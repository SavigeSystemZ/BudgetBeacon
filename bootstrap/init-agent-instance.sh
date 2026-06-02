#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  init-agent-instance.sh <repo-root> --agent-id ID --role ROLE [--lane LANE]
                         [--branch BRANCH] [--scope GLOB ...]
                         [--ttl SECONDS] [--notes TEXT] [--json]

Claim an agent instance lease in a downstream app repo. The claim is atomic:
fencing counter is bumped under flock, the lease file is created with O_EXCL,
and every requested scope lock is created with O_EXCL. Any failure rolls back
the partial state.

Required:
  <repo-root>          Path to the downstream app repo root.
  --agent-id ID        Must match agent-instance-policy.json#/naming/regex.
  --role ROLE          Free-form role tag (orchestrator, implementation-worker, ...).

Optional:
  --lane LANE          Logical work-stream id (default: derived from agent-id).
  --branch BRANCH      Git branch name (default: current branch).
  --scope GLOB         May be passed multiple times; each becomes a scope lock.
  --ttl SECONDS        Override policy default ttl_seconds.
  --notes TEXT         Free-form note attached to lease + locks.
  --json               Emit machine-readable envelope on stdout.

Refuses on:
  * wrong role (parent-template).
  * missing app-local-namespace.json.
  * agent-id mismatching naming regex.
  * concurrency cap exceeded for this agent_type.
  * existing active lease with the same agent_id.
  * existing active lock for any requested scope.
EOF
}

REPO_ROOT_ARG=""
AGENT_ID=""
ROLE=""
LANE=""
BRANCH=""
TTL_OVERRIDE=""
NOTES=""
JSON_MODE=0
SCOPES=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --agent-id) AGENT_ID="${2:-}"; shift 2 ;;
    --role)     ROLE="${2:-}"; shift 2 ;;
    --lane)     LANE="${2:-}"; shift 2 ;;
    --branch)   BRANCH="${2:-}"; shift 2 ;;
    --ttl)      TTL_OVERRIDE="${2:-}"; shift 2 ;;
    --notes)    NOTES="${2:-}"; shift 2 ;;
    --scope)    SCOPES+=("${2:-}"); shift 2 ;;
    --json)     JSON_MODE=1; shift ;;
    --) shift; break ;;
    -*) echo "unknown flag: $1" >&2; usage; exit 2 ;;
    *)
      [[ -z "${REPO_ROOT_ARG}" ]] && REPO_ROOT_ARG="$1" || { echo "unexpected positional: $1" >&2; exit 2; }
      shift
      ;;
  esac
done

emit_error() {
  local code="$1"; local msg="$2"
  if [[ "${JSON_MODE}" -eq 1 ]]; then
    python3 -c "import json,sys; print(json.dumps({'ok':False,'script':'init-agent-instance.sh','code':sys.argv[1],'message':sys.argv[2]}))" "${code}" "${msg}"
  else
    printf 'init-agent-instance.sh: %s: %s\n' "${code}" "${msg}" >&2
  fi
  exit 1
}

[[ -z "${REPO_ROOT_ARG}" || -z "${AGENT_ID}" || -z "${ROLE}" ]] && { usage >&2; exit 2; }
[[ ! -d "${REPO_ROOT_ARG}" ]] && emit_error "missing_repo_root" "repo root not found: ${REPO_ROOT_ARG}"
REPO_ROOT="$(cd -- "${REPO_ROOT_ARG}" && pwd)"

if [[ -z "${BRANCH}" ]]; then
  BRANCH="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
fi
[[ -z "${LANE}" ]] && LANE="auto-${AGENT_ID}"

# Hand off to Python for atomic claim.
SCOPES_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${SCOPES[@]:-}")"

python3 - "${REPO_ROOT}" "${AGENT_ID}" "${ROLE}" "${LANE}" "${BRANCH}" "${TTL_OVERRIDE}" "${NOTES}" "${SCOPES_JSON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import fcntl, hashlib, json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path

repo, agent_id, role, lane, branch, ttl_override, notes, scopes_json, json_mode_s = sys.argv[1:10]
json_mode = json_mode_s == "1"
scopes = [s for s in json.loads(scopes_json) if s]

