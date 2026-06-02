#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--runs N] [--json]"
  exit 2
fi
repo="$1"; shift || true
runs=3
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --runs) runs="${2:-3}"; shift 2 ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-quality-score-reproducibility.sh" "quality"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

if ! [[ "$runs" =~ ^[0-9]+$ ]] || [[ "$runs" -lt 2 ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "--runs must be >= 2" "validate-quality-score-reproducibility.sh" "quality"
  [[ "$json_mode" -eq 0 ]] && echo "--runs must be >= 2"
  exit 2
fi

scores=()
labels=()
for ((i=1; i<=runs; i++)); do
  out="$(bash "${SCRIPT_DIR}/score-quality-gates.sh" "${repo}" --json)"
  score="$(python3 - <<'PY' "$out"
import json,sys
print(json.loads(sys.argv[1])["result"]["score"])
PY
)"
  label="$(python3 - <<'PY' "$out"
import json,sys
print(json.loads(sys.argv[1])["result"]["label"])
PY
)"
  scores+=("$score")
  labels+=("$label")
done

first_score="${scores[0]}"
first_label="${labels[0]}"
repro_ok=1
for s in "${scores[@]}"; do [[ "$s" != "$first_score" ]] && repro_ok=0; done
for l in "${labels[@]}"; do [[ "$l" != "$first_label" ]] && repro_ok=0; done

if [[ "$repro_ok" -eq 1 ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "{\"runs\":${runs},\"score\":${first_score},\"label\":\"${first_label}\",\"reproducible\":true}" "validate-quality-score-reproducibility.sh" "quality"
  else
    echo "quality_score_reproducible runs=${runs} score=${first_score} label=${first_label}"
  fi
  exit 0
fi

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_error "non_reproducible_score" "quality score changed between runs" "validate-quality-score-reproducibility.sh" "quality"
else
  echo "quality_score_not_reproducible" >&2
fi
exit 1
