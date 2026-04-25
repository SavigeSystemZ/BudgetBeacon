#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: migrate-agent-surface-upgrade.sh <target-repo> [--dry-run|--write]

Apply the dual-metasystem agent-surface upgrade to an existing downstream repo:
- install missing managed files (additive only; rsync --ignore-existing)
- preserve-first: while installing, passes `--skip-onboarding-seeds` to
  `install-missing-files.sh` so PRODUCT_BRIEF, working files, and _system/context
  are not bulk-rewritten (equivalent to `AIAST_SKIP_ONBOARDING_SEEDS=1`)
- patch shared contract references (append-only)
- regenerate host adapters
- validate adapter alignment and instruction layer
- emit a concise migration report
EOF
}

TARGET_REPO="${1:-}"
MODE="${2:---dry-run}"

if [[ -z "${TARGET_REPO}" ]]; then
  usage
  exit 1
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ "${MODE}" != "--dry-run" && "${MODE}" != "--write" ]]; then
  usage
  exit 1
fi

if [[ "${MODE}" == "--write" ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

run_step() {
  local label="$1"
  shift
  printf '[migrate] %s\n' "${label}"
  "$@"
}

if [[ "${MODE}" == "--write" ]]; then
  # install-missing-files triggers onboarding refresh; for migrations we only want
  # missing template files copied, not narrative re-seeding of product state.
  run_step "install-missing-files" bash "${SCRIPT_DIR}/install-missing-files.sh" "${TARGET_REPO}" --skip-onboarding-seeds
  run_step "patch-agent-surface-contracts" bash "${SCRIPT_DIR}/patch-agent-surface-contracts.sh" "${TARGET_REPO}" --write
  run_step "generate-host-adapters" bash "${SCRIPT_DIR}/generate-host-adapters.sh" "${TARGET_REPO}" --write
  run_step "generate-system-registry" bash "${SCRIPT_DIR}/generate-system-registry.sh" "${TARGET_REPO}" --write
  run_step "generate-operating-profile" bash "${SCRIPT_DIR}/generate-operating-profile.sh" "${TARGET_REPO}" --write
  run_step "verify-integrity-generate" bash "${SCRIPT_DIR}/verify-integrity.sh" --generate --target "${TARGET_REPO}"
else
  run_step "install-missing-files-dry-run" bash "${SCRIPT_DIR}/install-missing-files.sh" "${TARGET_REPO}" --dry-run --skip-onboarding-seeds
  required_contracts=(
    "_system/AGENT_SURFACE_TAXONOMY.md"
    "_system/AGENT_INIT_CONVERGENCE.md"
    "_system/OPERATOR_PROMPTING_PLAYBOOK.md"
    "bootstrap/check-agent-surface-integrity.sh"
  )
  missing_any=0
  for rel in "${required_contracts[@]}"; do
    if [[ ! -f "${TARGET_REPO}/${rel}" ]]; then
      missing_any=1
    fi
  done
  if [[ ${missing_any} -eq 1 ]]; then
    echo "agent_surface_migration_dry_run_pending_install"
    echo "Run with --write to install required contract surfaces before validation."
    exit 0
  fi
  run_step "patch-agent-surface-contracts-check" bash "${SCRIPT_DIR}/patch-agent-surface-contracts.sh" "${TARGET_REPO}" --check
fi

run_step "check-host-adapter-alignment" bash "${SCRIPT_DIR}/check-host-adapter-alignment.sh" "${TARGET_REPO}"
run_step "check-agent-surface-integrity" bash "${SCRIPT_DIR}/check-agent-surface-integrity.sh" "${TARGET_REPO}"
run_step "validate-instruction-layer" bash "${SCRIPT_DIR}/validate-instruction-layer.sh" "${TARGET_REPO}"
run_step "check-system-awareness" bash "${SCRIPT_DIR}/check-system-awareness.sh" "${TARGET_REPO}"

if command -v git >/dev/null 2>&1 && [[ -d "${TARGET_REPO}/.git" ]]; then
  printf '\n[migrate] changed-files-report\n'
  git -C "${TARGET_REPO}" status --short
fi

echo "agent_surface_migration_ok mode=${MODE/--/}"
