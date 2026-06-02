#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: install-missing-files.sh <target-repo> [--source <template-root>] [--profile NAME]
                                [--strict] [--dry-run] [--skip-onboarding-seeds]

After copying missing template files, the onboarding refresh normally runs
suggest/seed scripts. Pass --skip-onboarding-seeds when you must preserve
repo-specific PRODUCT_BRIEF, working files, and _system/context (same effect as
export AIAST_SKIP_ONBOARDING_SEEDS=1 for this invocation).
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
SOURCE=""
PROFILE=""
STRICT=0
DRY_RUN=0
SKIP_ONBOARDING_SEEDS=0
README_DEST="README.md"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --skip-onboarding-seeds)
      SKIP_ONBOARDING_SEEDS=1
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

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ ${DRY_RUN} -eq 0 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

TEMPLATE_ROOT="${SOURCE:-${DEFAULT_TEMPLATE_ROOT}}"
aiaast_assert_template_root "${TEMPLATE_ROOT}"

RESOLVED_TEMPLATE="$(cd -- "${TEMPLATE_ROOT}" && pwd)"
RESOLVED_TARGET="$(cd -- "${TARGET_REPO}" && pwd)"
PROFILE="$(aiaast_resolve_scaffold_profile "${RESOLVED_TARGET}" "${PROFILE}")"

if [[ "${RESOLVED_TEMPLATE}" == "${RESOLVED_TARGET}" ]]; then
  echo "Source and target resolve to the same directory: ${RESOLVED_TEMPLATE}" >&2
  echo "Use --source <template-root> to specify the canonical AIAST template root in template-source mode." >&2
  echo "Example: install-missing-files.sh /path/to/app --source /path/to/TEMPLATE" >&2
  exit 1
fi

README_DEST="$(aiaast_detect_system_readme_path "${RESOLVED_TARGET}")"
bash "${RESOLVED_TARGET}/bootstrap/check-working-directory-alignment.sh" "${RESOLVED_TARGET}"
bash "${RESOLVED_TARGET}/bootstrap/check-project-target-consistency.sh" "${RESOLVED_TARGET}"
bash "${RESOLVED_TARGET}/bootstrap/emit-session-environment.sh" "${RESOLVED_TARGET}"

mapfile -t SOURCE_FILES < <(bash "${RESOLVED_TEMPLATE}/bootstrap/render-scaffold-profile.sh" "${RESOLVED_TEMPLATE}" --profile "${PROFILE}")
MISSING_FILES=()

for rel in "${SOURCE_FILES[@]}"; do
  rel="${rel#./}"
  if [[ "${rel}" == "README.md" ]]; then
    dest="${README_DEST}"
  else
    dest="${rel}"
  fi
  if [[ ! -e "${TARGET_REPO}/${dest}" ]]; then
    MISSING_FILES+=("${dest}")
  fi
done

if [[ ${#MISSING_FILES[@]} -eq 0 ]]; then
  echo "no_missing_files"
  exit 0
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "Dry run: would install missing files into ${TARGET_REPO}"
  echo "Dry run: scaffold profile ${PROFILE} selects ${#SOURCE_FILES[@]} files"
  if [[ ${SKIP_ONBOARDING_SEEDS} -eq 1 ]]; then
    echo "Dry run: would skip onboarding re-seeds (--skip-onboarding-seeds)"
  fi
  printf '%s\n' "${MISSING_FILES[@]}"
  exit 0
fi

for rel in "${SOURCE_FILES[@]}"; do
  dest_rel="${rel}"
  if [[ "${rel}" == "README.md" ]]; then
    dest_rel="${README_DEST}"
  fi
  if [[ -e "${TARGET_REPO}/${dest_rel}" ]]; then
    continue
  fi
  aiaast_copy_rel_file "${RESOLVED_TEMPLATE}" "${rel}" "${TARGET_REPO}" "${dest_rel}"
  if [[ "${rel}" == "README.md" && "${README_DEST}" != "README.md" ]]; then
    echo "Installed template README as ${README_DEST} to avoid clobbering the app README"
  fi
done

(
  if [[ ${SKIP_ONBOARDING_SEEDS} -eq 1 ]]; then
    export AIAST_SKIP_ONBOARDING_SEEDS=1
  fi
  aiaast_refresh_onboarding_baseline "${RESOLVED_TARGET}/bootstrap" "${RESOLVED_TARGET}"
)

aiaast_write_install_metadata \
  "${RESOLVED_TARGET}" \
  "${RESOLVED_TEMPLATE}" \
  "$(aiaast_template_version "${RESOLVED_TEMPLATE}")" \
  "copied-template" \
  "${README_DEST}" \
  "install-missing-files" \
  "${PROFILE}"
bash "${RESOLVED_TARGET}/bootstrap/generate-host-adapters.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-system-key.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-system-registry.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-operating-profile.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/verify-integrity.sh" --generate --target "${RESOLVED_TARGET}"

if [[ ${STRICT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO} --strict"
else
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}"
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO}"
fi

aiaast_emit_template_sync_notice "${RESOLVED_TARGET}" "install-missing-files" 0

aiaast_record_validation_success \
  "${RESOLVED_TARGET}" \
  "${validation_command}" \
  "AIAST additive install integrity, required files, config syntax, and awareness validation"

echo "Installed ${#MISSING_FILES[@]} missing files into ${TARGET_REPO}"
