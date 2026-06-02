#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--json]"
  exit 2
fi
repo="$1"; shift || true
json_mode=0
[[ "${1:-}" == "--json" ]] && json_mode=1
out="${repo}/_system/context/VALIDATION_EVIDENCE.md"
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
repo_name="$(basename "$repo")"

cat >"$out" <<EOF
# Status Report

- timestamp: ${ts}
- repo: ${repo_name}
- next_step: run strict validation lane and review score
EOF

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"output\":\"${out}\"}" "emit-status-report.sh" "status"
else
  echo "status_report_emitted output=${out}"
fi
