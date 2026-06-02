#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 2 ]]; then
  echo "usage: $0 <target-repo> <message>"
  exit 2
fi
repo="$1"; msg="$2"
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "- ${ts} | ${msg}" >> "${repo}/_system/context/BUILD_LOG.md"
echo "build log appended"

