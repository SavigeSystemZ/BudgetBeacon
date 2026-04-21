#!/usr/bin/env zsh

# AIAST Swarm Fleet: Integrity & Repair Tool
# Self-healing script to fix agent hooks, reset stuck states, and verify auth.

set -e

# --- Configuration ---
PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TEMPLATE_DIR="${PROJECT_ROOT}/TEMPLATE"
RECOVERY_PROTO="${PROJECT_ROOT}/TEMPLATE/_system/AUTH_RECOVERY_PROTOCOL.md"

# --- Formatting ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log_info() { echo -e "${GREEN}✅ [REPAIR INFO]${RESET} $1" }
log_warn() { echo -e "${YELLOW}⚠️ [REPAIR WARN]${RESET} $1" }
log_err()  { echo -e "${RED}❌ [REPAIR ERR]${RESET} $1" }

# --- Actions ---

repair_hooks() {
    log_info "Synchronizing agent adapters with SSoT..."
    if [[ -f "${TEMPLATE_DIR}/bootstrap/sync-agent-adapters.sh" ]]; then
        zsh "${TEMPLATE_DIR}/bootstrap/sync-agent-adapters.sh"
    else
        log_err "Sync script missing at ${TEMPLATE_DIR}/bootstrap/sync-agent-adapters.sh"
    fi
}

reset_agent_state() {
    log_info "Pruning agent ephemeral state to break logic loops..."
    
    # Cursor
    if [[ -d ".cursor/rules/.state" ]]; then
        rm -rf ".cursor/rules/.state"
        log_info "Pruned .cursor/rules/.state"
    fi

    # Windsurf
    if [[ -d ".windsurf_cache" ]]; then
        rm -rf ".windsurf_cache"
        log_info "Pruned .windsurf_cache"
    fi

    # Cline/Claude
    if [[ -d ".claude_cache" ]]; then
        rm -rf ".claude_cache"
        log_info "Pruned .claude_cache"
    fi
}

verify_auth() {
    log_info "Verifying SSH authentication for GitHub..."
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        log_info "GitHub SSH authentication: OK"
    else
        log_warn "GitHub SSH authentication failed."
        echo -e "${YELLOW}Refer to ${RECOVERY_PROTO} for manual recovery steps.${RESET}"
    fi

    log_info "Verifying repository ownership..."
    local git_owner=$(ls -ld .git | awk '{print $3}')
    if [[ "$git_owner" != "whyte" ]]; then
        log_warn "Repo owned by $git_owner, expected whyte. Attempting fix..."
        sudo chown -R whyte:whyte . || log_err "Failed to change ownership."
        log_info "Repo ownership corrected to whyte."
    else
        log_info "Repo ownership: OK"
    fi
}

# --- Main Routing ---
case "$1" in
    --hooks-only)
        repair_hooks
        ;;
    --reset-agent-state)
        reset_agent_state
        ;;
    --full)
        repair_hooks
        reset_agent_state
        verify_auth
        ;;
    *)
        echo -e "${YELLOW}Usage: swarm-repair {--hooks-only | --reset-agent-state | --full}${RESET}"
        exit 1
        ;;
esac

log_info "Repair operations complete."
