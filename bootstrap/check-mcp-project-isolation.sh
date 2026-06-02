#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-mcp-project-isolation.sh <template-or-repo-root> [--json]
                                       [--profile strict|standard|lenient]

Validate that tracked MCP examples and config do not grant cross-app,
home-directory, parent-template, root, or secret-bearing access.

When run against a downstream app (role=downstream-app), also validates
the MCP instance registry under _system/mcp/instances/ against the 7
invariants in _system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md and the
per-server-type rules in _system/mcp-instance-policy.json.

In strict profile (default), an MCP instance with server_type "unknown"
is refused (F-12). standard warns; lenient is silent.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"
shift || true
JSON_MODE=0
PROFILE=""
EMIT_BLEED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --emit-bleed-events)
      EMIT_BLEED=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "check-mcp-project-isolation.sh" "validation"
      [[ "${JSON_MODE}" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "${TARGET}" ]]; then
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "missing_target" "target does not exist" "check-mcp-project-isolation.sh" "validation"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "target does not exist: ${TARGET}" >&2
  exit 1
fi

TARGET="$(cd -- "${TARGET}" && pwd)"

export AIAST_EMIT_BLEED="${EMIT_BLEED}"
if ! python3 - <<'PY' "${TARGET}" "${PROFILE}"
from __future__ import annotations

import json
import os
import re
import secrets
import sys
import tomllib
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

root = Path(sys.argv[1]).resolve()
profile_arg = sys.argv[2] if len(sys.argv) > 2 else ""

# --- bleed-event emitter (opt-in via AIAST_EMIT_BLEED=1) ---
def _bleed(severity: str, ev_type: str, scope_path: str, *,
           observed: str | None = None, agent_id: str | None = None,
           evidence_refs: list[str] | None = None,
           context: dict | None = None,
           remediation_action: str = "notify") -> None:
    if os.environ.get("AIAST_EMIT_BLEED") != "1":
        return
    try:
        ns_file = root / "_system" / "app-local-namespace.json"
        app_id = host_fp = allowed_root = None
        if ns_file.is_file():
            ns = json.loads(ns_file.read_text())
            app_id = ns.get("app_id"); host_fp = ns.get("host_fingerprint_id")
            allowed_root = ns.get("repo_root_realpath")
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        ev = {
            "event_id": f"evt_{secrets.token_hex(13)}",
            "ts": now, "severity": severity, "type": ev_type,
            "detected_by": "check-mcp-project-isolation.sh",
            "agent_id": agent_id, "app_id": app_id, "host_fingerprint_id": host_fp,
            "scope": {"path": scope_path, "operation": "detect"},
            "intended_boundary": {"allowed_repo_root": allowed_root},
            "observed_target": observed,
            "evidence_refs": evidence_refs or [],
            "remediation": {"action": remediation_action, "by": "check-mcp-project-isolation.sh", "ts": now},
        }
        if context:
            ev["context"] = context
        audit = root / "_system" / "agent-state" / "audit"
        audit.mkdir(parents=True, exist_ok=True)
        with open(audit / f"{now[:7]}.jsonl", "a") as fh:
            fh.write(json.dumps(ev, separators=(",", ":")) + "\n")
    except Exception:
        pass  # never let telemetry block the validator
errors: list[str] = []
warnings: list[str] = []

json_files = [
    ".cursor/mcp.json",
    "_system/mcp/servers.cursor.example.json",
]
toml_files = [
    "_system/mcp/servers.codex.example.toml",
]
text_files = [
    "_system/MCP_CONFIG.md",
    "_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md",
    "_system/mcp/MCP_SELECTION_POLICY.md",
    "_system/mcp/MCP_SERVER_CATALOG.md",
    ".cursor/skills/mcp-config/SKILL.md",
]

allowed_root_values = {
    ".",
    "./",
    "__AIAST_PROJECT_ROOT__",
    "${AIAST_PROJECT_ROOT}",
    "${AIAST_PROJECT_ROOT:-.}",
    "${workspaceFolder}",
}

