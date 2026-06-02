#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--apply] [--json]"
  exit 2
fi
repo="$1"; shift || true
apply=0; json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *) [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "repair-safe-permission-drift.sh" "repair"; exit 2 ;;
  esac
done

[[ -d "$repo" ]] || { [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_dir" "missing repo: $repo" "repair-safe-permission-drift.sh" "repair"; exit 1; }

fixed=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$apply" -eq 1 ]]; then chmod u+w "$f" && fixed=$((fixed+1)); fi
done < <(rg --files "$repo" -g "*.sh")

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if [[ "$apply" -eq 1 ]]; then chmod u+x "$f" && fixed=$((fixed+1)); fi
done < <(rg --files "${repo}/bootstrap" -g "*.sh" 2>/dev/null || true)

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"mode\":\"$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run)\",\"fixes\":${fixed}}" "repair-safe-permission-drift.sh" "repair"
else
  echo "safe_permission_repair_ok mode=$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run) fixes=${fixed}"
fi
