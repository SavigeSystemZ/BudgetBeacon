#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-autonomous-guardrails.sh [target-repo] [--source <template-root>] [--mode <quick|full>] [--strict] [--allow-warn]

Run recurring AIAST guardrail checks and persist timestamped artifacts under:
  _system/automation/

Modes:
  quick  -> fast confidence pass for frequent intervals
  full   -> full doctor + report + trends (default)
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_REPO=""
SOURCE=""
MODE="full"
STRICT=0
ALLOW_WARN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --allow-warn)
      ALLOW_WARN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="${DEFAULT_TARGET}"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

case "${MODE}" in
  quick|full) ;;
  *)
    echo "Unsupported mode: ${MODE}" >&2
    exit 1
    ;;
esac

AUTOMATION_DIR="${TARGET_REPO}/_system/automation"
mkdir -p "${AUTOMATION_DIR}"

STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_FILE="${AUTOMATION_DIR}/guardrails-${STAMP}.log"
DIAG_FILE="${AUTOMATION_DIR}/diagnostic-${STAMP}.json"
TREND_FILE="${AUTOMATION_DIR}/trend-${STAMP}.json"
LATEST_LINK="${AUTOMATION_DIR}/latest.log"

exec > >(tee "${LOG_FILE}") 2>&1

echo "autonomous_guardrails_start stamp=${STAMP} mode=${MODE}"
echo "target_repo=${TARGET_REPO}"

strict_flag=()
[[ ${STRICT} -eq 1 ]] && strict_flag+=(--strict)

doctor_exit=0
if [[ "${MODE}" == "quick" ]]; then
  quick_failed=0
  if ! bash "${SCRIPT_DIR}/validate-system.sh" "${TARGET_REPO}" "${strict_flag[@]}"; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/verify-integrity.sh" --check --target "${TARGET_REPO}"; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/validate-instruction-layer.sh" "${TARGET_REPO}"; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/check-system-awareness.sh" "${TARGET_REPO}"; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/check-hallucination.sh" "${TARGET_REPO}"; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/check-network-bindings.sh" "${TARGET_REPO}" --include-template-assets; then
    quick_failed=1
  fi
  if ! bash "${SCRIPT_DIR}/check-repo-permissions.sh" "${TARGET_REPO}"; then
    quick_failed=1
  fi
  if [[ ${quick_failed} -eq 1 ]]; then
    doctor_exit=1
  fi
else
  doctor_args=("${TARGET_REPO}" --record)
  if [[ -n "${SOURCE}" ]]; then
    doctor_args+=(--source "${SOURCE}")
  fi
  doctor_args+=(--report)
  doctor_args+=("${strict_flag[@]}")
  if bash "${SCRIPT_DIR}/system-doctor.sh" "${doctor_args[@]}"; then
    doctor_exit=0
  else
    doctor_exit=$?
  fi
fi
echo "system_doctor_exit=${doctor_exit}"

if [[ "${MODE}" == "quick" ]]; then
  HISTORY_FILE="${TARGET_REPO}/_system/health-history.json"
  if [[ -f "${HISTORY_FILE}" ]]; then
    quick_result="ok"
    if [[ ${doctor_exit} -ne 0 ]]; then
      quick_result="fail"
    fi
    python3 - <<'PY_QUICK_RECORD' "${HISTORY_FILE}" "${quick_result}"
import json, sys
from datetime import datetime, timezone
path, result = sys.argv[1], sys.argv[2]
try:
    entries = json.loads(open(path).read())
except Exception:
    entries = []
entries.append({"timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"), "result": result})
entries = entries[-50:]
open(path, "w").write(json.dumps(entries, indent=2) + "\n")
print(f"health_history_recorded: {result} (total={len(entries)})")
PY_QUICK_RECORD
  fi
fi

if [[ "${MODE}" == "full" ]]; then
  bash "${SCRIPT_DIR}/generate-diagnostic-report.sh" "${TARGET_REPO}" --json > "${DIAG_FILE}" || true
  bash "${SCRIPT_DIR}/report-health-trends.sh" "${TARGET_REPO}" --json > "${TREND_FILE}" || true
fi

ln -sfn "$(basename "${LOG_FILE}")" "${LATEST_LINK}"

echo "autonomous_guardrails_complete doctor_exit=${doctor_exit}"
echo "log_file=${LOG_FILE}"
[[ -f "${DIAG_FILE}" ]] && echo "diagnostic_file=${DIAG_FILE}"
[[ -f "${TREND_FILE}" ]] && echo "trend_file=${TREND_FILE}"

if [[ ${doctor_exit} -eq 1 ]]; then
  exit 1
fi

# system-doctor warns with exit 2; preserve that signal to scheduler logs.
if [[ ${doctor_exit} -eq 2 ]]; then
  if [[ ${ALLOW_WARN} -eq 1 ]]; then
    echo "autonomous_guardrails_warn_allowed=true"
    exit 0
  fi
  exit 2
fi

exit 0
