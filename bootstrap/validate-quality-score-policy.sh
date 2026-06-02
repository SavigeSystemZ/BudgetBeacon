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
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-quality-score-policy.sh" "quality"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

policy="${repo}/_system/QUALITY_SCORE_POLICY.json"
schema="${repo}/_system/quality-gates/quality-score-policy.schema.json"

for f in "$policy" "$schema"; do
  if ! aiaast_require_file "$f"; then
    [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing: $f" "validate-quality-score-policy.sh" "quality"
    exit 1
  fi
done

py_out_file="$(mktemp)"
if ! python3 - "$policy" "$schema" >"${py_out_file}" <<'PY'
from __future__ import annotations
import json
import re
import sys
policy = json.loads(open(sys.argv[1], "r", encoding="utf-8").read())
schema = json.loads(open(sys.argv[2], "r", encoding="utf-8").read())

SUPPORTED_MAJOR = 1

required = schema.get("required", [])
for key in required:
    if key not in policy:
        raise SystemExit(f"missing required key: {key}")

version = str(policy.get("version", ""))
match = re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", version)
if not match:
    raise SystemExit("version must be semantic version MAJOR.MINOR.PATCH")
major, minor, patch = (int(part) for part in match.groups())
if major != SUPPORTED_MAJOR:
    raise SystemExit(f"unsupported policy major version: {major}")

weights = policy.get("weights", {})
if not isinstance(weights, dict) or not weights:
    raise SystemExit("weights must be a non-empty object")
for key, value in weights.items():
    if not isinstance(key, str) or not key:
        raise SystemExit("weight key must be a non-empty string")
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise SystemExit(f"weight must be a non-negative integer: {key}")

required_weight_keys = policy.get("required_weight_keys", [])
if not isinstance(required_weight_keys, list) or not required_weight_keys:
    raise SystemExit("required_weight_keys must be a non-empty array")
if any(not isinstance(item, str) or not item for item in required_weight_keys):
    raise SystemExit("required weight key must be a non-empty string")
if len(set(required_weight_keys)) != len(required_weight_keys):
    raise SystemExit("required_weight_keys must be unique")

declared = set(required_weight_keys)
actual = set(weights)
missing = sorted(declared - actual)
extra = sorted(actual - declared)
if missing:
    raise SystemExit("weights missing required keys: " + ", ".join(missing))
if extra:
    raise SystemExit("weights include undeclared keys: " + ", ".join(extra))

weight_sum = sum(weights.values())
expected = int(policy.get("expected_weight_sum", 0))
if weight_sum != expected:
    raise SystemExit(f"weight sum mismatch: got {weight_sum}, expected {expected}")

labels = policy.get("labels", [])
if not isinstance(labels, list) or not labels:
    raise SystemExit("labels must be a non-empty array")
seen_label_names = set()
last_min_score = None
for item in labels:
    if not isinstance(item, dict):
        raise SystemExit("label entry must be object")
    if "name" not in item or "min_score" not in item:
        raise SystemExit("label missing name/min_score")
    name = item["name"]
    min_score = item["min_score"]
    if not isinstance(name, str) or not name:
        raise SystemExit("label name must be a non-empty string")
    if name in seen_label_names:
        raise SystemExit(f"duplicate label name: {name}")
    seen_label_names.add(name)
    if not isinstance(min_score, int) or isinstance(min_score, bool):
        raise SystemExit(f"label min_score must be integer: {name}")
    if min_score < 0 or min_score > expected:
        raise SystemExit(f"label min_score out of range: {name}")
    if last_min_score is not None and min_score >= last_min_score:
        raise SystemExit("labels must be sorted by descending min_score")
    last_min_score = min_score
if labels[-1]["min_score"] != 0:
    raise SystemExit("lowest label must start at min_score 0")

print(json.dumps({
    "status": "pass",
    "policy_version": version,
    "supported_version": True,
    "semantic_version": {"major": major, "minor": minor, "patch": patch},
    "weight_sum": weight_sum,
    "required_weight_count": len(required_weight_keys),
    "label_count": len(labels),
}))
PY
then
  rm -f "${py_out_file}"
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_policy" "quality score policy failed validation" "validate-quality-score-policy.sh" "quality"
  [[ "$json_mode" -eq 0 ]] && echo "quality_score_policy_invalid"
  exit 1
fi

validation_payload="$(cat "${py_out_file}")"
if [[ "$json_mode" -eq 0 ]]; then
  printf '%s\n' "${validation_payload}"
fi
rm -f "${py_out_file}"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "${validation_payload}" "validate-quality-score-policy.sh" "quality"
else
  echo "quality_score_policy_ok"
fi