def fail(code: str, msg: str) -> None:
    if json_mode:
        print(json.dumps({"ok": False, "script": "init-agent-instance.sh", "code": code, "message": msg}))
    else:
        sys.stderr.write(f"init-agent-instance.sh: {code}: {msg}\n")
    sys.exit(1)

repo_p = Path(repo).resolve()
role_file = repo_p / "_system" / ".aiast-role.json"
ns_file   = repo_p / "_system" / "app-local-namespace.json"
pol_file  = repo_p / "_system" / "agent-instance-policy.json"
state     = repo_p / "_system" / "agent-state"

# Role gate.
if role_file.is_file():
    try:
        if json.loads(role_file.read_text()).get("role") == "parent-template":
            fail("wrong_role", "refusing to claim instance in a parent-template repo")
    except Exception as e:
        fail("role_unreadable", f"{e}")

# Load namespace (provides app_id + forbidden_roots).
if not ns_file.is_file():
    fail("missing_namespace", f"{ns_file} not found; run init-app-namespace.sh first")
try:
    ns = json.loads(ns_file.read_text())
except Exception as e:
    fail("namespace_unreadable", f"{e}")
app_id = ns.get("app_id", "")
forbidden_roots = ns.get("forbidden_roots", []) or []

# Load policy.
if not pol_file.is_file():
    fail("missing_policy", f"{pol_file} not found")
policy = json.loads(pol_file.read_text())

regex = policy.get("naming", {}).get("regex", "")
if not re.fullmatch(regex, agent_id):
    fail("invalid_agent_id", f"agent_id {agent_id!r} does not match policy regex {regex!r}")

agent_type = agent_id.rsplit("-", 1)[0]
allowed = set(policy.get("naming", {}).get("allowed_agent_types", []) or [])
if agent_type not in allowed:
    fail("unknown_agent_type", f"agent_type {agent_type!r} not in {sorted(allowed)}")

ttl = int(ttl_override or policy.get("leases", {}).get("ttl_seconds", 300))
hb_int = int(policy.get("leases", {}).get("heartbeat_interval_seconds", 30))

caps = policy.get("concurrency_caps", {})
cap_for_type = int(caps.get(agent_type, 1))

layout = policy.get("state_layout", {})
locks_dir      = repo_p / layout.get("locks_dir", "_system/agent-state/locks")
leases_dir     = repo_p / layout.get("leases_dir", "_system/agent-state/leases")
heartbeats_dir = repo_p / layout.get("heartbeats_dir", "_system/agent-state/heartbeats")
counter_path   = repo_p / policy.get("fencing", {}).get("counter_path", "_system/agent-state/.fencing-counter")
fencing_enabled = bool(policy.get("fencing", {}).get("enabled", True))

for d in (locks_dir, leases_dir, heartbeats_dir):
    d.mkdir(parents=True, exist_ok=True)
counter_path.parent.mkdir(parents=True, exist_ok=True)

now = datetime.now(timezone.utc).replace(microsecond=0)
now_iso = now.isoformat().replace("+00:00", "Z")
now_epoch = int(now.timestamp())

lease_file = leases_dir / f"{agent_id}.lease.json"

def scope_hash(scope: str) -> str:
    return hashlib.sha256(scope.encode("utf-8")).hexdigest()[:24]

scope_locks = [(s, locks_dir / f"{scope_hash(s)}.lock.json") for s in scopes]

# Pre-flight: lease already present? cap already hit? lock collision?
def count_active_for_type(t: str) -> int:
    n = 0
    if not leases_dir.is_dir(): return 0
    for p in leases_dir.iterdir():
        if not p.name.endswith(".lease.json"): continue
        try:
            d = json.loads(p.read_text())
            if d.get("agent_type") == t and d.get("status") in ("active", "expiring"):
                n += 1
        except Exception:
            continue
    return n

if lease_file.exists():
    fail("agent_id_in_use", f"active lease already exists for {agent_id}")

