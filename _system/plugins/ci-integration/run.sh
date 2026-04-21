#!/usr/bin/env bash
set -euo pipefail

# CI Integration Plugin — validates CI config alignment with project profile.
# Usage: run.sh <target-repo> <hook-name>

TARGET="${1:-.}"
HOOK="${2:-ci.pre_commit}"
REPORT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ "${HOOK}" == "ci.pre_commit" ]]; then
  # Check for CI config existence
  ci_found=0
  for ci_path in ".github/workflows" ".gitlab-ci.yml" ".circleci/config.yml"; do
    if [[ -e "${TARGET}/${ci_path}" ]]; then
      ci_found=1
      break
    fi
  done

  if [[ ${ci_found} -eq 0 ]]; then
    echo "ci_integration_warn: no CI configuration found"
    exit 0
  fi

  echo "ci_integration_ok: CI configuration present"

elif [[ "${HOOK}" == "ci.post_test" ]]; then
  # Record test completion timestamp
  echo "{\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"hook\":\"${HOOK}\",\"status\":\"recorded\"}" \
    > "${REPORT_DIR}/last-test-record.json"
  echo "ci_integration_ok: test result recorded"
fi
