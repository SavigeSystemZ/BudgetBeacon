#!/usr/bin/env bash
# check-pending-meta-sync.sh
#
# S19e — startup gate. Run as the first step of any agent session in a
# downstream repo to detect an unreconciled meta-system sync.
#
# Exit codes:
#   0 — no pending marker, OR pending marker present but operating in
#       default (informational) mode
#   1 — pending marker present AND --strict was passed (use in CI /
#       autopilots that must not proceed across an unreconciled sync)
#
# JSON envelope on --json:
#   { "ok": bool,
#     "result": "meta_sync_pending_none" | "meta_sync_pending",
#     "pending": null | { emitted_at, event, refresh_managed,
#                          template { before, after, source_root },
#                          changeset_summary { missing, drifted,
#                                              always_refresh, host_settings } },
#     "next_step": "bash bootstrap/reconcile-meta-sync.sh"
#   }
#
# See _system/META_SYNC_RECONCILE_PROTOCOL.md.

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

TARGET=""
EMIT_JSON=0
STRICT=0
shift_count=0
if [[ $# -gt 0 && "${1:-}" != --* ]]; then
  TARGET="$1"; shift_count=1
fi
shift "${shift_count}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)   EMIT_JSON=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: check-pending-meta-sync.sh [TARGET] [--json] [--strict]

Reports whether _system/agent-state/meta-sync/PENDING.json exists.
Default mode is informational (rc=0). --strict makes pending → rc=1.
See _system/META_SYNC_RECONCILE_PROTOCOL.md.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

export CPMS_TARGET="${TARGET}"
export CPMS_EMIT_JSON="${EMIT_JSON}"
export CPMS_STRICT="${STRICT}"

python3 <<'PY'
import json, os, sys
from pathlib import Path

target = Path(os.environ["CPMS_TARGET"])
emit_json = os.environ["CPMS_EMIT_JSON"] == "1"
strict = os.environ["CPMS_STRICT"] == "1"

marker = target / "_system/agent-state/meta-sync/PENDING.json"
if not marker.exists():
    env = {"ok": True, "result": "meta_sync_pending_none",
           "pending": None,
           "next_step": None}
    if emit_json:
        print(json.dumps(env, indent=2))
    else:
        print("meta_sync_pending_none")
    sys.exit(0)

try:
    payload = json.loads(marker.read_text(encoding="utf-8"))
except Exception as e:
    env = {"ok": False, "result": "meta_sync_pending_malformed",
           "error": str(e), "pending_path": str(marker),
           "next_step": "inspect or remove the malformed marker, then re-emit"}
    if emit_json:
        print(json.dumps(env, indent=2))
    else:
        print(f"meta_sync_pending_malformed: {e}", file=sys.stderr)
    sys.exit(1 if strict else 0)

cs = payload.get("changeset", {}) or {}
summary = {
    "missing": len(cs.get("missing_installed", []) or []),
    "drifted": len(cs.get("drifted_refreshed", []) or []),
    "always_refresh": len(cs.get("always_refresh_applied", []) or []),
    "host_settings": cs.get("host_settings"),
}

env = {
    "ok": (not strict),
    "result": "meta_sync_pending",
    "pending": {
        "emitted_at":        payload.get("emitted_at"),
        "event":             (payload.get("emitter") or {}).get("event"),
        "refresh_managed":   (payload.get("emitter") or {}).get("refresh_managed"),
        "host_running":      (payload.get("emitter") or {}).get("host_running"),
        "actor":             (payload.get("emitter") or {}).get("actor"),
        "template":          payload.get("template"),
        "changeset_summary": summary,
    },
    "next_step": payload.get("next_step", "bash bootstrap/reconcile-meta-sync.sh"),
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    p = env["pending"]
    print(f"meta_sync_pending emitted_at={p['emitted_at']} event={p['event']} "
          f"missing={summary['missing']} drifted={summary['drifted']} "
          f"always_refresh={summary['always_refresh']}", file=sys.stderr)
    print(f"  → run: {env['next_step']}", file=sys.stderr)

sys.exit(1 if strict else 0)
PY
