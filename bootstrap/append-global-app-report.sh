#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--sink PATH] [--approve-external-write] [--json]"
  exit 2
fi
repo="$1"; shift || true
sink=""
approve=0
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sink) sink="${2:-}"; shift 2 ;;
    --approve-external-write) approve=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "append-global-app-report.sh" "report-sink"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

if [[ -z "$sink" ]]; then
  if [[ -n "${AIAST_GLOBAL_APP_REPORT:-}" ]]; then
    sink="${AIAST_GLOBAL_APP_REPORT}"
  elif [[ -f "${repo}/registry/global_report_sink.yaml" ]]; then
    sink="$(python3 - "${repo}/registry/global_report_sink.yaml" <<'PY'
import sys
print(open(sys.argv[1], "r", encoding="utf-8").read().strip().split(":")[-1].strip())
PY
)"
  else
    sink="${repo}/_system/context/global-app-report.log"
  fi
fi

line="$(date -u +"%Y-%m-%dT%H:%M:%SZ"),repo=${repo},status=recorded"
mode="dry-run"
if [[ "$approve" -eq 1 ]]; then
  mkdir -p "$(dirname "$sink")"
  printf "%s\n" "$line" >> "$sink"
  mode="apply"
fi

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"sink\":\"${sink}\",\"approved\":$([[ "$approve" -eq 1 ]] && echo true || echo false)}" "append-global-app-report.sh" "$mode"
else
  echo "global_app_report_${mode} sink=${sink}"
fi
