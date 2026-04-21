#!/usr/bin/env bash
set -euo pipefail

# Observability Setup Plugin — checks and scaffolds observability surfaces.
# Usage: run.sh <target-repo> <hook-name>

TARGET="${1:-.}"
HOOK="${2:-monitoring.setup}"
REPORT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PROFILE="${TARGET}/_system/PROJECT_PROFILE.md"
results=()

if [[ ! -f "${PROFILE}" ]]; then
  echo "observability_warn: PROJECT_PROFILE.md not found"
  exit 0
fi

# Check for health endpoint declaration
if grep -q "Health endpoint" "${PROFILE}" 2>/dev/null; then
  results+=('health_endpoint: declared')
else
  results+=('health_endpoint: not_declared')
fi

# Check for structured logging
if grep -qi "structured.log" "${PROFILE}" 2>/dev/null || \
   grep -qi "logging" "${PROFILE}" 2>/dev/null; then
  results+=('structured_logging: declared')
else
  results+=('structured_logging: not_declared')
fi

# Check for observability standards
OBS_STANDARDS="${TARGET}/_system/OBSERVABILITY_STANDARDS.md"
if [[ -f "${OBS_STANDARDS}" ]]; then
  results+=('observability_standards: present')
else
  results+=('observability_standards: missing')
fi

printf '%s\n' "${results[@]}"
echo "observability_check_complete"
