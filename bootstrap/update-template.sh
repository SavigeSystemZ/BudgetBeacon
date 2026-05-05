#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: update-template.sh <target-repo> [--source <template-root>] [--strict] [--dry-run] [--refresh-managed]

Apply additive AIAST updates and optionally refresh drifted template-managed files.

Preserve-first: stateful repo-owned paths (for example TODO.md, PLAN.md,
PRODUCT_BRIEF.md, WHERE_LEFT_OFF.md, _system/context/*.md) are excluded from
template diff refresh, but --refresh-managed still copies any other drifted
template-managed file from the source template. Commit or snapshot the repo
before using --refresh-managed on important branches.
EOF
}

TARGET_REPO=""
SOURCE="${DEFAULT_TEMPLATE_ROOT}"
STRICT=0
DRY_RUN=0
REFRESH_MANAGED=0

AIAST_UPDATE_ORIGINAL_ARGS=("$@")

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

RESOLVED_TEMPLATE="$(cd -- "${SOURCE}" && pwd)"
aiaast_assert_template_root "${RESOLVED_TEMPLATE}"
RESOLVED_TARGET="$(cd -- "${TARGET_REPO}" && pwd)"

if [[ "${RESOLVED_TEMPLATE}" == "${RESOLVED_TARGET}" ]]; then
  echo "Source and target resolve to the same directory: ${RESOLVED_TEMPLATE}" >&2
  echo "Use --source <template-root> when updating an installed repo from the canonical AIAST template root." >&2
  exit 1
fi

# Self-refresh guard: if the installed copy of this script drifts from the
# source template, re-exec from a tempfile copy of the source version before
# touching any managed files. Bash reads scripts as a buffered stream, so
# rewriting the running script in place mid-execution corrupts the parser
# (classic symptom: "unexpected EOF while looking for matching quote" past
# the original line count). Re-execing from a stable tempfile avoids that.
if [[ "${AIAST_UPDATE_REEXEC:-0}" != "1" && ${DRY_RUN} -eq 0 && ${REFRESH_MANAGED} -eq 1 ]]; then
  source_self="${RESOLVED_TEMPLATE}/bootstrap/update-template.sh"
  running_self="${BASH_SOURCE[0]}"
  if [[ -f "${source_self}" && -f "${running_self}" ]]; then
    if ! diff -q "${source_self}" "${running_self}" >/dev/null 2>&1; then
      reexec_tmp="$(mktemp --suffix=.sh 2>/dev/null || mktemp -t aiaast-update.XXXXXX.sh)"
      cp -p "${source_self}" "${reexec_tmp}"
      chmod +x "${reexec_tmp}" 2>/dev/null || true
      export AIAST_UPDATE_REEXEC=1
      export AIAST_UPDATE_REEXEC_TMP="${reexec_tmp}"
      echo "AIAST update: re-executing from stable copy of source update-template.sh at ${reexec_tmp}"
      if [[ ${#AIAST_UPDATE_ORIGINAL_ARGS[@]} -gt 0 ]]; then
        exec bash "${reexec_tmp}" "${AIAST_UPDATE_ORIGINAL_ARGS[@]}"
      else
        exec bash "${reexec_tmp}"
      fi
    fi
  fi
fi

if [[ -n "${AIAST_UPDATE_REEXEC_TMP:-}" ]]; then
  trap 'rm -f "${AIAST_UPDATE_REEXEC_TMP}"' EXIT
fi

source_version="$(aiaast_template_version "${RESOLVED_TEMPLATE}")"
installed_version="$(aiaast_template_version "${RESOLVED_TARGET}")"
readme_dest="$(aiaast_detect_system_readme_path "${RESOLVED_TARGET}")"
bash "${RESOLVED_TARGET}/bootstrap/check-working-directory-alignment.sh" "${RESOLVED_TARGET}"
bash "${RESOLVED_TARGET}/bootstrap/check-project-target-consistency.sh" "${RESOLVED_TARGET}"
bash "${RESOLVED_TARGET}/bootstrap/emit-session-environment.sh" "${RESOLVED_TARGET}"
always_refresh_files=(
  "AIAST_VERSION.md"
  "AIAST_CHANGELOG.md"
  "bootstrap/generate-system-key.sh"
  "bootstrap/generate-host-adapters.sh"
  "_system/.template-version"
  "_system/aiaast-capabilities.json"
  "_system/instruction-precedence.json"
  "_system/host-adapter-manifest.json"
)

mapfile -t source_files < <(aiaast_list_files "${RESOLVED_TEMPLATE}")
missing_files=()
drifted_files=()

for rel in "${source_files[@]}"; do
  rel="${rel#./}"
  dest_rel="${rel}"
  if [[ "${rel}" == "README.md" ]]; then
    dest_rel="${readme_dest}"
  fi

  if [[ ! -e "${RESOLVED_TARGET}/${dest_rel}" ]]; then
    missing_files+=("${dest_rel}")
    continue
  fi

  if [[ "${rel}" == "README.md" ]]; then
    if ! diff -q "${RESOLVED_TEMPLATE}/README.md" "${RESOLVED_TARGET}/${dest_rel}" >/dev/null 2>&1; then
      drifted_files+=("${dest_rel}")
    fi
    continue
  fi

  if aiaast_is_template_diff_skip_path "${dest_rel}"; then
    continue
  fi

  if ! diff -q "${RESOLVED_TEMPLATE}/${rel}" "${RESOLVED_TARGET}/${dest_rel}" >/dev/null 2>&1; then
    drifted_files+=("${dest_rel}")
  fi
done

echo "AIAST Update Report"
echo "==================="
echo ""
echo "Target:            ${RESOLVED_TARGET}"
echo "Template source:   ${RESOLVED_TEMPLATE}"
echo "Installed version: ${installed_version}"
echo "Source version:    ${source_version}"
echo "System README:     ${readme_dest}"
echo ""

if [[ ${#missing_files[@]} -eq 0 ]]; then
  echo "Missing files: none"
else
  echo "Missing files (${#missing_files[@]}):"
  printf '  - %s\n' "${missing_files[@]}"
fi
echo ""

if [[ ${#drifted_files[@]} -eq 0 ]]; then
  echo "Drifted template-managed files: none"
else
  echo "Drifted template-managed files (${#drifted_files[@]}):"
  printf '  - %s\n' "${drifted_files[@]}"
  if [[ ${REFRESH_MANAGED} -eq 0 ]]; then
    echo ""
    echo "These will be left untouched unless you pass --refresh-managed."
  fi
fi
echo ""

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "Dry run only. No files were changed."
  exit 0
fi

for rel in "${source_files[@]}"; do
  rel="${rel#./}"
  dest_rel="${rel}"
  if [[ "${rel}" == "README.md" ]]; then
    dest_rel="${readme_dest}"
  fi

  if [[ ! -e "${RESOLVED_TARGET}/${dest_rel}" ]]; then
    aiaast_copy_rel_file "${RESOLVED_TEMPLATE}" "${rel}" "${RESOLVED_TARGET}" "${dest_rel}"
    continue
  fi

  if [[ ${REFRESH_MANAGED} -eq 0 ]]; then
    continue
  fi

  if [[ "${rel}" == "README.md" ]]; then
    cp -p "${RESOLVED_TEMPLATE}/README.md" "${RESOLVED_TARGET}/${dest_rel}"
    continue
  fi

  if aiaast_is_template_diff_skip_path "${dest_rel}"; then
    continue
  fi

  if ! diff -q "${RESOLVED_TEMPLATE}/${rel}" "${RESOLVED_TARGET}/${dest_rel}" >/dev/null 2>&1; then
    aiaast_copy_rel_file "${RESOLVED_TEMPLATE}" "${rel}" "${RESOLVED_TARGET}" "${dest_rel}"
  fi
done

for rel in "${always_refresh_files[@]}"; do
  if [[ -f "${RESOLVED_TEMPLATE}/${rel}" ]]; then
    aiaast_copy_rel_file "${RESOLVED_TEMPLATE}" "${rel}" "${RESOLVED_TARGET}" "${rel}"
  fi
done

for rel in "${source_files[@]}"; do
  rel="${rel#./}"
  dest_rel="${rel}"
  if [[ "${rel}" == "README.md" ]]; then
    dest_rel="${readme_dest}"
  fi

  if [[ ! -e "${RESOLVED_TARGET}/${dest_rel}" ]]; then
    continue
  fi

  if [[ "${rel}" != "README.md" ]] && aiaast_is_template_diff_skip_path "${dest_rel}"; then
    continue
  fi

  aiaast_sync_rel_file_mode "${RESOLVED_TEMPLATE}" "${rel}" "${RESOLVED_TARGET}" "${dest_rel}"
done

aiaast_refresh_onboarding_baseline "${RESOLVED_TARGET}/bootstrap" "${RESOLVED_TARGET}" "" "${REFRESH_MANAGED}"

aiaast_write_install_metadata \
  "${RESOLVED_TARGET}" \
  "${RESOLVED_TEMPLATE}" \
  "${source_version}" \
  "copied-template" \
  "${readme_dest}" \
  "update-template"

# Manifest and onboarding hooks may refresh immediately before adapter emission.
# Always re-pin the emitter script to the source template version so renderer
# tables stay aligned with `generated_adapters` kinds (avoids skew on large jumps).
if [[ -f "${RESOLVED_TEMPLATE}/bootstrap/generate-host-adapters.sh" ]]; then
  aiaast_copy_rel_file "${RESOLVED_TEMPLATE}" "bootstrap/generate-host-adapters.sh" "${RESOLVED_TARGET}" "bootstrap/generate-host-adapters.sh"
fi
bash "${RESOLVED_TARGET}/bootstrap/generate-host-adapters.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-system-key.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-system-registry.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/generate-operating-profile.sh" "${RESOLVED_TARGET}" --write
bash "${RESOLVED_TARGET}/bootstrap/verify-integrity.sh" --generate --target "${RESOLVED_TARGET}"

if [[ ${STRICT} -eq 1 ]]; then
  bash "${RESOLVED_TEMPLATE}/bootstrap/validate-system.sh" "${RESOLVED_TARGET}" --strict --mode installed --validator-root "${RESOLVED_TEMPLATE}"
  validation_command="bootstrap/update-template.sh ${RESOLVED_TARGET} --source <template-root> --strict"
else
  bash "${RESOLVED_TARGET}/bootstrap/validate-system.sh" "${RESOLVED_TARGET}"
  validation_command="bootstrap/update-template.sh ${RESOLVED_TARGET} --source <template-root>"

  set +e
  canonical_validation_output="$(
    bash "${RESOLVED_TEMPLATE}/bootstrap/validate-instruction-layer.sh" "${RESOLVED_TARGET}" --validator-root "${RESOLVED_TEMPLATE}" 2>&1
  )"
  canonical_validation_status=$?
  set -e

  if [[ ${canonical_validation_status} -ne 0 ]]; then
    echo ""
    echo "Post-update notice: canonical instruction-layer validation still fails against preserved installed surfaces."
    printf '%s\n' "${canonical_validation_output}"
    if [[ ${REFRESH_MANAGED} -eq 0 ]]; then
      echo ""
      echo "The update was additive only. Drifted template-managed files were preserved."
      echo "Review the reported surfaces, then re-run with --refresh-managed or repair the repo-local instruction layer manually."
    fi
  fi
fi

aiaast_emit_template_sync_notice "${RESOLVED_TARGET}" "update-template" "${REFRESH_MANAGED}"

aiaast_record_validation_success \
  "${RESOLVED_TARGET}" \
  "${validation_command}" \
  "AIAST update integrity, required files, config syntax, and awareness validation"

echo "AIAST update complete."
