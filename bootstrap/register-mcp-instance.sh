#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  register-mcp-instance.sh <repo-root>
        --server-type TYPE
        --tier-declared T0|T1|T2|T3
        --package-id ID --package-version VER [--package-integrity HASH]
        --binding key=value [--binding key=value ...]
        [--instance-suffix SUFFIX]
        [--profile strict|standard|lenient]
        [--json]

Register one MCP server instance in a downstream app repo. The write is
atomic (O_EXCL on the per-instance record) and appends a register event
to _system/mcp/runtime/mcp-server-provenance.jsonl.

See _system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md for the lifecycle and
record envelope, and _system/mcp-instance-policy.json for per-server-type
rules.

Refusal codes (machine-readable, also surfaced as exit message):
  namespace_missing, parent_template_refusal, server_type_unknown,
  required_field_missing, tier_above_ceiling, instance_id_in_use,
  policy_violation, missing_policy, missing_matrix, bad_binding.
EOF
}

TARGET=""
SERVER_TYPE=""
TIER_DECLARED=""
PKG_ID=""
PKG_VER=""
PKG_INTEGRITY=""
PROFILE=""
INSTANCE_SUFFIX=""
JSON_MODE=0
BINDINGS=()

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --server-type)       SERVER_TYPE="${2:-}"; shift 2 ;;
    --tier-declared)     TIER_DECLARED="${2:-}"; shift 2 ;;
    --package-id)        PKG_ID="${2:-}"; shift 2 ;;
    --package-version)   PKG_VER="${2:-}"; shift 2 ;;
    --package-integrity) PKG_INTEGRITY="${2:-}"; shift 2 ;;
    --binding)           BINDINGS+=("${2:-}"); shift 2 ;;
    --instance-suffix)   INSTANCE_SUFFIX="${2:-}"; shift 2 ;;
    --profile)           PROFILE="${2:-}"; shift 2 ;;
    --json)              JSON_MODE=1; shift ;;
    -h|--help)           usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_error() {
  local code="$1" msg="$2"
  if [[ "${JSON_MODE}" -eq 1 ]]; then
    aiaast_json_error "${code}" "${msg}" "register-mcp-instance.sh" "mutating"
  else
    printf 'register-mcp-instance.sh: %s: %s\n' "${code}" "${msg}" >&2
  fi
  exit 1
}

[[ ! -d "${TARGET}" ]] && emit_error "missing_target" "target not found: ${TARGET}"
[[ -z "${SERVER_TYPE}" ]] && { usage >&2; exit 2; }
[[ -z "${TIER_DECLARED}" ]] && { usage >&2; exit 2; }
[[ -z "${PKG_ID}" || -z "${PKG_VER}" ]] && { usage >&2; exit 2; }

TARGET="$(cd -- "${TARGET}" && pwd)"
BINDINGS_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${BINDINGS[@]:-}")"

python3 - "${TARGET}" "${SERVER_TYPE}" "${TIER_DECLARED}" "${PKG_ID}" "${PKG_VER}" "${PKG_INTEGRITY}" "${PROFILE}" "${INSTANCE_SUFFIX}" "${BINDINGS_JSON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, os, re, secrets, sys
from datetime import datetime, timezone
from pathlib import Path

(target_s, server_type, tier_declared, pkg_id, pkg_ver, pkg_integrity,
 profile_arg, instance_suffix, bindings_json, json_mode_s) = sys.argv[1:11]
json_mode = json_mode_s == "1"
bindings_raw = [b for b in json.loads(bindings_json) if b]

def fail(code: str, msg: str) -> None:
    if json_mode:
        print(json.dumps({"ok": False, "script": "register-mcp-instance.sh",
                          "error": {"code": code, "message": msg}}))
    else:
        sys.stderr.write(f"register-mcp-instance.sh: {code}: {msg}\n")
    sys.exit(1)

target = Path(target_s).resolve()
role_file   = target / "_system" / ".aiast-role.json"
ns_file     = target / "_system" / "app-local-namespace.json"
matrix_file = target / "_system" / "mcp-server-capability-matrix.json"
policy_file = target / "_system" / "mcp-instance-policy.json"

# 1. role gate
if role_file.is_file():
    try:
        role = json.loads(role_file.read_text()).get("role")
    except Exception as e:
        fail("role_unreadable", f"{e}")
    if role == "parent-template":
        fail("parent_template_refusal", "refusing to register MCP instance in parent-template repo")

# 2. namespace gate
if not ns_file.is_file():
    fail("namespace_missing", f"{ns_file} not found; run init-app-namespace.sh first")
try:
    ns = json.loads(ns_file.read_text())
except Exception as e:
    fail("namespace_unreadable", f"{e}")
