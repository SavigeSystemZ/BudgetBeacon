#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 [--app-root PATH]"
}

APP_ROOT="${APP_ROOT:-}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-root) APP_ROOT="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done

if [[ -z "${APP_ROOT}" ]]; then
  cwd="$(pwd)"
  if [[ "${cwd}" == */app-runtime ]] || [[ "${cwd}" == */app-meta ]]; then
    APP_ROOT="$(dirname "${cwd}")"
  else
    APP_ROOT="${cwd}"
  fi
fi

ops_dir="${APP_ROOT}/ops"
log_file="${ops_dir}/logs/operations.jsonl"
session_notes="${ops_dir}/SESSION_NOTES.md"
recovery_ledger="${ops_dir}/RECOVERY_LEDGER.md"
mkdir -p "${ops_dir}/logs"

python3 - "${log_file}" "${session_notes}" "${recovery_ledger}" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone

log_file, session_notes, recovery_ledger = sys.argv[1:]
events = []
if os.path.isfile(log_file):
    with open(log_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                events.append(json.loads(line))
            except json.JSONDecodeError:
                continue

events = events[-200:]
ok = [e for e in events if e.get("status") == "ok"]
issues = [e for e in events if e.get("status") in {"warn", "error"}]
ts = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

with open(session_notes, "w", encoding="utf-8") as f:
    f.write("# Session Notes\n\n")
    f.write(f"- Generated at: {ts}\n")
    f.write(f"- Successful operations captured: {len(ok)}\n\n")
    f.write("## Recent successful events\n\n")
    for e in ok[-20:]:
        f.write(f"- `{e.get('timestamp','')}` {e.get('tool','')}:{e.get('command','')} status={e.get('status','')}\n")

with open(recovery_ledger, "w", encoding="utf-8") as f:
    f.write("# Recovery Ledger\n\n")
    f.write(f"- Generated at: {ts}\n")
    f.write(f"- Recovery-relevant events: {len(issues)}\n\n")
    f.write("## Warnings and errors\n\n")
    if not issues:
        f.write("- none\n")
    for e in issues[-50:]:
        details = e.get("details", {})
        f.write(
            f"- `{e.get('timestamp','')}` {e.get('tool','')}:{e.get('command','')}"
            f" status={e.get('status','')} details={json.dumps(details, sort_keys=True)}\n"
        )
PY

echo "ops_notes_generated session=${session_notes} recovery=${recovery_ledger}"
