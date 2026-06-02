#!/bin/bash
# Context Isolation Validation Script
# Checks that agent contexts stay repo-local and don't bleed from parent directories

set -euo pipefail

REPO_ROOT="${1:-.}"
SCRIPT_NAME="check-context-isolation"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize status
VIOLATIONS=0
WARNINGS=0

# Helper functions
log_pass() { echo -e "${GREEN}✓${NC} $1"; }
log_fail() { echo -e "${RED}✗${NC} $1"; ((VIOLATIONS++)); }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; ((WARNINGS++)); }

# Check 1: Verify local AGENTS.md exists
check_local_agents() {
  if [ -f "$REPO_ROOT/AGENTS.md" ]; then
    log_pass "Local AGENTS.md found"
  else
    log_fail "Local AGENTS.md not found (repo may not be scaffolded)"
  fi
}

# Check 2: Verify _system/ exists and is local
check_local_system() {
  if [ -d "$REPO_ROOT/_system" ]; then
    if [ -L "$REPO_ROOT/_system" ]; then
      log_fail "_system/ is a symlink (should be local directory)"
    else
      log_pass "Local _system/ directory found"
    fi
  else
    log_fail "Local _system/ directory not found"
  fi
}

# Check 3: Verify adapter folders are not symlinks
check_adapter_symlinks() {
  for adapter in .claude .cursor .gemini .aider .continuerules .clinerules; do
    if [ -L "$REPO_ROOT/$adapter" ]; then
      log_fail "$adapter/ is a symlink to parent or external location"
    elif [ -d "$REPO_ROOT/$adapter" ]; then
      log_pass "$adapter/ is a local directory (not symlink)"
    fi
  done
}

# Check 4: Verify no parent-directory references in context files
check_no_parent_references() {
  local found_refs=0
  
  # Check .cursor/plans, .cursor/rules for hardcoded parent paths
  if [ -d "$REPO_ROOT/.cursor/plans" ]; then
    if grep -r "~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE" "$REPO_ROOT/.cursor/plans/" 2>/dev/null; then
      log_fail "Found hardcoded parent paths in .cursor/plans/"
      found_refs=1
    fi
  fi
  
  # Check .cursor/rules for hardcoded parent paths
  if [ -d "$REPO_ROOT/.cursor/rules" ]; then
    if grep -r "~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE" "$REPO_ROOT/.cursor/rules/" 2>/dev/null; then
      log_fail "Found hardcoded parent paths in .cursor/rules/"
      found_refs=1
    fi
  fi
  
  # Check for "Canonical PWD" references in adapter files
  for adapter_file in "$REPO_ROOT"/.cursorrules "$REPO_ROOT"/.cursor/.cursorrules "$REPO_ROOT"/.claude/.cluerules; do
    if [ -f "$adapter_file" ] 2>/dev/null; then
      if grep -q "Canonical PWD" "$adapter_file" 2>/dev/null; then
        log_warn "Found 'Canonical PWD' in $adapter_file (should be agnostic)"
      fi
    fi
  done
  
  if [ $found_refs -eq 0 ]; then
    log_pass "No hardcoded parent-directory references found in context"
  fi
}

# Check 5: Verify runtime code doesn't reference _system/
check_runtime_isolation() {
  local found_refs=0
  
  for lang_pattern in "*.js" "*.ts" "*.py" "*.java" "*.go" "*.rs"; do
    if find "$REPO_ROOT" -name "$lang_pattern" -type f 2>/dev/null | \
       grep -v node_modules | \
       grep -v _system | \
       xargs grep -l "_system/" 2>/dev/null; then
      log_fail "Found _system/ references in runtime code ($lang_pattern)"
      found_refs=1
    fi
  done
  
  if [ $found_refs -eq 0 ]; then
    log_pass "Runtime code does not reference _system/"
  fi
}

# Check 6: Verify adapter README redirect shims
check_adapter_redirect_shims() {
  for adapter in .cursor .claude .gemini; do
    if [ -d "$REPO_ROOT/$adapter" ]; then
      if [ -f "$REPO_ROOT/$adapter/README.md" ]; then
        if grep -q -E "redirect|local|Redirect|Local" "$REPO_ROOT/$adapter/README.md" 2>/dev/null; then
          log_pass "$adapter/ has proper README.md"
        else
          log_warn "$adapter/README.md exists but may not clarify local authority"
        fi
      fi
    fi
  done
}

# Check 7: Verify TEMPLATE/.cursor is a shim only (no plans/rules in master)
check_template_adapter_shim() {
  # This check only applies if we're IN the template repo
  if [ -f "$REPO_ROOT/AGENTS.md" ] && grep -q "role: parent-template\|_AI_AGENT_SYSTEM_TEMPLATE" "$REPO_ROOT/AGENTS.md" 2>/dev/null; then
    
    # Check that .cursor/plans doesn't exist (it should be in _META_AGENT_SYSTEM/)
    if [ -d "$REPO_ROOT/.cursor/plans" ]; then
      log_fail "Master template has .cursor/plans/ (should be in _META_AGENT_SYSTEM/cursor-context/)"
    else
      log_pass "Master template has no .cursor/plans (correct)"
    fi
    
    # Note: .cursor/rules is application overlay rules (legitimate); template-maintenance rules are in _META_AGENT_SYSTEM/
    if [ -d "$REPO_ROOT/.cursor/rules" ]; then
      log_pass "Master template has .cursor/rules (application overlays, legitimate)"
    fi
  fi
}

# Main execution
main() {
  echo "==================== Context Isolation Validation ===================="
  echo "Repo: $REPO_ROOT"
  echo ""
  
  check_local_agents
  check_local_system
  check_adapter_symlinks
  check_no_parent_references
  check_runtime_isolation
  check_adapter_redirect_shims
  check_template_adapter_shim
  
  echo ""
  echo "==================== Summary =========================================="
  echo "Violations: $VIOLATIONS"
  echo "Warnings: $WARNINGS"
  echo ""
  
  if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✓ context_isolation_ok${NC}"
    return 0
  else
    echo -e "${RED}✗ context_isolation_failed${NC}"
    return 1
  fi
}

main "$@"