app_id = ns.get("app_id", "")
if not app_id:
    fail("namespace_missing", "app_id not present in app-local-namespace.json")

# 3. matrix + policy
if not matrix_file.is_file():
    fail("missing_matrix", f"{matrix_file} not found")
if not policy_file.is_file():
    fail("missing_policy", f"{policy_file} not found")
matrix = json.loads(matrix_file.read_text())
policy = json.loads(policy_file.read_text())

profile = profile_arg or policy.get("validation_profile_default", "strict")
if profile not in ("strict", "standard", "lenient"):
    fail("bad_profile", f"unknown profile {profile!r}")

# 4. server_type acceptance
type_entry = next((t for t in matrix.get("server_types", []) if t.get("type") == server_type), None)
if type_entry is None:
    fail("server_type_unknown", f"server_type {server_type!r} not in capability matrix")

if server_type == "unknown":
    action = (matrix.get("unknown_handling", {}) or {}).get(profile, "refuse")
    if action == "refuse":
        fail("server_type_unknown", f"server_type 'unknown' is refused under profile={profile}")
    # warn/allow continue; refusal already short-circuited

# 5. tier_declared validation
TIER_ORDER = {"T0": 0, "T1": 1, "T2": 2, "T3": 3}
if tier_declared not in TIER_ORDER:
    fail("policy_violation", f"tier_declared {tier_declared!r} not in T0..T3")
tier_ceiling = type_entry["tier_ceiling"]
if TIER_ORDER[tier_declared] > TIER_ORDER[tier_ceiling]:
    fail("tier_above_ceiling",
         f"declared {tier_declared} exceeds ceiling {tier_ceiling} for type {server_type}")

# 6. bindings parse + required_fields check
bindings: dict[str, str] = {}
for raw in bindings_raw:
    if "=" not in raw:
        fail("bad_binding", f"binding {raw!r} must be key=value")
    k, _, v = raw.partition("=")
    k = k.strip(); v = v.strip()
    if not k:
        fail("bad_binding", f"binding has empty key: {raw!r}")
    bindings[k] = v

required = type_entry.get("required_fields", []) or []
missing = [f for f in required if not bindings.get(f)]
if missing:
    fail("required_field_missing",
         f"server_type {server_type} requires {required}; missing or empty: {missing}")

# 7. per-server-type policy checks (best effort; full validators are
#    check-mcp-project-isolation.sh and check-mcp-bleed.sh)
st_policy = (policy.get("server_types", {}) or {}).get(server_type, {})
repo_real = Path(ns.get("repo_root_realpath") or target_s).resolve()

if server_type == "filesystem":
    roots_csv = bindings.get("allowed_roots", "")
    roots = [r for r in roots_csv.split(",") if r]
    if not roots:
        fail("policy_violation", "filesystem instance requires non-empty allowed_roots (comma-separated)")
    if st_policy.get("allowed_roots_must_be_inside_repo_root_realpath", True):
        for r in roots:
            rp = (target / r).resolve() if not r.startswith("/") else Path(r).resolve()
            try:
                rp.relative_to(repo_real)
            except ValueError:
                fail("policy_violation", f"allowed_root {r!r} resolves outside repo_root_realpath ({repo_real})")

if server_type == "browser":
    bp = bindings.get("browser_profile_path", "")
    if not bp:
        fail("policy_violation", "browser instance requires browser_profile_path")
    bp_real = (target / bp).resolve() if not bp.startswith("/") else Path(bp).resolve()
    try:
        bp_real.relative_to(repo_real / ".local" / "browser-profiles" / app_id)
    except ValueError:
        fail("policy_violation",
             f"browser_profile_path {bp!r} must resolve under {repo_real}/.local/browser-profiles/{app_id}/")

if server_type == "memory_artifact":
    ns_val = bindings.get("memory_namespace", "")
    if st_policy.get("memory_namespace_must_start_with_app_id", True):
        if not ns_val.startswith(f"{app_id}:"):
            fail("policy_violation",
                 f"memory_namespace {ns_val!r} must start with '{app_id}:'")

if server_type == "redis":
    try:
        idx = int(bindings.get("db_index", ""))
    except Exception:
        fail("policy_violation", "redis db_index must be an integer")
    lo = int(st_policy.get("db_index_min", 0)); hi = int(st_policy.get("db_index_max", 15))
    if not (lo <= idx <= hi):
        fail("policy_violation", f"redis db_index {idx} outside [{lo},{hi}]")
    cns = bindings.get("cache_namespace", "")
    pat = st_policy.get("cache_namespace_pattern", "^[a-z0-9_-]{1,64}:$")
    if not re.fullmatch(pat, cns):
        fail("policy_violation", f"redis cache_namespace {cns!r} does not match {pat}")

