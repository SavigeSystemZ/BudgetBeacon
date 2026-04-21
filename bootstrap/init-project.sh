#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: init-project.sh <target-repo> [--app-name NAME] [--strict] [--dry-run]
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
if [[ ${STRICT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO} --strict"
else
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}"
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO}"
fi

aiaast_record_validation_success \
  "${TARGET_REPO}" \
  "${validation_command}" \
  "AIAST install integrity, required files, config syntax, and awareness validation"

echo "Initialized AIAST $(aiaast_template_version "${TEMPLATE_ROOT}") in ${TARGET_REPO}"
