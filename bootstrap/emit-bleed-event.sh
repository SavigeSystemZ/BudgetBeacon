#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  emit-bleed-event.sh <repo-root>
      --severity critical|high|medium|low
      --type     scope-escape|namespace-collision|lease-violation|host-clash|credential-leak|memory-authority-inversion|schema-violation|provenance-drift|template-app-confusion|remediation|meta-sync-blocked|meta-sync-forced|integrity-signature-mismatch|unknown
      --detected-by SCRIPT_NAME
      --scope-path PATH --scope-op register|refresh|retire|quarantine|read|write|claim|release|detect
      [--agent-id ID] [--app-id ID] [--host-fingerprint-id ID]
      [--allowed-repo-root PATH] [--observed-target STR]
      [--fencing-token N]
      [--evidence-ref REF ...]
      [--remediation-action quarantine|notify|allow|refused|released]
      [--remediation-by STR]
      [--context-json JSON]
      [--json]

Appends one schema-conformant bleed event to
_system/agent-state/audit/<YYYY-MM>.jsonl using O_APPEND (never
rewrites existing lines). Reads policy / namespace / role-sentinel to
default app_id / host_fingerprint_id when not given.

The event is validated against _system/schemas/bleed-event.schema.json
before emission; refusal exits non-zero with a `schema_violation`
error code so a buggy validator can't poison the log.

Used by S5/S6 validators. Safe to call from any script that needs to
record a boundary event.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"; shift
SEVERITY=""; TYPE=""; DETECTED_BY=""
SCOPE_PATH=""; SCOPE_OP=""
AGENT_ID=""; APP_ID=""; HOST_FP=""
ALLOWED_ROOT=""; OBSERVED=""
FENCING_TOKEN=""
REMED_ACTION="notify"
REMED_BY=""
CONTEXT_JSON=""
JSON_MODE=0
EVIDENCE_REFS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --severity)            SEVERITY="${2:-}"; shift 2 ;;
    --type)                TYPE="${2:-}"; shift 2 ;;
    --detected-by)         DETECTED_BY="${2:-}"; shift 2 ;;
    --scope-path)          SCOPE_PATH="${2:-}"; shift 2 ;;
    --scope-op)            SCOPE_OP="${2:-}"; shift 2 ;;
    --agent-id)            AGENT_ID="${2:-}"; shift 2 ;;
    --app-id)              APP_ID="${2:-}"; shift 2 ;;
    --host-fingerprint-id) HOST_FP="${2:-}"; shift 2 ;;
    --allowed-repo-root)   ALLOWED_ROOT="${2:-}"; shift 2 ;;
    --observed-target)     OBSERVED="${2:-}"; shift 2 ;;
    --fencing-token)       FENCING_TOKEN="${2:-}"; shift 2 ;;
    --evidence-ref)        EVIDENCE_REFS+=("${2:-}"); shift 2 ;;
    --remediation-action)  REMED_ACTION="${2:-}"; shift 2 ;;
    --remediation-by)      REMED_BY="${2:-}"; shift 2 ;;
    --context-json)        CONTEXT_JSON="${2:-}"; shift 2 ;;
    --json)                JSON_MODE=1; shift ;;
    -h|--help)             usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"
[[ -z "${SEVERITY}" || -z "${TYPE}" || -z "${DETECTED_BY}" || -z "${SCOPE_PATH}" || -z "${SCOPE_OP}" ]] && { usage >&2; exit 2; }

EV_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${EVIDENCE_REFS[@]:-}")"

python3 - "${TARGET}" "${SEVERITY}" "${TYPE}" "${DETECTED_BY}" \
  "${SCOPE_PATH}" "${SCOPE_OP}" "${AGENT_ID}" "${APP_ID}" "${HOST_FP}" \
  "${ALLOWED_ROOT}" "${OBSERVED}" "${FENCING_TOKEN}" "${EV_JSON}" \
  "${REMED_ACTION}" "${REMED_BY}" "${CONTEXT_JSON}" "${JSON_MODE}" <<'PY'
