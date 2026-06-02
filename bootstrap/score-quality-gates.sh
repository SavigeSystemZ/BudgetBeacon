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

if ! bash "${SCRIPT_DIR}/validate-quality-score-policy.sh" "${repo}" >/dev/null 2>&1; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "invalid_policy" "quality score policy validation failed" "score-quality-gates.sh" "quality"
  else
    echo "quality_score_policy_invalid"
  fi
  exit 1
fi

score_payload="$(python3 - "$repo" <<'PY'
from __future__ import annotations
import json
import os
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
policy = repo / "_system" / "QUALITY_SCORE_POLICY.json"
if not policy.is_file():
    print(json.dumps({"error": "missing policy", "score": 0, "label": "not_ready"}))
    raise SystemExit(0)

cfg = json.loads(policy.read_text(encoding="utf-8"))
weights = cfg.get("weights", {})
required_keys = cfg.get("required_weight_keys") or list(weights.keys())

checks = {
    "instruction_precedence_contract": (repo / "_system" / "INSTRUCTION_PRECEDENCE_CONTRACT.md").is_file(),
    "workspace_authority_contract": (repo / "_system" / "WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md").is_file(),
    "scaffold_profile_matrix": (repo / "_system" / "SCAFFOLD_PROFILE_MATRIX.md").is_file(),
    "archetype_routing_matrix": (repo / "_system" / "APP_ARCHETYPE_ROUTING_MATRIX.md").is_file(),
    "validate_system_script": os.access(repo / "bootstrap" / "validate-system.sh", os.X_OK),
    "fleet_readiness_script": os.access(repo / "bootstrap" / "check-fleet-readiness.sh", os.X_OK),
    "security_hardening_contract": (repo / "_system" / "SECURITY_HARDENING_CONTRACT.md").is_file(),
    "network_bindings_script": os.access(repo / "bootstrap" / "check-network-bindings.sh", os.X_OK),
    "runtime_foundations_script": os.access(repo / "bootstrap" / "check-runtime-foundations.sh", os.X_OK),
    "delivery_gates_doc": (repo / "_system" / "DELIVERY_GATES.md").is_file(),
}

missing_score_checks = sorted(set(required_keys) - set(checks))
if missing_score_checks:
    print(json.dumps({
        "error": "policy references checks not implemented by score-quality-gates.sh",
        "missing_score_checks": missing_score_checks,
        "score": 0,
        "label": "not_ready",
        "policy_version": cfg.get("version", "unknown"),
    }))
    raise SystemExit(0)

score = 0
checks_passed = []
checks_failed = []
for key in required_keys:
    ok = checks.get(key, False)
    if ok:
        score += int(weights.get(key, 0))
        checks_passed.append(key)
    else:
        checks_failed.append(key)

labels = sorted(cfg.get("labels", []), key=lambda x: int(x.get("min_score", 0)), reverse=True)
label = "not_ready"
for item in labels:
    if score >= int(item.get("min_score", 0)):
        label = str(item.get("name", "not_ready"))
        break

print(json.dumps({
    "score": score,
    "label": label,
    "policy_version": cfg.get("version", "unknown"),
    "checks_passed": checks_passed,
    "checks_failed": checks_failed,
}))
PY
)"
score_error="$(python3 - <<'PY' "$score_payload"
import json,sys
print(json.loads(sys.argv[1]).get("error", ""))
PY
)"
if [[ -n "${score_error}" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "quality_score_contract_mismatch" "${score_error}" "score-quality-gates.sh" "quality" "${score_payload}"
  else
    printf 'quality_score_contract_mismatch %s\n' "${score_error}" >&2
  fi
  exit 1
fi
score="$(python3 - <<'PY' "$score_payload"
import json,sys
print(json.loads(sys.argv[1]).get("score", 0))
PY
)"
label="$(python3 - <<'PY' "$score_payload"
import json,sys
print(json.loads(sys.argv[1]).get("label", "not_ready"))
PY
)"
policy_version="$(python3 - <<'PY' "$score_payload"
import json,sys
print(json.loads(sys.argv[1]).get("policy_version", "unknown"))
PY
)"
checks_passed="$(python3 - <<'PY' "$score_payload"
import json,sys
print(len(json.loads(sys.argv[1]).get("checks_passed", [])))
PY
)"
checks_failed="$(python3 - <<'PY' "$score_payload"
import json,sys
print(len(json.loads(sys.argv[1]).get("checks_failed", [])))
PY
)"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"score\":${score},\"label\":\"${label}\",\"policy_version\":\"${policy_version}\",\"checks_passed\":${checks_passed},\"checks_failed\":${checks_failed}}" "score-quality-gates.sh" "quality"
else
  echo "quality_score=${score} label=${label} policy_version=${policy_version} checks_passed=${checks_passed} checks_failed=${checks_failed}"
fi
