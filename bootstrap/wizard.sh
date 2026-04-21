#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: wizard.sh <target-repo> [--non-interactive] [--dry-run]

Interactive AIAST setup wizard. Guides you through:
  1. Detect or ask for app name
  2. Detect or ask for tech stack
  3. Install the AIAST system
  4. Configure the project profile
  5. Recommend and apply a starter blueprint
  6. Run validation

Options:
  --non-interactive   Accept all defaults without prompting
  --dry-run           Show what would happen without making changes
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
NON_INTERACTIVE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
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

if [[ -z "${TARGET_REPO}" ]]; then
  echo "Target repo path is required." >&2
  exit 1
fi

if [[ ${DRY_RUN} -eq 0 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

TARGET_REPO="$(cd -- "${TARGET_REPO}" 2>/dev/null && pwd || echo "${TARGET_REPO}")"

# --- Helpers ---

BOLD="\033[1m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
RESET="\033[0m"

# Suppress ANSI when piped
if [[ ! -t 1 ]]; then
  BOLD="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

section() {
  printf "\n${BOLD}${CYAN}=== %s ===${RESET}\n\n" "$1"
}

step() {
  printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

info() {
  printf "  ${YELLOW}→${RESET} %s\n" "$1"
}

ask() {
  local prompt="$1"
  local default="$2"
  local varname="$3"

  if [[ ${NON_INTERACTIVE} -eq 1 ]]; then
    eval "${varname}=\"${default}\""
    return
  fi

  printf "  %s [%s]: " "${prompt}" "${default}"
  read -r response
  if [[ -z "${response}" ]]; then
    eval "${varname}=\"${default}\""
  else
    eval "${varname}=\"${response}\""
  fi
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

# --- Detect template source ---

TEMPLATE_ROOT=""
if [[ -f "${SCRIPT_DIR}/../.installable-product-root" ]]; then
  TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
elif [[ -f "${SCRIPT_DIR}/../../TEMPLATE/.installable-product-root" ]]; then
  TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/../../TEMPLATE" && pwd)"
fi

if [[ -z "${TEMPLATE_ROOT}" ]]; then
  echo "Cannot locate AIAST template root from script location." >&2
  exit 1
fi

# --- Step 1: App name ---

section "Step 1: App Name"

DETECTED_NAME="$(basename "${TARGET_REPO}")"

# Check if already installed
if [[ -f "${TARGET_REPO}/_system/PROJECT_PROFILE.md" ]]; then
  EXISTING_NAME="$(grep -oP '(?<=^- App name: ).+' "${TARGET_REPO}/_system/PROJECT_PROFILE.md" 2>/dev/null || true)"
  if [[ -n "${EXISTING_NAME}" ]]; then
    DETECTED_NAME="${EXISTING_NAME}"
    info "Existing profile detected: ${DETECTED_NAME}"
  fi
fi

ask "App name" "${DETECTED_NAME}" APP_NAME
step "App name: ${APP_NAME}"

# --- Step 2: Detect stack ---

section "Step 2: Tech Stack Detection"

DETECTED_STACK=""
if [[ -f "${TARGET_REPO}/package.json" ]]; then
  DETECTED_STACK="Node.js"
  if grep -q '"react"' "${TARGET_REPO}/package.json" 2>/dev/null; then
    DETECTED_STACK="React"
  fi
  if grep -q '"next"' "${TARGET_REPO}/package.json" 2>/dev/null; then
    DETECTED_STACK="Next.js"
  fi
  if grep -q '"vue"' "${TARGET_REPO}/package.json" 2>/dev/null; then
    DETECTED_STACK="Vue.js"
  fi
fi
if [[ -f "${TARGET_REPO}/pyproject.toml" || -f "${TARGET_REPO}/requirements.txt" ]]; then
  if [[ -n "${DETECTED_STACK}" ]]; then
    DETECTED_STACK="${DETECTED_STACK} + Python"
  else
    DETECTED_STACK="Python"
    if grep -q "fastapi" "${TARGET_REPO}/pyproject.toml" "${TARGET_REPO}/requirements.txt" 2>/dev/null; then
      DETECTED_STACK="FastAPI"
    fi
    if grep -q "django" "${TARGET_REPO}/pyproject.toml" "${TARGET_REPO}/requirements.txt" 2>/dev/null; then
      DETECTED_STACK="Django"
    fi
    if grep -q "flask" "${TARGET_REPO}/pyproject.toml" "${TARGET_REPO}/requirements.txt" 2>/dev/null; then
      DETECTED_STACK="Flask"
    fi
  fi
fi
if [[ -f "${TARGET_REPO}/go.mod" ]]; then
  DETECTED_STACK="${DETECTED_STACK:+${DETECTED_STACK} + }Go"
fi
if [[ -f "${TARGET_REPO}/Cargo.toml" ]]; then
  DETECTED_STACK="${DETECTED_STACK:+${DETECTED_STACK} + }Rust"
fi
if [[ -f "${TARGET_REPO}/pubspec.yaml" ]]; then
  DETECTED_STACK="${DETECTED_STACK:+${DETECTED_STACK} + }Flutter"
fi
if [[ -z "${DETECTED_STACK}" ]]; then
  DETECTED_STACK="Unknown"
fi

info "Detected stack: ${DETECTED_STACK}"
step "Stack detection complete"

# --- Step 3: Install ---

section "Step 3: AIAST Installation"

ALREADY_INSTALLED=0
if [[ -f "${TARGET_REPO}/AGENTS.md" && -d "${TARGET_REPO}/_system" ]]; then
  ALREADY_INSTALLED=1
  info "AIAST is already installed in this repo."
  if ! confirm "Reinstall / update?"; then
    step "Skipping installation"
  else
    ALREADY_INSTALLED=0
  fi
fi

if [[ ${ALREADY_INSTALLED} -eq 0 ]]; then
  if [[ ${DRY_RUN} -eq 1 ]]; then
    info "[dry-run] Would run: init-project.sh ${TARGET_REPO} --app-name \"${APP_NAME}\""
    step "Installation skipped (dry-run)"
  else
    info "Installing AIAST..."
    bash "${TEMPLATE_ROOT}/bootstrap/init-project.sh" "${TARGET_REPO}" --app-name "${APP_NAME}"
    step "AIAST installed"
  fi
fi

# --- Step 4: Profile configuration ---

section "Step 4: Project Profile"

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "[dry-run] Would run: suggest-project-profile.sh ${TARGET_REPO} --write"
  step "Profile suggestion skipped (dry-run)"
else
  info "Running profile suggestion..."
  bash "${TARGET_REPO}/bootstrap/suggest-project-profile.sh" "${TARGET_REPO}" --write 2>/dev/null || true
  step "Profile configured"
fi

# --- Step 5: Blueprint ---

section "Step 5: Starter Blueprint"

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "[dry-run] Would run: recommend-starter-blueprint.sh ${TARGET_REPO} --write"
  step "Blueprint recommendation skipped (dry-run)"
else
  info "Getting blueprint recommendation..."
  bash "${TARGET_REPO}/bootstrap/recommend-starter-blueprint.sh" "${TARGET_REPO}" --write 2>/dev/null || true

  if [[ -f "${TARGET_REPO}/_system/BLUEPRINT_RECOMMENDATION.md" ]]; then
    RECOMMENDED="$(grep -oP '(?<=^- Recommended blueprint: ).+' "${TARGET_REPO}/_system/BLUEPRINT_RECOMMENDATION.md" 2>/dev/null || echo "none")"
    if [[ "${RECOMMENDED}" != "none" && -n "${RECOMMENDED}" ]]; then
      info "Recommended blueprint: ${RECOMMENDED}"
      if confirm "Apply this blueprint?"; then
        bash "${TARGET_REPO}/bootstrap/apply-starter-blueprint.sh" "${TARGET_REPO}" --blueprint "${RECOMMENDED}" 2>/dev/null || true
        step "Blueprint applied: ${RECOMMENDED}"
      else
        step "Blueprint skipped"
      fi
    else
      step "No blueprint recommendation available"
    fi
  else
    step "No blueprint recommendation available"
  fi
fi

# --- Step 6: Validation ---

section "Step 6: Validation"

if [[ ${DRY_RUN} -eq 1 ]]; then
  info "[dry-run] Would run: validate-system.sh ${TARGET_REPO} --strict"
  step "Validation skipped (dry-run)"
else
  info "Running system validation..."
  if bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict 2>/dev/null; then
    step "Validation passed"
  else
    info "Validation reported issues. Run bootstrap/system-doctor.sh for details."
  fi
fi

# --- Summary ---

section "Setup Complete"

printf "  App name:        %s\n" "${APP_NAME}"
printf "  Stack:           %s\n" "${DETECTED_STACK}"
printf "  Target:          %s\n" "${TARGET_REPO}"
echo ""
info "Next steps:"
printf "    1. Review and fill _system/PROJECT_PROFILE.md\n"
printf "    2. Open the repo in your preferred AI tool\n"
printf "    3. See _system/QUICKSTART.md for more guidance\n"
echo ""
