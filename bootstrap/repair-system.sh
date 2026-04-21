#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_SOURCE="${LOCAL_REPO_ROOT}"

usage() {
  cat <<'EOF'
Usage: repair-system.sh [target-repo] [--source <template-root>] [--strict] [--dry-run]

Restore missing or drifted template-managed files while preserving app-owned state.
EOF
}

TARGET_REPO=""
SOURCE="${DEFAULT_SOURCE}"
STRICT=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="${LOCAL_REPO_ROOT}"
fi

args=("${TARGET_REPO}" "--source" "${SOURCE}" "--refresh-managed")
[[ ${STRICT} -eq 1 ]] && args+=("--strict")
[[ ${DRY_RUN} -eq 1 ]] && args+=("--dry-run")

bash "${SCRIPT_DIR}/update-template.sh" "${args[@]}"