if server_type == "postgres":
    sp = bindings.get("db_schema_or_prefix", "")
    pat = st_policy.get("schema_or_prefix_pattern", "^[a-z][a-z0-9_]{1,62}$")
    if not re.fullmatch(pat, sp):
        fail("policy_violation", f"postgres db_schema_or_prefix {sp!r} does not match {pat}")

if server_type == "http_remote":
    base = bindings.get("base_url", "")
    if st_policy.get("base_url_must_be_https", True) and not base.lower().startswith("https://"):
        fail("policy_violation", f"http_remote base_url must be https://: got {base!r}")
    apr = bindings.get("allowed_paths_regex", "")
    if st_policy.get("allowed_paths_regex_must_be_anchored", True):
        if not (apr.startswith("^") and apr.endswith("$")):
            fail("policy_violation",
                 f"http_remote allowed_paths_regex must be anchored with ^…$: got {apr!r}")

if server_type == "github":
    repos_csv = bindings.get("allowed_repos", "")
    repos = [r for r in repos_csv.split(",") if r]
    min_n = int(st_policy.get("allowed_repos_min", 1))
    if len(repos) < min_n:
        fail("policy_violation", f"github allowed_repos requires at least {min_n}; got {len(repos)}")
    if not bindings.get("credentials_scope"):
        fail("required_field_missing", "github credentials_scope must be non-empty")

# 8. mint mcp_instance_id; enforce instance_id_pattern
suffix = instance_suffix or secrets.token_hex(8)
if not re.fullmatch(r"[0-9a-f]{8,32}", suffix):
    fail("bad_binding", f"--instance-suffix must be 8-32 lowercase hex chars; got {suffix!r}")

mcp_instance_id = f"{app_id}:mcp:{server_type}:{suffix}"
id_pattern = policy.get("instance_id_pattern", "")
if id_pattern and not re.fullmatch(id_pattern, mcp_instance_id):
    fail("policy_violation",
         f"mcp_instance_id {mcp_instance_id!r} does not match instance_id_pattern {id_pattern!r}")

# 9. paths + atomic O_EXCL write
reg = (policy.get("registry") or {})
instances_dir = target / reg.get("instances_dir", "_system/mcp/instances")
runtime_dir   = target / reg.get("runtime_dir",   "_system/mcp/runtime")
prov_log      = target / reg.get("provenance_log","_system/mcp/runtime/mcp-server-provenance.jsonl")
instances_dir.mkdir(parents=True, exist_ok=True)
runtime_dir.mkdir(parents=True, exist_ok=True)

# Filenames cannot contain ':' on some filesystems — sanitise.
safe_name = mcp_instance_id.replace(":", "__")
record_path = instances_dir / f"{safe_name}.json"

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

record = {
    "schema_version": "1.0.0",
    "mcp_instance_id": mcp_instance_id,
    "app_id": app_id,
    "host_fingerprint_id": ns.get("host_fingerprint_id", "fp_000000000000"),
    "server_type": server_type,
    "server_package": {
        "id": pkg_id,
        "version": pkg_ver,
        "integrity": pkg_integrity or None,
    },
    "tier_declared": tier_declared,
    "tier_ceiling": tier_ceiling,
    "namespace_bindings": bindings,
    "lifecycle": {
        "registered_at": now,
        "refreshed_at": now,
        "retired_at": None,
        "status": "active",
        "events": [
            {"ts": now, "kind": "registered", "by": "register-mcp-instance.sh"}
        ],
    },
}

try:
    fd = os.open(str(record_path), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
except FileExistsError:
    fail("instance_id_in_use", f"record already exists: {record_path.relative_to(target)}")

with os.fdopen(fd, "w") as fh:
    json.dump(record, fh, indent=2)
    fh.write("\n")

# 10. append to provenance log
prov_log.parent.mkdir(parents=True, exist_ok=True)
with open(prov_log, "a") as fh:
    fh.write(json.dumps({
        "ts": now,
        "mcp_instance_id": mcp_instance_id,
        "kind": "register",
        "package": record["server_package"],
        "server_type": server_type,
        "tier_declared": tier_declared,
    }) + "\n")

if json_mode:
    print(json.dumps({
        "ok": True,
        "script": "register-mcp-instance.sh",
        "mcp_instance_id": mcp_instance_id,
        "record": str(record_path.relative_to(target)),
        "tier_declared": tier_declared,
        "tier_ceiling": tier_ceiling,
        "profile": profile,
    }))
else:
    print(f"register-mcp-instance.sh: registered {mcp_instance_id} "
          f"({server_type}, {tier_declared}<={tier_ceiling}) → {record_path.relative_to(target)}")
PY