secret_patterns = [
    (re.compile(r"ghp_[A-Za-z0-9_]{20,}"), "GitHub classic token"),
    (re.compile(r"github_pat_[A-Za-z0-9_]{20,}"), "GitHub fine-grained token"),
    (re.compile(r"sk-[A-Za-z0-9_-]{20,}"), "API key"),
    (re.compile(r"AIza[0-9A-Za-z_-]{20,}"), "Google API key"),
    (re.compile(r"xox[baprs]-[A-Za-z0-9-]{20,}"), "Slack token"),
    (re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----"), "private key"),
    (re.compile(r"postgres(?:ql)?://[^:\s/@]+:[^@\s]+@"), "database URL with password"),
    (re.compile(r"redis://[^:\s/@]+:[^@\s]+@"), "Redis URL with password"),
]

absolute_path_patterns = [
    (re.compile(r"^/$"), "root filesystem"),
    (re.compile(r"^~(?:/|$)"), "home directory"),
    (re.compile(r"^\$HOME(?:/|$)"), "home directory"),
    (re.compile(r"^\$\{HOME\}(?:/|$)"), "home directory"),
    (re.compile(r"^/home/[^/]+(?:/|$)"), "Linux home absolute path"),
    (re.compile(r"^/Users/[^/]+(?:/|$)"), "macOS home absolute path"),
    (re.compile(r"^[A-Za-z]:\\\\"), "Windows absolute path"),
]

cross_app_markers = [
    ".MyAppZ",
    "_AI_AGENT_SYSTEM_TEMPLATE",
    "/../",
    "../",
]

def add_error(rel: str, message: str) -> None:
    errors.append(f"{rel}: {message}")

def iter_strings(value: Any, path: str = "$"):
    if isinstance(value, str):
        yield path, value
    elif isinstance(value, dict):
        for key, item in value.items():
            yield f"{path}.__key__", str(key)
            yield from iter_strings(item, f"{path}.{key}")
    elif isinstance(value, list):
        for idx, item in enumerate(value):
            yield from iter_strings(item, f"{path}[{idx}]")

def parse_json(rel: str) -> Any | None:
    path = root / rel
    if not path.is_file():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        add_error(rel, f"invalid JSON: {exc}")
        return None

def parse_toml(rel: str) -> Any | None:
    path = root / rel
    if not path.is_file():
        return None
    try:
        return tomllib.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        add_error(rel, f"invalid TOML: {exc}")
        return None

def check_secret_strings(rel: str, values: list[str]) -> None:
    for value in values:
        for pattern, label in secret_patterns:
            if pattern.search(value):
                add_error(rel, f"tracked MCP surface appears to contain a real {label}")

def check_forbidden_path_string(rel: str, value: str) -> None:
    stripped = value.strip()
    if not stripped or stripped in allowed_root_values:
        return
    if stripped == "/ABSOLUTE/PATH/TO/PROJECT" or "/absolute/path/to/project" in stripped:
        add_error(rel, "uses absolute project path placeholder; use __AIAST_PROJECT_ROOT__ or . in tracked examples")
        return
    for marker in cross_app_markers:
        if marker in stripped:
            add_error(rel, f"tracked MCP config references cross-app or parent-template marker {marker!r}: {stripped}")
            return
    for pattern, label in absolute_path_patterns:
        if pattern.search(stripped):
            add_error(rel, f"tracked MCP config uses {label}: {stripped}")
            return

def looks_like_filesystem_server(name: str, server: Any) -> bool:
    if "filesystem" in name.lower():
        return True
    if isinstance(server, dict):
        joined = " ".join(str(item) for _, item in iter_strings(server))
        return "server-filesystem" in joined or "mcp-filesystem" in joined
    return False

def server_entries(config: Any) -> list[tuple[str, dict[str, Any]]]:
    if not isinstance(config, dict):
        return []
    entries: list[tuple[str, dict[str, Any]]] = []
    for key in ("mcpServers", "mcp_servers", "servers"):
        value = config.get(key)
        if isinstance(value, dict):
            for name, server in value.items():
                if isinstance(server, dict):
                    entries.append((str(name), server))
    return entries

def check_filesystem_args(rel: str, name: str, server: dict[str, Any]) -> None:
    args = server.get("args", [])
    if not isinstance(args, list):
        add_error(rel, f"{name} filesystem server args must be a list")
        return

    string_args = [str(arg).strip() for arg in args if isinstance(arg, str)]
    if not string_args:
        add_error(rel, f"{name} filesystem server must declare project root args")
        return

    scope_args = [
        arg for arg in string_args
        if arg not in {"-y", "--yes"}
        and not arg.startswith("-")
        and not arg.startswith("@")
        and "server-filesystem" not in arg
        and "mcp-filesystem" not in arg
        and arg not in {"npx", "node"}
    ]

    if not scope_args:
        add_error(rel, f"{name} filesystem server must include an explicit project root scope")
        return

    for arg in scope_args:
        if arg in allowed_root_values:
            continue
        before = len(errors)
        check_forbidden_path_string(rel, arg)
        if len(errors) == before:
            add_error(rel, f"{name} filesystem scope must be project-local placeholder or '.': {arg}")

def check_structured(rel: str, config: Any) -> None:
    if config is None:
        return
    strings = [value for _, value in iter_strings(config)]
    check_secret_strings(rel, strings)
    for value in strings:
        check_forbidden_path_string(rel, value)
    for name, server in server_entries(config):
        if looks_like_filesystem_server(name, server):
            check_filesystem_args(rel, name, server)

for rel in json_files:
    check_structured(rel, parse_json(rel))

for rel in toml_files:
    check_structured(rel, parse_toml(rel))

for rel in text_files:
    path = root / rel
    if not path.is_file():
        continue
    text = path.read_text(encoding="utf-8")
    check_secret_strings(rel, [text])
    if "/ABSOLUTE/PATH/TO/PROJECT" in text or "/absolute/path/to/project" in text:
        add_error(rel, "contains obsolete absolute project path placeholder")

required_docs = [
    "_system/MCP_CONFIG.md",
    "_system/mcp/MCP_PROJECT_ISOLATION_POLICY.md",
    "_system/mcp/MCP_SELECTION_POLICY.md",
    "_system/mcp/MCP_SERVER_CAPABILITY_TIER_MATRIX.md",
    "_system/mcp/MCP_INSTANCE_REGISTRY_PROTOCOL.md",
    "_system/mcp/MCP_SERVER_CATALOG.md",
    "_system/mcp/servers.cursor.example.json",
    "_system/mcp/servers.codex.example.toml",
    "_system/mcp-instance-policy.json",
    "_system/mcp-server-capability-matrix.json",
    "_system/schemas/mcp-instance-policy.schema.json",
    "_system/schemas/mcp-server-capability-matrix.schema.json",
]
for rel in required_docs:
    if not (root / rel).is_file():
        add_error(rel, "required MCP isolation surface is missing")

# ---- Registry pass (MCP_INSTANCE_REGISTRY_PROTOCOL.md §"Invariants") ----
#
# Runs only when role is "downstream-app". Parent-template repos have an
# empty instances/ directory by design; if anything is there, that's a
# bug worth surfacing.

role_file = root / "_system" / ".aiast-role.json"
role = "unknown"
if role_file.is_file():
    try:
        role = json.loads(role_file.read_text(encoding="utf-8")).get("role", "unknown")
    except Exception as exc:
        add_error("_system/.aiast-role.json", f"unreadable: {exc}")

policy_file = root / "_system" / "mcp-instance-policy.json"
matrix_file = root / "_system" / "mcp-server-capability-matrix.json"
ns_file     = root / "_system" / "app-local-namespace.json"

policy: dict[str, Any] = {}
matrix: dict[str, Any] = {}
if policy_file.is_file():
    try: policy = json.loads(policy_file.read_text(encoding="utf-8"))
    except Exception as exc: add_error(str(policy_file.relative_to(root)), f"invalid JSON: {exc}")
if matrix_file.is_file():
    try: matrix = json.loads(matrix_file.read_text(encoding="utf-8"))
    except Exception as exc: add_error(str(matrix_file.relative_to(root)), f"invalid JSON: {exc}")

profile = profile_arg or policy.get("validation_profile_default", "strict")
if profile not in ("strict", "standard", "lenient"):
    add_error("--profile", f"unknown profile {profile!r}")
    profile = "strict"

registry = policy.get("registry") or {}
instances_dir  = root / registry.get("instances_dir",  "_system/mcp/instances")
quarantine_dir = root / registry.get("quarantine_dir", "_system/mcp/instances/quarantine")

matrix_types: dict[str, dict[str, Any]] = {
    t.get("type"): t for t in (matrix.get("server_types") or []) if t.get("type")
}
TIER_ORDER = {"T0": 0, "T1": 1, "T2": 2, "T3": 3}

def iter_instance_records():
    if not instances_dir.is_dir(): return
    for p in sorted(instances_dir.iterdir()):
        if p.is_dir(): continue
        if not p.name.endswith(".json"): continue
        if p.name == ".gitkeep": continue
        yield p

if role == "parent-template":
    rogue = list(iter_instance_records())
    if rogue:
        add_error(
            str(instances_dir.relative_to(root)),
            f"parent-template repo MUST have empty instances/ (found {len(rogue)} record(s))",
        )
elif role == "downstream-app":
    ns_app_id = None
    if ns_file.is_file():
        try:
            ns_app_id = json.loads(ns_file.read_text(encoding="utf-8")).get("app_id")
        except Exception as exc:
            add_error(str(ns_file.relative_to(root)), f"unreadable: {exc}")

    id_pattern_re = None
    pat = policy.get("instance_id_pattern", "")
    if pat:
        try: id_pattern_re = re.compile(pat)
        except re.error as exc: add_error("mcp-instance-policy.json", f"bad instance_id_pattern: {exc}")

    seen_ids: set[str] = set()

    for rec_path in iter_instance_records():
        rel = str(rec_path.relative_to(root))
        try:
            rec = json.loads(rec_path.read_text(encoding="utf-8"))
        except Exception as exc:
            add_error(rel, f"invalid JSON: {exc}"); continue

        mid = rec.get("mcp_instance_id", "")
        # Invariant 1: prefix matches <app_id>:mcp:
        if ns_app_id and not mid.startswith(f"{ns_app_id}:mcp:"):
            add_error(rel, f"invariant_1: mcp_instance_id {mid!r} must start with '{ns_app_id}:mcp:'")
        # Invariant 2: app_id matches
        if ns_app_id and rec.get("app_id") != ns_app_id:
            add_error(rel, f"invariant_2: record app_id {rec.get('app_id')!r} != namespace app_id {ns_app_id!r}")
        # id pattern
        if id_pattern_re and not id_pattern_re.fullmatch(mid):
            add_error(rel, f"mcp_instance_id {mid!r} does not match instance_id_pattern")
        # uniqueness
        if mid in seen_ids:
            add_error(rel, f"duplicate mcp_instance_id within instances/: {mid}")
        seen_ids.add(mid)

        # Invariant 3: server_type in matrix; unknown_handling by profile
        st = rec.get("server_type", "")
        t_entry = matrix_types.get(st)
        if t_entry is None:
            add_error(rel, f"invariant_3: server_type {st!r} not in capability matrix")
            continue
        if st == "unknown":
            action = (matrix.get("unknown_handling") or {}).get(profile, "refuse")
            if action == "refuse":
                add_error(rel, f"invariant_3 (F-12): server_type 'unknown' refused under profile={profile}")
                _bleed("medium", "scope-escape", rel,
                       observed="server_type=unknown",
                       context={"profile": profile, "fault": "F-12", "mcp_instance_id": mid},
                       remediation_action="refused")
            elif action == "warn":
                warnings.append(f"{rel}: server_type 'unknown' under profile={profile}")
                _bleed("low", "scope-escape", rel,
                       observed="server_type=unknown",
                       context={"profile": profile, "fault": "F-12", "mcp_instance_id": mid},
                       remediation_action="allow")

        # Invariant 4: tier_declared <= tier_ceiling
        td = rec.get("tier_declared", ""); tc = t_entry.get("tier_ceiling", "T0")
        if td not in TIER_ORDER:
            add_error(rel, f"tier_declared {td!r} not in T0..T3")
        elif TIER_ORDER[td] > TIER_ORDER.get(tc, 0):
            add_error(rel, f"invariant_4: tier_declared {td} exceeds ceiling {tc} for type {st}")

        # Invariant 5: required_fields present in namespace_bindings
        bindings = rec.get("namespace_bindings") or {}
        required = t_entry.get("required_fields") or []
        missing = [f for f in required if not bindings.get(f)]
        if missing:
            add_error(rel, f"invariant_5: missing required namespace_bindings for {st}: {missing}")

        # Invariants 6 + 7: lifecycle status / retired_at consistency
        lc = rec.get("lifecycle") or {}
        status = lc.get("status", "")
        retired_at = lc.get("retired_at")
        if status == "active" and retired_at is not None:
            add_error(rel, "invariant_6: status=active but retired_at is non-null")
        if status == "retired":
            if not retired_at:
                add_error(rel, "invariant_7: status=retired but retired_at is null")
            events = lc.get("events") or []
            if not any(e.get("kind") == "retired" for e in events):
                add_error(rel, "invariant_7: status=retired but no 'retired' lifecycle event")

elif role != "unknown":
    warnings.append(f"unrecognised role={role!r}; skipping registry pass")

if warnings:
    for warning in warnings:
        print(warning, file=sys.stderr)

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    raise SystemExit(1)
PY
then
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "mcp_isolation_invalid" "MCP project isolation check failed" "check-mcp-project-isolation.sh" "validation"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "mcp project isolation: FAIL" >&2
  exit 1
fi

if [[ "${JSON_MODE}" -eq 1 ]]; then
  aiaast_json_ok '{"scope":"project"}' "check-mcp-project-isolation.sh" "validation"
else
  echo "mcp project isolation: PASS"
fi
