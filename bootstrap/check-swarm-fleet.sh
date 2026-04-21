#!/usr/bin/env bash
# AIAST Swarm Fleet: Health & Integrity Check
# Verifies that all agent hooks, anti-drift rules, and swarm tools are present and aligned.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

TARGET_REPO="${1:-$(pwd)}"

log_info() { echo "✅ [SWARM CHECK] $1"; }
log_fail() { echo "❌ [SWARM FAIL] $1"; exit 1; }
log_warn() { echo "⚠️ [SWARM WARN] $1"; }

REPO_MODE="$(aiaast_detect_repo_mode "${TARGET_REPO}")"

check_file() {
    local rel="$1"
    if [[ "${REPO_MODE}" == "template" ]]; then
        if [[ ! -f "${TARGET_REPO}/${rel}" ]]; then
            log_fail "Missing critical swarm file: ${rel}"
        fi
    else
        local installed_rel="${rel#TEMPLATE/}"
        if [[ ! -f "${TARGET_REPO}/${installed_rel}" ]]; then
            log_fail "Missing critical swarm file: ${installed_rel}"
        fi
    fi
}

ensure_copilot_overlay() {
    local rel=".github/copilot-instructions.md"
    local path="${TARGET_REPO}/${rel}"
    if [[ -f "${path}" && ! -L "${path}" ]]; then
        return 0
    fi
    log_warn "Missing or invalid Copilot overlay: ${rel}. Regenerating host adapters..."
    rm -f "${path}" || true
    bash "${SCRIPT_DIR}/generate-host-adapters.sh" "${TARGET_REPO}" --write >/dev/null
    if [[ -f "${path}" && ! -L "${path}" ]]; then
        log_info "Repaired Copilot overlay via adapter generation."
        return 0
    fi
    log_fail "Unable to restore ${rel} as a regular generated file."
}

log_info "Verifying Swarm Fleet Core Tools..."
check_file "bootstrap/git-swarm-manager.sh"
check_file "bootstrap/sync-agent-adapters.sh"
check_file "bootstrap/repair-swarm-integrity.sh"
check_file "_system/MCP_CONFIG.md"
check_file "_system/AUTH_RECOVERY_PROTOCOL.md"
check_file "_system/mcp/MCP_SURVIVAL_PLAYBOOK.md"

log_info "Verifying Anti-Drift Rules..."
check_file ".cursor/rules/00-anti-drift-ssot.mdc"

log_info "Verifying Agent Adapters..."
check_file ".cursorrules"
check_file ".windsurfrules"
check_file ".clinerules"
check_file ".continuerules"

log_info "Verifying Copilot overlay..."
ensure_copilot_overlay

log_info "Verifying SSH Identity for 'whyte'..."
if [[ "$(whoami)" != "whyte" ]]; then
    log_warn "Current user is $(whoami), expected 'whyte' for swarm operations."
fi

echo "swarm_fleet_ok"
exit 0