from __future__ import annotations
import json, os, secrets, sys
from datetime import datetime, timezone
from pathlib import Path

(target_s, severity, ev_type, detected_by,
 scope_path, scope_op, agent_id, app_id, host_fp,
 allowed_root, observed, fencing_token_s, ev_refs_s,
 remed_action, remed_by, context_json, json_mode_s) = sys.argv[1:18]

json_mode = json_mode_s == "1"
evidence_refs = [e for e in json.loads(ev_refs_s) if e]

def fail(code, msg):
    if json_mode:
        print(json.dumps({"ok": False, "script": "emit-bleed-event.sh",
                          "error": {"code": code, "message": msg}}))
    else:
        sys.stderr.write(f"emit-bleed-event.sh: {code}: {msg}\n")
    sys.exit(1)

target = Path(target_s).resolve()

# Default fields from namespace/role if not given.
ns_file = target / "_system" / "app-local-namespace.json"
if ns_file.is_file():
    try:
        ns = json.loads(ns_file.read_text())
        app_id   = app_id   or ns.get("app_id") or ""
        host_fp  = host_fp  or ns.get("host_fingerprint_id") or ""
        allowed_root = allowed_root or ns.get("repo_root_realpath") or ""
    except Exception:
        pass

def or_none(s):
    return s if s != "" else None

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
# event_id: evt_ + 26 chars (hex token)
event_id = f"evt_{secrets.token_hex(13)}"

ev: dict = {
    "event_id": event_id,
    "ts": now,
    "severity": severity,
    "type": ev_type,
    "detected_by": detected_by,
    "agent_id": or_none(agent_id),
    "app_id":   or_none(app_id),
    "host_fingerprint_id": or_none(host_fp),
    "scope": {"path": scope_path, "operation": scope_op},
    "intended_boundary": {"allowed_repo_root": or_none(allowed_root)},
    "observed_target": or_none(observed),
    "evidence_refs": evidence_refs,
    "remediation": {"action": remed_action, "by": or_none(remed_by), "ts": now},
}
if fencing_token_s:
    try:
        ev["fencing_token"] = int(fencing_token_s)
    except ValueError:
        fail("schema_violation", f"fencing_token must be integer; got {fencing_token_s!r}")
if context_json:
    try:
        ev["context"] = json.loads(context_json)
    except Exception as e:
        fail("schema_violation", f"--context-json not valid JSON: {e}")
    if not isinstance(ev["context"], dict):
        fail("schema_violation", "--context-json must be a JSON object")

# Validate against schema if jsonschema is available.
schema_file = target / "_system" / "schemas" / "bleed-event.schema.json"
if schema_file.is_file():
    try:
        from jsonschema import Draft202012Validator  # type: ignore
    except ImportError:
        Draft202012Validator = None  # type: ignore
    if Draft202012Validator is not None:
        try:
            schema = json.loads(schema_file.read_text())
            v = Draft202012Validator(schema)
            errs = sorted(v.iter_errors(ev), key=lambda e: e.path)
            if errs:
                fail("schema_violation",
                     "; ".join(f"{list(e.path)}: {e.message}" for e in errs[:3]))
        except Exception as e:
            fail("schema_violation", f"schema check failed: {e}")

# Locate audit file by current UTC month.
audit_dir = target / "_system" / "agent-state" / "audit"
audit_dir.mkdir(parents=True, exist_ok=True)
month_file = audit_dir / f"{now[:7]}.jsonl"  # YYYY-MM
fd = os.open(str(month_file), os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o644)
with os.fdopen(fd, "a") as fh:
    fh.write(json.dumps(ev, separators=(",", ":")) + "\n")

if json_mode:
    print(json.dumps({"ok": True, "script": "emit-bleed-event.sh",
                      "event_id": event_id,
                      "log": str(month_file.relative_to(target)),
                      "ts": now}))
else:
    print(f"emit-bleed-event.sh: appended {event_id} severity={severity} type={ev_type} "
          f"→ {month_file.relative_to(target)}")
PY
