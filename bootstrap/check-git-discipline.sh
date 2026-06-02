#!/bin/bash
# Git Discipline Validation Script
# Enforces GitHub mirror model: single main branch by default, no feature branches

set -euo pipefail

REPO_ROOT="${1:-.}"
SCRIPT_NAME="check-git-discipline"

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

# Check 1: Verify git repository
check_git_repo() {
  if [ -d "$REPO_ROOT/.git" ]; then
    log_pass "Git repository found"
  else
    log_warn "Not a git repository (may be a fresh setup)"
    return 0
  fi
}

# Check 2: Verify main branch exists and is default
check_main_branch() {
  cd "$REPO_ROOT" || return 1
  
  if ! git rev-parse --verify main &>/dev/null; then
    log_warn "main branch does not exist (fresh repo or renamed default branch)"
    return 0
  fi
  
  local default_branch
  default_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
  
  if [ "$default_branch" == "main" ]; then
    log_pass "main is the current branch"
  else
    log_warn "Current branch is $default_branch (expected main)"
  fi
}

# Check 3: Verify only main branch exists (or whitelisted exceptions)
check_no_feature_branches() {
  cd "$REPO_ROOT" || return 1
  
  # Get list of local branches
  local branches
  branches=$(git branch --list | grep -v "^\*" | sed 's/^ *//' || true)
  
  if [ -z "$branches" ]; then
    log_pass "Only main branch exists (no feature branches)"
    return 0
  fi
  
  # Filter out main and check for violations
  local feature_branches
  feature_branches=$(echo "$branches" | grep -v "^main$" || true)
  
  if [ -z "$feature_branches" ]; then
    log_pass "Only main branch exists (no feature branches)"
  else
    # Check for whitelisted prefixes (wip/, review/, tmp/)
    local non_whitelisted
    non_whitelisted=$(echo "$feature_branches" | grep -v "^wip/" | grep -v "^review/" | grep -v "^tmp/" || true)
    
    if [ -z "$non_whitelisted" ]; then
      log_warn "Found whitelisted temporary branches: $(echo "$feature_branches" | tr '\n' ' ')"
    else
      log_fail "Found standing feature branches (should be merged or deleted): $(echo "$non_whitelisted" | tr '\n' ' ')"
    fi
  fi
}

# Check 4: Verify no stale remote branches
check_no_stale_remotes() {
  cd "$REPO_ROOT" || return 1
  
  if ! git remote -v &>/dev/null | grep -q "origin"; then
    log_warn "No remote configured yet (setup may be incomplete)"
    return 0
  fi
  
  # Get list of remote branches
  local remote_branches
  remote_branches=$(git branch -r | grep -v "^.*HEAD" | sed 's/^ *//' | sed 's|origin/||' || true)
  
  if [ -z "$remote_branches" ]; then
    log_pass "No remote branches (not yet pushed or only main exists)"
    return 0
  fi
  
  # Filter out main
  local remote_feature_branches
  remote_feature_branches=$(echo "$remote_branches" | grep -v "^main$" || true)
  
  if [ -z "$remote_feature_branches" ]; then
    log_pass "Only origin/main exists (no stale remote branches)"
  else
    log_warn "Remote has feature branches (cleanup needed): $(echo "$remote_feature_branches" | tr '\n' ' ')"
  fi
}

# Check 5: Verify no uncommitted changes
check_clean_tree() {
  cd "$REPO_ROOT" || return 1
  
  if [ -z "$(git status --porcelain 2>/dev/null || true)" ]; then
    log_pass "Working tree is clean"
  else
    log_warn "Working tree has uncommitted changes"
  fi
}

# Check 6: Verify no unmerged changes on feature branches
check_no_divergent_branches() {
  cd "$REPO_ROOT" || return 1
  
  # Get list of local branches
  local branches
  branches=$(git branch --list | grep -v "^\*" | sed 's/^ *//' || true)
  
  if [ -z "$branches" ]; then
    return 0
  fi
  
  # Check each branch for unmerged commits
  local found_divergent=0
  while IFS= read -r branch; do
    [ "$branch" = "main" ] && continue
    
    # Check if branch has unique commits not in main
    local unique_count
    unique_count=$(git rev-list --count main..$branch 2>/dev/null || echo 0)
    
    if [ "$unique_count" -gt 0 ]; then
      log_warn "Branch '$branch' has $unique_count unmerged commits"
      found_divergent=1
    fi
  done <<< "$branches"
  
  if [ $found_divergent -eq 0 ]; then
    log_pass "No divergent branches detected"
  fi
}

# Check 7: Verify no protected-branch rules blocking main
check_no_branch_protection() {
  cd "$REPO_ROOT" || return 1
  
  # This is a local check; remote protection is checked differently
  # Just warn if GitHub integration exists and might have rules
  if [ -f "$REPO_ROOT/.github/protected-branches.json" ] || \
     [ -f "$REPO_ROOT/.github/branch-protection.yml" ]; then
    log_warn "Found branch protection config (verify it doesn't block pushes to main)"
  else
    log_pass "No local branch protection rules found"
  fi
}

# Check 8: Verify remote is set correctly
check_remote_config() {
  cd "$REPO_ROOT" || return 1
  
  if ! git remote get-url origin &>/dev/null; then
    log_warn "No origin remote configured (setup may be incomplete)"
    return 0
  fi
  
  local origin_url
  origin_url=$(git remote get-url origin)
  
  if [ -z "$origin_url" ]; then
    log_warn "origin remote is empty"
  else
    log_pass "origin remote is configured: $origin_url"
  fi
}

# Main execution
main() {
  echo "======================= Git Discipline Validation ====================="
  echo "Repo: $REPO_ROOT"
  echo "Policy: GitHub mirror model (single main branch by default)"
  echo ""
  
  check_git_repo || return 0
  check_main_branch
  check_no_feature_branches
  check_no_stale_remotes
  check_clean_tree
  check_no_divergent_branches
  check_no_branch_protection
  check_remote_config
  
  echo ""
  echo "======================= Summary ======================================"
  echo "Violations: $VIOLATIONS"
  echo "Warnings: $WARNINGS"
  echo ""
  
  if [ $VIOLATIONS -eq 0 ]; then
    echo -e "${GREEN}✓ git_discipline_ok${NC}"
    return 0
  else
    echo -e "${RED}✗ git_discipline_failed${NC}"
    return 1
  fi
}

main "$@"