# Acquire flock on counter file for the whole critical section.
# Open in r+ if exists, else create. The lock file is the counter itself
# (advisory lock; non-blocking with bounded wait).
counter_path.touch(exist_ok=True)
fp = open(counter_path, "r+")
deadline = time.time() + 5.0
got = False
while time.time() < deadline:
    try:
        fcntl.flock(fp.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        got = True
        break
    except BlockingIOError:
        time.sleep(0.05)
if not got:
    fp.close()
    fail("counter_busy", "could not acquire fencing counter lock in 5s")

try:
    # Re-check after lock acquisition.
    if lease_file.exists():
        fail("agent_id_in_use", f"active lease already exists for {agent_id}")

    if count_active_for_type(agent_type) >= cap_for_type:
        fail("cap_exceeded", f"concurrency cap reached for {agent_type}: {cap_for_type}")

    # Check no lock collisions BEFORE writing anything.
    for s, p in scope_locks:
        if p.exists():
            fail("scope_in_use", f"scope already locked by another instance: {s}")

    # Bump counter.
    raw = fp.read().strip()
    cur = int(raw) if raw else 0
    new_token = cur + 1
    fp.seek(0); fp.truncate()
    fp.write(str(new_token))
    fp.flush()
    os.fsync(fp.fileno())

    # Atomically create the lease via O_EXCL.
    lease_doc = {
        "schema_version": "1.0.0",
        "agent_id": agent_id,
        "agent_type": agent_type,
        "app_id": app_id,
        "host_fingerprint_id": "fp_000000000000",
        "process_id": os.getpid(),
        "process_start_epoch": now_epoch,
        "role": role,
        "lane": lane,
        "branch": branch,
        "scopes": [],
        "forbidden_roots": forbidden_roots,
        "fencing_token": new_token,
        "lease_started_at": now_iso,
        "lease_expires_at": datetime.fromtimestamp(now_epoch + ttl, tz=timezone.utc).isoformat().replace("+00:00", "Z"),
        "heartbeat_at": now_iso,
        "heartbeat_interval_seconds": hb_int,
        "ttl_seconds": ttl,
        "status": "active",
        "notes": notes,
    }

    fd = -1
    try:
        fd = os.open(str(lease_file), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
    except FileExistsError:
        fail("agent_id_in_use", f"active lease already exists for {agent_id}")

    created_locks: list[Path] = []
    try:
        # Write each scope lock with O_EXCL too; rollback on any collision.
        for s, p in scope_locks:
            lock_doc = {
                "scope": s,
                "scope_hash": p.stem,
                "owner_agent_id": agent_id,
                "owner_role": role,
                "app_id": app_id,
                "lease_started_at": now_iso,
                "lease_expires_at": lease_doc["lease_expires_at"],
                "fencing_token": new_token,
                "notes": notes,
            }
            try:
                lfd = os.open(str(p), os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o644)
            except FileExistsError:
                raise RuntimeError(f"scope_in_use:{s}")
            with os.fdopen(lfd, "w") as lh:
                json.dump(lock_doc, lh, indent=2)
            created_locks.append(p)
            lease_doc["scopes"].append({
                "scope": s,
                "lock_path": str(p.relative_to(repo_p)),
                "claimed_at": now_iso,
            })

        with os.fdopen(fd, "w") as fh:
            fd = -1
            json.dump(lease_doc, fh, indent=2)

        # Heartbeat.
        hb = heartbeats_dir / f"{agent_id}.json"
        hb.write_text(json.dumps({
            "agent_id": agent_id,
            "heartbeat_at": now_iso,
            "fencing_token": new_token,
        }, indent=2))

    except Exception as e:
        # Rollback partial state.
        try:
            if fd >= 0: os.close(fd)
        except Exception: pass
        try: lease_file.unlink(missing_ok=True)
        except Exception: pass
        for p in created_locks:
            try: p.unlink(missing_ok=True)
            except Exception: pass
        msg = str(e)
        if msg.startswith("scope_in_use:"):
            fail("scope_in_use", msg.split(":", 1)[1])
        fail("claim_failed", msg)

finally:
    try:
        fcntl.flock(fp.fileno(), fcntl.LOCK_UN)
    except Exception:
        pass
    fp.close()

if json_mode:
    print(json.dumps({
        "ok": True, "script": "init-agent-instance.sh",
        "agent_id": agent_id, "fencing_token": new_token,
        "lease": str(lease_file.relative_to(repo_p)),
        "locks": [str(p.relative_to(repo_p)) for _, p in scope_locks],
    }))
else:
    print(f"init-agent-instance.sh: claimed {agent_id} (token={new_token}) with {len(scope_locks)} scope(s)")
PY
