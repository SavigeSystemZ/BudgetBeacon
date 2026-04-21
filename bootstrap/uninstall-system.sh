#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: uninstall-system.sh [target-repo] [--source <template-root>] [--backup-state] [--leave-tombstone] [--dry-run]

Remove the AIAST operating layer while leaving application runtime code intact.
EOF
}

TARGET_REPO=""
SOURCE="${LOCAL_REPO_ROOT}"
BACKUP_STATE=0
LEAVE_TOMBSTONE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --backup-state)
      BACKUP_STATE=1
      shift
      ;;
    --leave-tombstone)
      LEAVE_TOMBSTONE=1
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

RESOLVED_TARGET="$(cd -- "${TARGET_REPO}" && pwd)"
RESOLVED_SOURCE="$(cd -- "${SOURCE}" && pwd)"
aiaast_assert_template_root "${RESOLVED_SOURCE}"
README_PATH="$(aiaast_detect_system_readme_path "${RESOLVED_TARGET}")"

mapfile -t source_files < <(aiaast_list_files "${RESOLVED_SOURCE}")
remove_files=()
backup_files=()

for rel in "${source_files[@]}"; do
  rel="${rel#./}"
  dest_rel="${rel}"
  if [[ "${rel}" == "README.md" ]]; then
    dest_rel="${README_PATH}"
  fi
  [[ -e "${RESOLVED_TARGET}/${dest_rel}" ]] && remove_files+=("${dest_rel}")
done

stateful_backup_candidates=(
  "TODO.md"
  "FIXME.md"
  "WHERE_LEFT_OFF.md"
  "PLAN.md"
  "PRODUCT_BRIEF.md"
  "ROADMAP.md"
  "DESIGN_NOTES.md"
  "ARCHITECTURE_NOTES.md"
  "RESEARCH_NOTES.md"
  "TEST_STRATEGY.md"
  "RISK_REGISTER.md"
  "RELEASE_NOTES.md"
  "CHANGELOG.md"
  "_system/PROJECT_PROFILE.md"
  "_system/context/CURRENT_STATUS.md"
  "_system/context/DECISIONS.md"
  "_system/context/MEMORY.md"
  "_system/context/ARCHITECTURAL_INVARIANTS.md"
  "_system/context/ASSUMPTIONS.md"
  "_system/context/INTEGRATION_SURFACES.md"
  "_system/context/OPEN_QUESTIONS.md"
  "_system/context/QUALITY_DEBT.md"
  ".cursor/mcp.json"
)

for rel in "${stateful_backup_candidates[@]}"; do
  [[ -e "${RESOLVED_TARGET}/${rel}" ]] && backup_files+=("${rel}")
done

echo "AIAST Uninstall Plan"
echo "===================="
echo ""
echo "Target: ${RESOLVED_TARGET}"
echo "Source: ${RESOLVED_SOURCE}"
echo ""
echo "Files to remove: ${#remove_files[@]}"
echo "Backup state:    $([[ ${BACKUP_STATE} -eq 1 ]] && echo yes || echo no)"
echo "Tombstone:       $([[ ${LEAVE_TOMBSTONE} -eq 1 ]] && echo yes || echo no)"

if [[ ${DRY_RUN} -eq 1 ]]; then
  printf '  - %s\n' "${remove_files[@]}"
  exit 0
fi

if [[ ${BACKUP_STATE} -eq 1 && ${#backup_files[@]} -gt 0 ]]; then
  timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
  backup_root="${RESOLVED_TARGET}/.aiaast_backups/uninstall_${timestamp}"
  for rel in "${backup_files[@]}"; do
    mkdir -p "$(dirname "${backup_root}/${rel}")"
    cp -p "${RESOLVED_TARGET}/${rel}" "${backup_root}/${rel}"
  done
  echo "Backed up app-owned AIAST state to ${backup_root}"
fi

for rel in "${remove_files[@]}"; do
  rm -f "${RESOLVED_TARGET}/${rel}"
done

for dir in \
  "${RESOLVED_TARGET}/bootstrap/lib" \
  "${RESOLVED_TARGET}/_system/plugins" \
  "${RESOLVED_TARGET}/_system/systemd" \
  "${RESOLVED_TARGET}/_system/ci" \
  "${RESOLVED_TARGET}/_system/packaging"; do
  [[ -d "${dir}" ]] && rmdir --ignore-fail-on-non-empty -p "${dir}" 2>/dev/null || true
done

if [[ ${LEAVE_TOMBSTONE} -eq 1 ]]; then
  cat > "${RESOLVED_TARGET}/AIAST_REMOVED.md" <<EOF
# AIAST Removed

- Removed at: $(date -u +%Y-%m-%dT%H:%M:%SZ)
- Removed by: bootstrap/uninstall-system.sh
- Previous system README path: ${README_PATH}
EOF
fi

echo "AIAST uninstall complete."
