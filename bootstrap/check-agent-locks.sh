#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--strict] [--json]"
  exit 2
fi
repo="$1"
strict=0
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) strict=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-agent-locks.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2 ;;
  esac
done
lock_dir="${repo}/_system/agent-state/locks"
if ! aiaast_require_dir "$lock_dir"; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_lock_dir" "missing lock dir: $lock_dir" "check-agent-locks.sh" "validation"
  fi
  exit 1
fi
count="$( (rg --files "$lock_dir" -g "*.lock.json" || true) | wc -l)"
if [[ "$json_mode" -eq 1 ]]; then
  echo "lock files: $count" >&2
else
  echo "lock files: $count"
fi
if [[ "$count" -eq 0 ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "$(python3 - "$strict" <<'PY'
import json, sys
strict = sys.argv[1] == "1"
print(json.dumps({"lock_files": 0, "strict": strict}))
PY
)" "check-agent-locks.sh" "validation"
  else
    echo "agent lock check: PASS"
  fi
else
  if ! python3 - "$lock_dir" "$strict" <<'PY'
import json, os, sys
from datetime import datetime, timezone
lock_dir = sys.argv[1]
strict = sys.argv[2] == "1"
now = datetime.now(timezone.utc)
failed = False
expired = []
for name in sorted(os.listdir(lock_dir)):
    path = os.path.join(lock_dir, name)
    if not os.path.isfile(path) or not name.endswith(".lock.json"):
        continue
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    for field in ("scope", "owner_agent_id", "lease_expires_at"):
        if field not in data:
            print(f"invalid lock missing field {field}: {path}")
            failed = True
    exp = data.get("lease_expires_at")
    if isinstance(exp, str):
        exp_dt = datetime.strptime(exp, "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
        if exp_dt < now:
            expired.append(path)
if expired:
    for p in expired:
        print(f"expired lease: {p}")
    if strict:
        failed = True
if failed:
    raise SystemExit(1)
PY
  then
    if [[ "$json_mode" -eq 1 ]]; then
      aiaast_json_error "invalid_or_expired_locks" "agent lock check failed" "check-agent-locks.sh" "validation"
    else
      echo "agent lock check: FAIL"
    fi
    exit 1
  else
    if [[ "$json_mode" -eq 1 ]]; then
      aiaast_json_ok "$(python3 - "$count" "$strict" <<'PY'
import json, sys
count = int(sys.argv[1])
strict = sys.argv[2] == "1"
print(json.dumps({"lock_files": count, "strict": strict}))
PY
)" "check-agent-locks.sh" "validation"
    else
      echo "agent lock check: PASS"
    fi
  fi
fi

