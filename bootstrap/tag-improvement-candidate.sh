#!/usr/bin/env bash
set -euo pipefail

# tag-improvement-candidate.sh
# Register a file or pattern as a generic improvement candidate for AIAST.

usage() {
  echo "Usage: tag-improvement-candidate.sh <file-path> --description \"...\""
}

if [[ $# -lt 3 ]]; then
  usage
  exit 1
fi

FILE_PATH="$1"
DESCRIPTION=""

shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --description)
      DESCRIPTION="$2"
      shift 2
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ ! -e "${FILE_PATH}" ]]; then
  echo "Error: File or directory not found: ${FILE_PATH}" >&2
  exit 1
fi

CANDIDATE_REGISTRY="_system/improvement-candidates.jsonl"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPO_NAME=$(basename "$(pwd)")

# Ensure _system exists
mkdir -p _system

# Add to registry
printf '{"timestamp": "%s", "repo": "%s", "path": "%s", "description": "%s"}\n' \
  "${TIMESTAMP}" "${REPO_NAME}" "${FILE_PATH}" "${DESCRIPTION}" \
  >> "${CANDIDATE_REGISTRY}"

echo "Registered improvement candidate: ${FILE_PATH}"
echo "It will be reviewed by AIAST maintainers during the next harvest."
