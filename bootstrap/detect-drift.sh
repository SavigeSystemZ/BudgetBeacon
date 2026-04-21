#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: detect-drift.sh <target-repo> [--source <template-root>] [--verbose]

Detect structural, integrity, freshness, and version drift between an installed repo and the master template.
EOF
}

TARGET_REPO=""
SOURCE=""
VERBOSE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --verbose)
      VERBOSE=1
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

TEMPLATE_ROOT="${SOURCE:-${DEFAULT_TEMPLATE_ROOT}}"
RESOLVED_TEMPLATE="$(cd -- "${TEMPLATE_ROOT}" && pwd)"
aiaast_assert_template_root "${RESOLVED_TEMPLATE}"
RESOLVED_TARGET="$(cd -- "${TARGET_REPO}" && pwd)"

if [[ "${RESOLVED_TEMPLATE}" == "${RESOLVED_TARGET}" ]]; then
  echo "Source and target resolve to the same directory: ${RESOLVED_TEMPLATE}" >&2
  echo "Point --source at the canonical AIAST template root instead of the installed repo." >&2
  exit 1
fi

readme_dest="$(aiaast_detect_system_readme_path "${RESOLVED_TARGET}")"
source_version="$(aiaast_template_version "${RESOLVED_TEMPLATE}")"
installed_version="$(aiaast_template_version "${RESOLVED_TARGET}")"

echo "Drift Report"
echo "============"
echo ""
echo "Template source:   ${RESOLVED_TEMPLATE}"
echo "Target repo:       ${RESOLVED_TARGET}"
echo "Source version:    ${source_version}"
echo "Installed version: ${installed_version}"
echo ""

mapfile -t template_files < <(aiaast_list_files "${RESOLVED_TEMPLATE}")
missing_files=()
drifted_files=()

for rel in "${template_files[@]}"; do
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

echo "## Structural drift"
echo ""
if [[ ${#missing_files[@]} -eq 0 ]]; then
  echo "No missing files."
else
  printf '  - %s\n' "${missing_files[@]}"
fi
echo ""

echo "## Content drift"
echo ""
if [[ ${#drifted_files[@]} -eq 0 ]]; then
  echo "No template-managed files differ from the source template."
else
  for rel in "${drifted_files[@]}"; do
    echo "  - ${rel}"
    if [[ ${VERBOSE} -eq 1 ]]; then
      source_rel="${rel}"
      [[ "${rel}" == "${readme_dest}" ]] && source_rel="README.md"
      echo "    ---"
      diff -u "${RESOLVED_TEMPLATE}/${source_rel}" "${RESOLVED_TARGET}/${rel}" | head -30 || true
      echo "    ---"
    fi
  done
fi
echo ""

echo "## Integrity drift"
echo ""
mapfile -t integrity_failures < <(bash "${SCRIPT_DIR}/verify-integrity.sh" --check --target "${RESOLVED_TARGET}" --list-failed 2>/dev/null || true)
if [[ ${#integrity_failures[@]} -eq 0 ]]; then
  echo "Integrity manifest matches for template-managed files."
else
  for rel in "${integrity_failures[@]}"; do
    echo "  - ${rel}"
  done
fi
echo ""

echo "## Version skew"
echo ""
if [[ "${installed_version}" == "${source_version}" ]]; then
  echo "No version skew."
else
  echo "Installed repo carries ${installed_version}; source template is ${source_version}."
fi
echo ""

echo "## Stale drift"
echo ""
status_file="${RESOLVED_TARGET}/_system/context/CURRENT_STATUS.md"
if [[ -f "${status_file}" ]]; then
  last_updated=$(grep -i "^- Last updated:" "${status_file}" 2>/dev/null | head -1 | sed 's/^- Last updated:\s*//')
  if [[ -z "${last_updated}" || "${last_updated}" == *"$"* ]]; then
    echo "CURRENT_STATUS.md has no concrete freshness timestamp."
  else
    echo "CURRENT_STATUS.md last updated: ${last_updated}"
  fi
else
  echo "CURRENT_STATUS.md not found."
fi
echo ""

echo "## Extra files in _system/"
echo ""
extra_system_files=()
if [[ -d "${RESOLVED_TARGET}/_system" ]]; then
  while IFS= read -r -d '' f; do
    rel="${f#${RESOLVED_TARGET}/}"
    if [[ ! -e "${RESOLVED_TEMPLATE}/${rel}" ]]; then
      if aiaast_is_stateful_path "${rel}" || aiaast_is_local_config_path "${rel}"; then
        continue
      fi
      extra_system_files+=("${rel}")
    fi
  done < <(find "${RESOLVED_TARGET}/_system" -type f -print0 | sort -z)
fi
if [[ ${#extra_system_files[@]} -eq 0 ]]; then
  echo "No extra _system files."
else
  printf '  - %s\n' "${extra_system_files[@]}"
fi
echo ""

total_issues=$(( ${#missing_files[@]} + ${#drifted_files[@]} + ${#integrity_failures[@]} + ${#extra_system_files[@]} ))
echo "## Summary"
echo ""
if [[ ${total_issues} -eq 0 && "${installed_version}" == "${source_version}" ]]; then
  echo "drift_ok"
else
  echo "Detected drift or skew."
  [[ ${#missing_files[@]} -gt 0 ]] && echo "  Fix missing files: bootstrap/install-missing-files.sh ${RESOLVED_TARGET} --source ${RESOLVED_TEMPLATE}"
  [[ ${#drifted_files[@]} -gt 0 ]] && echo "  Review or refresh managed files: bootstrap/update-template.sh ${RESOLVED_TARGET} --source ${RESOLVED_TEMPLATE} --refresh-managed --dry-run"
  [[ ${#integrity_failures[@]} -gt 0 ]] && echo "  Repair integrity mismatches: bootstrap/repair-system.sh ${RESOLVED_TARGET} --source ${RESOLVED_TEMPLATE} --dry-run"
  [[ "${installed_version}" != "${source_version}" ]] && echo "  Upgrade installed version: bootstrap/update-template.sh ${RESOLVED_TARGET} --source ${RESOLVED_TEMPLATE} --dry-run"
  [[ ${#extra_system_files[@]} -gt 0 ]] && echo "  Review extra system files before cleanup or plugin registration."
fi
