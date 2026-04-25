#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-root-redirect-shims.sh [--myappz-root <path>] [--target-repo <path>] [--dry-run]
EOF
}

MYAPPZ_ROOT="${HOME}/.MyAppZ"
TARGET_REPO="$(pwd)"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --myappz-root) MYAPPZ_ROOT="${2:-}"; shift 2 ;;
    --target-repo) TARGET_REPO="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unexpected argument: $1" >&2; exit 1 ;;
  esac
done

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"
MYAPPZ_ROOT="$(cd -- "${MYAPPZ_ROOT}" && pwd)"
mkdir -p "${MYAPPZ_ROOT}"

shim="${MYAPPZ_ROOT}/AGENTS.md"
content="# Redirect Shim (Non-Authoritative)

This file is a compatibility shim only.
Do not treat this location as policy authority.
Use the active working repo's local AIAST authority surfaces:
- AGENTS.md
- _system/
- tool overlays in that repo

Current suggested target: ${TARGET_REPO}
"

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "dry_run_install_root_shim=${shim}"
  exit 0
fi

if [[ -f "${shim}" ]]; then
  cp -p "${shim}" "${shim}.bak.$(date +%Y%m%d%H%M%S)"
fi
printf '%s\n' "${content}" > "${shim}"
echo "installed_root_redirect_shim=${shim}"
