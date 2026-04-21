#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: scaffold-system.sh [target-repo] [--app-name NAME] [--source <template-root>] [--strict] [--dry-run] [--refresh-managed]

Smart AIAST lifecycle entrypoint:
  - first install into a repo that does not have AIAST yet
  - additive backfill/update for an installed repo
  - managed refresh when --refresh-managed is explicitly requested
EOF
}

TARGET_REPO=""
APP_NAME=""
SOURCE=""
STRICT=0
DRY_RUN=0
REFRESH_MANAGED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
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
    --refresh-managed)
      REFRESH_MANAGED=1
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

if [[ -z "${TARGET_REPO}" && -t 0 ]]; then
  printf 'Target repo path: '
  read -r TARGET_REPO
fi

if [[ -z "${TARGET_REPO}" ]]; then
  usage
  exit 1
fi

if [[ ${DRY_RUN} -eq 0 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

TARGET_REPO="$(cd -- "${TARGET_REPO}" 2>/dev/null && pwd || echo "${TARGET_REPO}")"

if [[ -d "${TARGET_REPO}" && ${DRY_RUN} -eq 0 ]]; then
  if ! bash "${SCRIPT_DIR}/check-repo-permissions.sh" "${TARGET_REPO}" >/dev/null 2>&1; then
    echo "Warning: Target repo has permission issues (likely root-owned files)." >&2
    echo "This may cause the scaffold to fail." >&2
    echo "Run the following command to repair permissions if needed:" >&2
    echo "  sudo bash ${SCRIPT_DIR}/repair-myappz-root-ownership.sh ${TARGET_REPO} --apply" >&2
    echo ""
  fi
fi

CANONICAL_SOURCE=""
if [[ -n "${SOURCE}" ]]; then
  CANONICAL_SOURCE="$(cd -- "${SOURCE}" && pwd)"
elif [[ -f "${REPO_ROOT}/_AIAST/TEMPLATE/.installable-product-root" ]]; then
  CANONICAL_SOURCE="$(cd -- "${REPO_ROOT}/_AIAST/TEMPLATE" && pwd)"
elif [[ -f "${REPO_ROOT}/.installable-product-root" && ! -d "${REPO_ROOT}/apps" ]]; then
  CANONICAL_SOURCE="${REPO_ROOT}"
fi

IS_INSTALLED=0
if [[ -f "${TARGET_REPO}/_system/.template-install.json" || ( -f "${TARGET_REPO}/AGENTS.md" && -d "${TARGET_REPO}/_system" ) ]]; then
  IS_INSTALLED=1
fi

if [[ ${IS_INSTALLED} -eq 0 ]]; then
  if [[ -z "${CANONICAL_SOURCE}" ]]; then
    echo "Cannot resolve a canonical AIAST template source for first install." >&2
    echo "Provide --source <template-root> or keep a local _AIAST/TEMPLATE copy." >&2
    exit 1
  fi

  cmd=(bash "${CANONICAL_SOURCE}/bootstrap/init-project.sh" "${TARGET_REPO}")
  if [[ -n "${APP_NAME}" ]]; then
    cmd+=(--app-name "${APP_NAME}")
  fi
  if [[ ${STRICT} -eq 1 ]]; then
    cmd+=(--strict)
  fi
  if [[ ${DRY_RUN} -eq 1 ]]; then
    cmd+=(--dry-run)
  fi

  echo "scaffold-system: first install"
  exec "${cmd[@]}"
fi

if [[ -z "${CANONICAL_SOURCE}" || "${CANONICAL_SOURCE}" == "${TARGET_REPO}" ]]; then
  echo "Installed repo detected, but no separate canonical template source was resolved." >&2
  echo "Provide --source <template-root> or keep a local _AIAST/TEMPLATE copy for additive updates." >&2
  exit 1
fi

cmd=(bash "${CANONICAL_SOURCE}/bootstrap/update-template.sh" "${TARGET_REPO}" --source "${CANONICAL_SOURCE}")
if [[ ${STRICT} -eq 1 ]]; then
  cmd+=(--strict)
fi
if [[ ${DRY_RUN} -eq 1 ]]; then
  cmd+=(--dry-run)
fi
if [[ ${REFRESH_MANAGED} -eq 1 ]]; then
  cmd+=(--refresh-managed)
fi

if [[ ${REFRESH_MANAGED} -eq 1 ]]; then
  echo "scaffold-system: managed update"
else
  echo "scaffold-system: additive backfill/update"
fi

exec "${cmd[@]}"
