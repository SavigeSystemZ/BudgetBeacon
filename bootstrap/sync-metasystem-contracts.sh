#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

TARGET_REPO="${1:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"
MODE="${2:---write}"

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ "${MODE}" != "--write" && "${MODE}" != "--check" ]]; then
  echo "Usage: sync-metasystem-contracts.sh [target-repo] [--write|--check]" >&2
  exit 1
fi

if [[ "${MODE}" == "--write" ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

run_step() {
  local label="$1"
  shift
  printf '[sync] %s\n' "${label}"
  "$@"
}

if [[ "${MODE}" == "--write" ]]; then
  run_step "generate-host-adapters" bash "${SCRIPT_DIR}/generate-host-adapters.sh" "${TARGET_REPO}" --write
  run_step "generate-system-registry" bash "${SCRIPT_DIR}/generate-system-registry.sh" "${TARGET_REPO}" --write
  run_step "generate-operating-profile" bash "${SCRIPT_DIR}/generate-operating-profile.sh" "${TARGET_REPO}" --write
  run_step "verify-integrity-generate" bash "${SCRIPT_DIR}/verify-integrity.sh" --generate --target "${TARGET_REPO}"
fi

run_step "check-host-adapter-alignment" bash "${SCRIPT_DIR}/check-host-adapter-alignment.sh" "${TARGET_REPO}"
run_step "check-agent-surface-integrity" bash "${SCRIPT_DIR}/check-agent-surface-integrity.sh" "${TARGET_REPO}"
run_step "validate-instruction-layer" bash "${SCRIPT_DIR}/validate-instruction-layer.sh" "${TARGET_REPO}"
run_step "check-system-awareness" bash "${SCRIPT_DIR}/check-system-awareness.sh" "${TARGET_REPO}"

echo "metasystem_contract_sync_ok mode=${MODE/--/}"
