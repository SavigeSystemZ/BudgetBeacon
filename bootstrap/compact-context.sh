#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="${1:-$(pwd)}"

if [[ ! -d "${TARGET_REPO}/_system/context" ]]; then
  echo "No context directory found in ${TARGET_REPO}."
  exit 0
fi

# We define the threshold for stale files
DAYS_OLD=14
COLD_STORAGE="${TARGET_REPO}/_system/context/cold-storage"

mkdir -p "${COLD_STORAGE}"

# Find files older than DAYS_OLD in _system/context/ (excluding cold-storage and essential indexes)
STALE_FILES=$(find "${TARGET_REPO}/_system/context" -maxdepth 1 -name "*.md" -type f -mtime +${DAYS_OLD} ! -name "VALIDATION_EVIDENCE.md" ! -name "CURRENT_STATUS.md" ! -name "ARCHIVE_SUMMARY.md")

if [[ -z "${STALE_FILES}" ]]; then
  echo "No stale context files older than ${DAYS_OLD} days found."
  exit 0
fi

ARCHIVE_DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE_STAGING="${COLD_STORAGE}/staging_${ARCHIVE_DATE}"
mkdir -p "${ARCHIVE_STAGING}"

echo "Compacting the following stale context files:"
for file in $STALE_FILES; do
  echo " - $(basename "$file")"
  mv "$file" "${ARCHIVE_STAGING}/"
done

# Zip them up
cd "${COLD_STORAGE}"
tar -czf "archive_${ARCHIVE_DATE}.tar.gz" -C "staging_${ARCHIVE_DATE}" .
rm -rf "staging_${ARCHIVE_DATE}"

echo ""
echo "================================================================"
echo "SUCCESS: Stale context files have been moved to cold storage:"
echo " -> _system/context/cold-storage/archive_${ARCHIVE_DATE}.tar.gz"
echo "================================================================"
echo "ACTION REQUIRED BY AGENT:"
echo "1. If those files contained important long-term architectural decisions,"
echo "   you must read the archive and summarize them into _system/context/ARCHIVE_SUMMARY.md"
echo "2. Otherwise, no further action is needed. Context bloat has been resolved."
echo "================================================================"
