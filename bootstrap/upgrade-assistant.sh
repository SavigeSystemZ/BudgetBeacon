#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: upgrade-assistant.sh <target-repo> --source <template-root> [--non-interactive] [--dry-run]

Interactive upgrade assistant for AIAST. Wraps update-template.sh with guidance:
  1. Show current vs available version
  2. Preview file changes (additions, updates, removals)
  3. Warn about breaking changes
  4. Confirm or abort before applying
  5. Run post-upgrade validation

Options:
  --source <path>       Path to the canonical AIAST template root
  --non-interactive     Accept all defaults without prompting
  --dry-run             Show what would happen without making changes
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
SOURCE_TEMPLATE=""
NON_INTERACTIVE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_TEMPLATE="${2:-}"
      shift 2
      ;;
    --non-interactive)
      NON_INTERACTIVE=1
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

if [[ -z "${TARGET_REPO}" || ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ -z "${SOURCE_TEMPLATE}" ]]; then
  echo "--source <template-root> is required." >&2
  exit 1
fi

if [[ ! -d "${SOURCE_TEMPLATE}" ]]; then
  echo "Source template does not exist: ${SOURCE_TEMPLATE}" >&2
  exit 1
fi

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"
SOURCE_TEMPLATE="$(cd -- "${SOURCE_TEMPLATE}" && pwd)"

# --- Helpers ---

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
RESET="\033[0m"

if [[ ! -t 1 ]]; then
  BOLD="" GREEN="" YELLOW="" RED="" CYAN="" RESET=""
fi

section() {
  printf "\n${BOLD}${CYAN}=== %s ===${RESET}\n\n" "$1"
}

info() {
  printf "  ${YELLOW}→${RESET} %s\n" "$1"
}

warn() {
  printf "  ${RED}!${RESET} %s\n" "$1"
}

ok() {
  printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

confirm() {
  local prompt="$1"
  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
    return 0
  fi
  printf "  %s [Y/n]: " "${prompt}"
  read -r response
  case "${response}" in
    [Nn]*)
      return 1
      ;;
  esac
  return 0
}

# --- Step 1: Version comparison ---

section "Step 1: Version Check"

CURRENT_VERSION="$(aiaast_template_version "${TARGET_REPO}")"
SOURCE_VERSION="$(aiaast_template_version "${SOURCE_TEMPLATE}")"

printf "  Current version:   %s\n" "${CURRENT_VERSION}"
printf "  Available version: %s\n" "${SOURCE_VERSION}"

if [[ "${CURRENT_VERSION}" == "${SOURCE_VERSION}" ]]; then
  info "Versions match — you are up to date."
  if ! confirm "Continue anyway?"; then
    echo "Upgrade aborted."
    exit 0
  fi
fi

# --- Step 2: Preview changes ---

section "Step 2: Change Preview"

info "Running dry-run to preview changes..."

DRY_OUTPUT="$(bash "${TARGET_REPO}/bootstrap/update-template.sh" "${TARGET_REPO}" --source "${SOURCE_TEMPLATE}" --dry-run 2>&1 || true)"

if [[ -z "${DRY_OUTPUT}" ]]; then
  info "No output from dry-run — the update script may need the source to differ."
else
  echo "${DRY_OUTPUT}" | head -60
  LINE_COUNT="$(echo "${DRY_OUTPUT}" | wc -l)"
  if [[ ${LINE_COUNT} -gt 60 ]]; then
    info "(${LINE_COUNT} total lines — showing first 60)"
  fi
fi

# --- Step 3: Breaking change warnings ---

section "Step 3: Breaking Change Check"

BREAKING=0

# Check if AIAST_CHANGELOG mentions breaking changes for versions after current
if [[ -f "${SOURCE_TEMPLATE}/AIAST_CHANGELOG.md" ]]; then
  if grep -qi "breaking" "${SOURCE_TEMPLATE}/AIAST_CHANGELOG.md"; then
    warn "The source changelog mentions breaking changes."
    warn "Review AIAST_CHANGELOG.md before proceeding."
    BREAKING=1
  fi
fi

# Check if required file count changed
CURRENT_COUNT="$(find "${TARGET_REPO}/_system" -type f 2>/dev/null | wc -l)"
SOURCE_COUNT="$(find "${SOURCE_TEMPLATE}/_system" -type f 2>/dev/null | wc -l)"
DIFF_COUNT=$((SOURCE_COUNT - CURRENT_COUNT))

if [[ ${DIFF_COUNT} -gt 0 ]]; then
  info "${DIFF_COUNT} new files will be added to _system/"
elif [[ ${DIFF_COUNT} -lt 0 ]]; then
  warn "$((DIFF_COUNT * -1)) files may be removed from _system/"
  BREAKING=1
fi

if [[ ${BREAKING} -eq 0 ]]; then
  ok "No breaking changes detected"
fi

# --- Step 4: Confirm ---

section "Step 4: Confirm Upgrade"

printf "  From: %s\n" "${CURRENT_VERSION}"
printf "  To:   %s\n" "${SOURCE_VERSION}"

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "[dry-run] Would apply upgrade. Stopping here."
  exit 0
fi

if ! confirm "Apply upgrade?"; then
  echo "Upgrade aborted."
  exit 0
fi

# --- Step 5: Apply ---

section "Step 5: Applying Upgrade"

info "Running update-template.sh..."
bash "${TARGET_REPO}/bootstrap/update-template.sh" "${TARGET_REPO}" --source "${SOURCE_TEMPLATE}" --strict
ok "Upgrade applied"

# --- Step 6: Post-upgrade validation ---

section "Step 6: Post-Upgrade Validation"

info "Running system-doctor..."
if bash "${TARGET_REPO}/bootstrap/system-doctor.sh" "${TARGET_REPO}" 2>/dev/null; then
  ok "System doctor passed"
else
  warn "System doctor reported issues — run bootstrap/system-doctor.sh for details"
fi

info "Running validation..."
if bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict 2>/dev/null; then
  ok "Validation passed"
else
  warn "Validation reported issues — check output above"
fi

# --- Summary ---

section "Upgrade Complete"

printf "  Previous version: %s\n" "${CURRENT_VERSION}"
printf "  New version:      %s\n" "${SOURCE_VERSION}"
printf "  Target:           %s\n" "${TARGET_REPO}"
echo ""
info "Next steps:"
printf "    1. Review changes with: git diff\n"
printf "    2. Test your application\n"
printf "    3. Commit when satisfied\n"
echo ""
