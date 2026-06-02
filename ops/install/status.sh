#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"

echo "status: installed"
echo "repo: ${repo_root}"
if [[ -f "${repo_root}/_system/.template-install.json" ]]; then
  echo "aiaast: present"
else
  echo "aiaast: unknown"
fi
