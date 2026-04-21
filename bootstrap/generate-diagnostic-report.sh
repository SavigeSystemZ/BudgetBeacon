#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate-diagnostic-report.sh <target-repo> [--json]

Run all system-doctor checks, environment checks, drift detection, and plugin status.
Output a structured diagnostic report.
EOF
}

TARGET=""
JSON_OUTPUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET}" ]]; then
        TARGET="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  usage; exit 1
fi

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Gather AIAST version
AIAST_VERSION="unknown"
if [[ -f "${TARGET}/_system/.template-version" ]]; then
  AIAST_VERSION="$(cat "${TARGET}/_system/.template-version")"
fi

# Run validation
VALIDATION_STATUS="unknown"
if bash "${SCRIPT_DIR}/validate-system.sh" "${TARGET}" >/dev/null 2>&1; then
  VALIDATION_STATUS="pass"
else
  VALIDATION_STATUS="fail"
fi

# Run environment check
ENV_STATUS="unknown"
ENV_REPORT=""
if [[ -x "${SCRIPT_DIR}/check-environment.sh" ]]; then
  ENV_REPORT=$(bash "${SCRIPT_DIR}/check-environment.sh" "${TARGET}" --json 2>/dev/null || echo '{"checks":[],"warnings":0,"failures":0}')
  if echo "${ENV_REPORT}" | python3 -c "import sys,json; d=json.load(sys.stdin); sys.exit(0 if d.get('failures',0)==0 else 1)" 2>/dev/null; then
    ENV_STATUS="pass"
  else
    ENV_STATUS="warn"
  fi
fi

# Check drift
DRIFT_STATUS="unknown"
if [[ -x "${SCRIPT_DIR}/detect-drift.sh" ]]; then
  if bash "${SCRIPT_DIR}/detect-drift.sh" "${TARGET}" >/dev/null 2>&1; then
    DRIFT_STATUS="clean"
  else
    DRIFT_STATUS="drift_detected"
  fi
fi

# Discover plugins
PLUGIN_REPORT=""
if [[ -x "${SCRIPT_DIR}/discover-plugins.sh" ]]; then
  PLUGIN_REPORT=$(bash "${SCRIPT_DIR}/discover-plugins.sh" "${TARGET}" --json 2>/dev/null || echo '{"plugins":[],"count":0}')
fi

# Git status snapshot
GIT_BRANCH="none"
GIT_DIRTY="false"
if git -C "${TARGET}" rev-parse --git-dir >/dev/null 2>&1; then
  GIT_BRANCH=$(git -C "${TARGET}" branch --show-current 2>/dev/null || echo "detached")
  if [[ -n "$(git -C "${TARGET}" status --porcelain 2>/dev/null)" ]]; then
    GIT_DIRTY="true"
  fi
fi

if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  cat <<ENDJSON
{
  "timestamp": "${TIMESTAMP}",
  "aiast_version": "${AIAST_VERSION}",
  "validation": "${VALIDATION_STATUS}",
  "environment": ${ENV_REPORT:-"{}"},
  "drift": "${DRIFT_STATUS}",
  "plugins": ${PLUGIN_REPORT:-"{}"},
  "git": {"branch": "${GIT_BRANCH}", "dirty": ${GIT_DIRTY}}
}
ENDJSON
else
  echo "=== AIAST Diagnostic Report ==="
  echo "Timestamp:  ${TIMESTAMP}"
  echo "Version:    ${AIAST_VERSION}"
  echo "Validation: ${VALIDATION_STATUS}"
  echo "Environment: ${ENV_STATUS}"
  echo "Drift:      ${DRIFT_STATUS}"
  echo "Git:        ${GIT_BRANCH} (dirty=${GIT_DIRTY})"
  echo ""
  if [[ -n "${PLUGIN_REPORT}" ]]; then
    PLUGIN_COUNT=$(echo "${PLUGIN_REPORT}" | python3 -c "import sys,json; print(json.load(sys.stdin).get('count',0))" 2>/dev/null || echo "0")
    echo "Plugins:    ${PLUGIN_COUNT} discovered"
  fi
  echo ""
  echo "diagnostic_report_complete"
fi
