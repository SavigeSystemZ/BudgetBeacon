#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"

if [[ -x "${repo_root}/bootstrap/check-runtime-foundations.sh" ]]; then
  bash "${repo_root}/bootstrap/check-runtime-foundations.sh" "${repo_root}"
else
  echo "runtime foundation checker not installed; basic doctor only"
fi
