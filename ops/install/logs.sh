#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
log_dir="${repo_root}/ops/logging"

if [[ -d "${log_dir}" ]]; then
  find "${log_dir}" -maxdepth 2 -type f | sort
else
  echo "no log directory found: ${log_dir}"
fi
