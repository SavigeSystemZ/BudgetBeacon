#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
compose_file="${repo_root}/ops/compose/compose.yml"

if command -v docker >/dev/null 2>&1 && [[ -f "${compose_file}" ]]; then
  docker compose -f "${compose_file}" up -d
else
  echo "no managed start command available; add app-specific start logic here"
fi
