#!/usr/bin/env bash
set -euo pipefail

# Security Scan Plugin — wraps existing scan-security.sh and optional SAST tools.
# Usage: run.sh <target-repo> <hook-name>

TARGET="${1:-.}"
HOOK="${2:-security.scan}"
REPORT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORT_FILE="${REPORT_DIR}/last-report.json"

results=()
exit_code=0

# Always run the built-in secret scanner
SCAN_SCRIPT="${TARGET}/bootstrap/scan-security.sh"
if [[ -x "${SCAN_SCRIPT}" ]]; then
  if bash "${SCAN_SCRIPT}" "${TARGET}" >/dev/null 2>&1; then
    results+=('{"tool":"scan-security","status":"pass"}')
  else
    results+=('{"tool":"scan-security","status":"warn","detail":"findings detected"}')
    exit_code=1
  fi
else
  results+=('{"tool":"scan-security","status":"skip","detail":"script not found"}')
fi

# Optional: semgrep SAST
if command -v semgrep >/dev/null 2>&1; then
  if [[ "${HOOK}" == "security.scan" ]]; then
    if semgrep --config auto --quiet --json "${TARGET}" >/dev/null 2>&1; then
      results+=('{"tool":"semgrep","status":"pass"}')
    else
      results+=('{"tool":"semgrep","status":"warn","detail":"findings detected"}')
    fi
  fi
else
  results+=('{"tool":"semgrep","status":"skip","detail":"not installed"}')
fi

# Optional: bandit (Python)
if command -v bandit >/dev/null 2>&1; then
  if [[ "${HOOK}" == "security.scan" ]]; then
    if bandit -r "${TARGET}" -q 2>/dev/null; then
      results+=('{"tool":"bandit","status":"pass"}')
    else
      results+=('{"tool":"bandit","status":"warn","detail":"findings detected"}')
    fi
  fi
fi

# Write report
printf '{"hook":"%s","results":[%s]}\n' "${HOOK}" "$(IFS=,; echo "${results[*]}")" > "${REPORT_FILE}"

echo "security_scan_complete: $(cat "${REPORT_FILE}")"
exit ${exit_code}
