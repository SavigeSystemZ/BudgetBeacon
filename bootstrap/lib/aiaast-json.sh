#!/usr/bin/env bash
# aiaast-json.sh — JSON envelope helpers (bool/ok/error)
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

aiaast_json_bool() {
  local value="${1:-0}"
  if [[ "${value}" == "1" || "${value}" == "true" ]]; then
    printf "true"
  else
    printf "false"
  fi
}

aiaast_json_ok() {
  local payload="${1-}"
  [[ -n "${payload}" ]] || payload='{}'
  local script_name="${2:-unknown-script}"
  local mode="${3:-default}"
  local timestamp
  timestamp="$(aiaast_iso_utc_now)"
  python3 - "$payload" "$script_name" "$mode" "$timestamp" <<'PY'
import json, sys
payload, script_name, mode, timestamp = sys.argv[1:]
try:
    result = json.loads(payload)
except Exception:
    result = {"raw": payload}
print(json.dumps({
    "ok": True,
    "script": script_name,
    "timestamp": timestamp,
    "mode": mode,
    "result": result
}))
PY
}

aiaast_json_error() {
  local code="${1:-unknown_error}"
  local message="${2:-operation failed}"
  local script_name="${3:-unknown-script}"
  local mode="${4:-default}"
  local details="${5:-}"
  local timestamp
  timestamp="$(aiaast_iso_utc_now)"
  python3 - "$code" "$message" "$script_name" "$mode" "$details" "$timestamp" <<'PY'
import json, sys
code, message, script_name, mode, details, timestamp = sys.argv[1:]
payload = {
    "ok": False,
    "script": script_name,
    "timestamp": timestamp,
    "mode": mode,
    "error": {"code": code, "message": message}
}
if details:
    try:
        payload["error"]["details"] = json.loads(details)
    except Exception:
        payload["error"]["details"] = details
print(json.dumps(payload))
PY
}

# --- Path classification helpers ---
