#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: init-project.sh <target-repo> [--app-name NAME] [--strict] [--dry-run]
                       [--install-root-shims] [--install-tool-global-redirects]
                       [--seed-orphan-meta-snapshot] [--myappz-root <path>]
                       [--template-root <path>] [--no-global-writes]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
APP_NAME=""
STRICT=0
DRY_RUN=0
README_DEST="README.md"
INSTALL_ROOT_SHIMS=0
INSTALL_TOOL_GLOBAL_REDIRECTS=0
SEED_ORPHAN_META_SNAPSHOT=0
NO_GLOBAL_WRITES=0
MYAPPZ_ROOT="${HOME}/.MyAppZ"
TEMPLATE_ROOT_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
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
    --install-root-shims)
      INSTALL_ROOT_SHIMS=1
      shift
      ;;
    --install-tool-global-redirects)
      INSTALL_TOOL_GLOBAL_REDIRECTS=1
      shift
      ;;
    --seed-orphan-meta-snapshot)
      SEED_ORPHAN_META_SNAPSHOT=1
      shift
      ;;
    --myappz-root)
      MYAPPZ_ROOT="${2:-}"
      shift 2
      ;;
    --template-root)
      TEMPLATE_ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --no-global-writes)
      NO_GLOBAL_WRITES=1
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
  usage
  exit 1
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(basename -- "${TARGET_REPO}")"
fi

if [[ -n "${TEMPLATE_ROOT_OVERRIDE}" ]]; then
  TEMPLATE_ROOT="$(cd -- "${TEMPLATE_ROOT_OVERRIDE}" && pwd)"
fi

if [[ ${DRY_RUN} -eq 0 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

aiaast_assert_template_root "${TEMPLATE_ROOT}"

mkdir -p "${TARGET_REPO}"

if [[ -e "${TARGET_REPO}/README.md" ]]; then
  README_DEST="AI_SYSTEM_README.md"
fi

mapfile -t SOURCE_FILES < <(cd "${TEMPLATE_ROOT}" && find . -type f | sort)
CONFLICTS=()

for rel in "${SOURCE_FILES[@]}"; do
  rel="${rel#./}"
  if [[ "${rel}" == "README.md" ]]; then
    dest="${TARGET_REPO}/${README_DEST}"
  else
    dest="${TARGET_REPO}/${rel}"
  fi
  if [[ -e "${dest}" ]]; then
    CONFLICTS+=("${dest}")
  fi
done

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo "Refusing to overwrite existing files:" >&2
  printf '  %s\n' "${CONFLICTS[@]}" >&2
  exit 1
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "Dry run: would copy operating system into ${TARGET_REPO}"
  echo "Dry run: would configure app name as ${APP_NAME}"
  echo "Dry run: would install AIAST version $(aiaast_template_version "${TEMPLATE_ROOT}")"
  if [[ "${README_DEST}" != "README.md" ]]; then
    echo "Dry run: would install template README as ${README_DEST}"
  fi
  echo "Dry run: would run alignment checks and emit session environment report"
  if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_ROOT_SHIMS} -eq 1 ]]; then
    echo "Dry run: would install root redirect shims under ${MYAPPZ_ROOT}"
  fi
  if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_TOOL_GLOBAL_REDIRECTS} -eq 1 ]]; then
    echo "Dry run: would install tool-global redirect notices"
  fi
  if [[ ${SEED_ORPHAN_META_SNAPSHOT} -eq 1 ]]; then
    echo "Dry run: would seed orphan snapshot lane metadata"
  fi
  exit 0
fi

if [[ "${README_DEST}" == "README.md" ]]; then
  rsync -a "${TEMPLATE_ROOT}/" "${TARGET_REPO}/"
else
  rsync -a --exclude '/README.md' "${TEMPLATE_ROOT}/" "${TARGET_REPO}/"
  cp -p "${TEMPLATE_ROOT}/README.md" "${TARGET_REPO}/${README_DEST}"
  echo "Installed template README as ${README_DEST} to avoid clobbering the app README"
fi
aiaast_refresh_onboarding_baseline "${TARGET_REPO}/bootstrap" "${TARGET_REPO}" "${APP_NAME}"
aiaast_write_install_metadata \
  "${TARGET_REPO}" \
  "$(cd -- "${TEMPLATE_ROOT}" && pwd)" \
  "$(aiaast_template_version "${TEMPLATE_ROOT}")" \
  "copied-template" \
  "${README_DEST}" \
  "install"
bash "${TARGET_REPO}/bootstrap/generate-host-adapters.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-system-key.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-system-registry.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-operating-profile.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/verify-integrity.sh" --generate --target "${TARGET_REPO}"
expected_repo_target="$(basename -- "${TARGET_REPO}")"
bash "${TARGET_REPO}/bootstrap/check-working-directory-alignment.sh" "${TARGET_REPO}" --expected-target "${expected_repo_target}"
bash "${TARGET_REPO}/bootstrap/check-project-target-consistency.sh" "${TARGET_REPO}" --expected-target "${expected_repo_target}" || {
  echo "Project target consistency failed; refusing to continue writes." >&2
  exit 1
}
bash "${TARGET_REPO}/bootstrap/emit-session-environment.sh" "${TARGET_REPO}"
if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_ROOT_SHIMS} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/install-root-redirect-shims.sh" --myappz-root "${MYAPPZ_ROOT}" --target-repo "${TARGET_REPO}"
fi
if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_TOOL_GLOBAL_REDIRECTS} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/install-tool-global-redirects.sh" --target-repo "${TARGET_REPO}"
fi
if [[ ${SEED_ORPHAN_META_SNAPSHOT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/snapshot-meta-to-orphan-branch.sh" "${TARGET_REPO}" --dry-run
fi
if [[ ${STRICT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO} --strict"
else
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}"
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO}"
fi

aiaast_emit_template_sync_notice "${TARGET_REPO}" "init-project" 0

aiaast_record_validation_success \
  "${TARGET_REPO}" \
  "${validation_command}" \
  "AIAST install integrity, required files, config syntax, and awareness validation"

echo "Initialized AIAST $(aiaast_template_version "${TEMPLATE_ROOT}") in ${TARGET_REPO}"
