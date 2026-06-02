#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo>"
  exit 2
fi
repo="$1"
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-tool-memory-alignment.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2
      ;;
  esac
done
dir="${repo}/_system/tool-memory"
[[ -d "$dir" ]] || {
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_dir" "missing tool-memory dir" "check-tool-memory-alignment.sh" "validation"
  else
    echo "missing tool-memory dir"
  fi
  exit 1
}
for f in claude-memory.md cursor-memory.md codex-memory.md gemini-memory.md copilot-memory.md aider-memory.md agent-zero-memory.md local-model-memory.md; do
  [[ -f "${dir}/${f}" ]] || {
    if [[ "$json_mode" -eq 1 ]]; then
      aiaast_json_error "missing_file" "missing ${dir}/${f}" "check-tool-memory-alignment.sh" "validation"
    else
      echo "missing ${dir}/${f}"
    fi
    exit 1
  }
done
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass"}' "check-tool-memory-alignment.sh" "validation"
else
  echo "tool memory alignment: PASS"
fi

