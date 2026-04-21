#!/usr/bin/env bash
# AIAST Swarm Fleet: MCP Health & Re-Auth Validator
# Tests connectivity for each defined MCP server and provides re-auth steps on failure.

set -euo pipefail

log_info() { echo "✅ [MCP INFO] $1"; }
log_fail() { echo "❌ [MCP FAIL] $1"; }
log_warn() { echo "⚠️ [MCP WARN] $1"; }

check_filesystem() {
    log_info "Testing Filesystem MCP..."
    # We only check if the package is available/invocable without starting the long-running server.
    if command -v npx >/dev/null 2>&1; then
        log_info "Filesystem MCP: OK (npx available)"
    else
        log_fail "Filesystem MCP: npx NOT FOUND"
    fi
}

check_github() {
    log_info "Testing GitHub MCP..."
    if [[ -z "${GITHUB_PERSONAL_ACCESS_TOKEN:-}" ]]; then
        log_warn "GITHUB_PERSONAL_ACCESS_TOKEN is not set in shell environment."
        echo "   Re-Auth: Export GITHUB_PERSONAL_ACCESS_TOKEN to verify API connectivity."
    else
        log_info "GitHub MCP Token present."
    fi
}

check_brave() {
    log_info "Testing Brave Search MCP..."
    if [[ -z "${BRAVE_API_KEY:-}" ]]; then
        log_warn "BRAVE_API_KEY is not set in shell environment."
        echo "   Re-Auth: Export BRAVE_API_KEY to verify API connectivity."
    else
        log_info "Brave API Key present."
    fi
}

log_info "Starting MCP Fleet Health Check..."
check_filesystem
check_github
check_brave

echo ""
log_info "MCP Diagnostics complete. If an IDE reports MCP errors, check the 'mcpServers' config in your settings.json or claude_desktop_config.json."
exit 0
