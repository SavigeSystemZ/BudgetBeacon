#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-tool-global-redirects.sh [--target-repo <path>] [--dry-run]
EOF
}

TARGET_REPO="$(pwd)"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-repo) TARGET_REPO="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unexpected argument: $1" >&2; exit 1 ;;
  esac
done

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"

declare -a candidates=(
  "${HOME}/.cursor/CURSOR.md"
  "${HOME}/.config/Cursor/CURSOR.md"
  "${HOME}/.config/Windsurf/WINDSURF.md"
)

for path in "${candidates[@]}"; do
  dir="$(dirname -- "${path}")"
  content="# Redirect Notice (Non-Authoritative)
Use repo-local AIAST authority in the active working repository.
Suggested local source: ${TARGET_REPO}
"
  if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "dry_run_install_tool_redirect=${path}"
    continue
  fi
  mkdir -p "${dir}"
  if [[ -f "${path}" ]]; then
    cp -p "${path}" "${path}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  printf '%s\n' "${content}" > "${path}"
  echo "installed_tool_redirect=${path}"
done
