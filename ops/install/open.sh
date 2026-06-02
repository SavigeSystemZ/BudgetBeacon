#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
url_file="${repo_root}/registry/ports.yaml"

if [[ -f "${url_file}" ]]; then
  echo "open target hints: ${url_file}"
else
  echo "no open target configured"
fi
