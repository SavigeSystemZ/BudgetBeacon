#!/usr/bin/env bash
set -euo pipefail

# install-aiast.sh
# Interactive or non-interactive AIAST installer for project-specific agents.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: install-aiast.sh [options]

Scaffold a project-specific AIAST copy from this template root. The master template
tree that contains this script stays read-only with respect to the target app repo.

Interactive mode (default): prompts for app name and target directory.

Non-interactive options:
  --app-name NAME          Application name (required for non-interactive mode)
  --target PATH            Target directory (~ allowed; relative paths use cwd)
  --yes, -y                Skip confirmation prompt

Optional:
  --blueprint ID           After install, run apply-starter-blueprint.sh with this ID
                           (see bootstrap/apply-starter-blueprint.sh --list)
  --strict                 Pass --strict to scaffold-system.sh
  --dry-run                Pass --dry-run to scaffold-system.sh (skips blueprint,
                           network check, and checkpoint write)
  --check-network-bindings Run bootstrap/check-network-bindings.sh on the target after
                           a successful non-dry-run install

Examples:
  install-aiast.sh
  install-aiast.sh --app-name MyApp --target ~/code/MyApp --yes
  install-aiast.sh --app-name Svc --target /srv/Svc --yes --blueprint FASTAPI_API \\
    --check-network-bindings --strict
EOF
}

APP_NAME=""
TARGET_DIR=""
SKIP_CONFIRM=0
BLUEPRINT=""
CHECK_NETWORK=0
SCAFFOLD_EXTRA=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --target|--target-dir)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --yes|-y)
      SKIP_CONFIRM=1
      shift
      ;;
    --blueprint)
      BLUEPRINT="${2:-}"
      shift 2
      ;;
    --check-network-bindings)
      CHECK_NETWORK=1
      shift
      ;;
    --strict)
      SCAFFOLD_EXTRA+=(--strict)
      shift
      ;;
    --dry-run)
      SCAFFOLD_EXTRA+=(--dry-run)
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

HAVE_NONINTERACTIVE=0
if [[ -n "${APP_NAME}" || -n "${TARGET_DIR}" ]]; then
  HAVE_NONINTERACTIVE=1
fi

if [[ ${HAVE_NONINTERACTIVE} -eq 1 ]]; then
  if [[ -z "${APP_NAME}" || -z "${TARGET_DIR}" ]]; then
    echo "Non-interactive mode requires both --app-name and --target." >&2
    exit 1
  fi
fi

if [[ -z "${APP_NAME}" ]]; then
  printf "Enter your Application Name (e.g., MyAwesomeApp): "
  read -r APP_NAME
fi
if [[ -z "${APP_NAME}" ]]; then
  echo "Error: Application Name is required." >&2
  exit 1
fi

if [[ -z "${TARGET_DIR}" ]]; then
  printf "Enter the Target Directory (absolute path or relative to %s): " "${HOME}"
  read -r TARGET_DIR
fi
if [[ -z "${TARGET_DIR}" ]]; then
  echo "Error: Target Directory is required." >&2
  exit 1
fi

# Resolve ~ if present
TARGET_DIR="${TARGET_DIR/#\~/${HOME}}"
# Ensure absolute path
if [[ "${TARGET_DIR}" != /* ]]; then
  TARGET_DIR="$(pwd)/${TARGET_DIR}"
fi

echo ""
echo "----------------------------------------------------------------"
echo "AIAST Installer"
echo "----------------------------------------------------------------"
echo "This tool will scaffold a project-specific AIAST copy."
echo "The master template will remain UNTOUCHED."
echo ""
echo "Configuration:"
echo "  App Name:   ${APP_NAME}"
echo "  Target Dir: ${TARGET_DIR}"
echo "  Source:     ${TEMPLATE_ROOT}"
if [[ -n "${BLUEPRINT}" ]]; then
  echo "  Blueprint:  ${BLUEPRINT} (post-install)"
fi
if [[ ${CHECK_NETWORK} -eq 1 ]]; then
  echo "  Preflight: check-network-bindings after install"
fi
echo ""

if [[ ${SKIP_CONFIRM} -eq 0 ]]; then
  printf "Proceed with installation? (y/n): "
  read -r CONFIRM
  if [[ "${CONFIRM}" != "y" ]]; then
    echo "Installation cancelled."
    exit 0
  fi
fi

DRY_RUN=0
for flag in "${SCAFFOLD_EXTRA[@]}"; do
  if [[ "${flag}" == "--dry-run" ]]; then
    DRY_RUN=1
  fi
done

echo "Installing..."
bash "${SCRIPT_DIR}/scaffold-system.sh" "${TARGET_DIR}" --app-name "${APP_NAME}" \
  --source "${TEMPLATE_ROOT}" "${SCAFFOLD_EXTRA[@]}"

if [[ ${DRY_RUN} -eq 0 && -n "${BLUEPRINT}" ]]; then
  echo "Applying starter blueprint ${BLUEPRINT}..."
  bash "${SCRIPT_DIR}/apply-starter-blueprint.sh" "${TARGET_DIR}" \
    --blueprint "${BLUEPRINT}" --app-name "${APP_NAME}"
fi

if [[ ${DRY_RUN} -eq 0 && ${CHECK_NETWORK} -eq 1 && -d "${TARGET_DIR}/bootstrap" ]]; then
  echo "Running network binding check..."
  bash "${SCRIPT_DIR}/check-network-bindings.sh" "${TARGET_DIR}" || {
    echo "Warning: check-network-bindings reported findings; review before bind exposure." >&2
  }
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "Dry run finished (no checkpoint written)."
  exit 0
fi

echo "----------------------------------------------------------------"
echo "INSTALLATION COMPLETE"
echo "----------------------------------------------------------------"
echo "AIAST has been successfully scaffolded to: ${TARGET_DIR}"
echo ""
echo "STOP WORKING IN THIS DIRECTORY."
echo "Switch your context to the target directory and resume work there."
echo ""

CHECKPOINT_DIR="${TARGET_DIR}/_system/checkpoints"
mkdir -p "${CHECKPOINT_DIR}"
cat > "${CHECKPOINT_DIR}/LATEST.md" <<EOF
# RESUME BRIEFING: SCAFFOLD HANDOFF

## Context
AIAST was scaffolded from the master template at \`${TEMPLATE_ROOT}\`.
$(
  if [[ -n "${BLUEPRINT}" ]]; then
    printf '%s\n' "" "## Blueprint" "Applied starter blueprint \`${BLUEPRINT}\` via \`bootstrap/apply-starter-blueprint.sh\`."
  fi
)

## Agent Action Required
1. **Change Directory:** \`cd ${TARGET_DIR}\`
2. **Launch Agent:** Launch a new agent session in the new directory.
3. **Verify:** Run \`bash bootstrap/system-doctor.sh\` to confirm the local environment is healthy.

## Sovereign Rule Reminder
You are now in your project-specific environment. Do NOT navigate back to the master template for direct edits. Any improvements should be made HERE first.
EOF

echo "A handoff checkpoint has been created at ${CHECKPOINT_DIR}/LATEST.md"
echo "Goodbye."
