#!/usr/bin/env zsh

# AIAST Swarm Mode Git Manager
# Enables collision-free execution for solo developers using multiple AI agents.

set -e

# --- Configuration ---
ORG_NAME="SavigeSystemZ"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
REPO_NAME=$(basename -s .git $(git config --get remote.origin.url) 2>/dev/null || basename $(pwd))
REMOTE_URL="git@github.com:${ORG_NAME}/${REPO_NAME}.git"

# --- Formatting ---
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

log_info() { echo -e "${GREEN}✅ [SWARM INFO]${RESET} $1" }
log_warn() { echo -e "${YELLOW}⚠️ [SWARM WARN]${RESET} $1" }
log_err()  { echo -e "${RED}❌ [SWARM ERR]${RESET} $1"; exit 1; }

# --- Verification ---
ensure_remote() {
    local current_remote=$(git config --get remote.origin.url)
    if [[ "$current_remote" != "$REMOTE_URL" ]]; then
        log_warn "Remote origin mismatch. Configuring to $REMOTE_URL..."
        git remote set-url origin "$REMOTE_URL" || git remote add origin "$REMOTE_URL"
        log_info "Remote origin configured."
    fi
}

ensure_dev_branch() {
    if ! git show-ref --verify --quiet refs/heads/dev; then
        log_warn "Branch 'dev' does not exist locally. Creating from main..."
        git checkout -b dev main || log_err "Failed to create 'dev' branch."
    fi
}

# --- Actions ---
action_start() {
    local agent_name=$1
    local feature=$2

    if [[ -z "$agent_name" || -z "$feature" ]]; then
        log_err "Usage: swarm-init start <agent_name> <feature>"
    fi

    ensure_remote
    ensure_dev_branch

    # Sync dev branch first
    log_info "Syncing 'dev' branch..."
    git checkout dev
    git pull origin dev || log_warn "Could not pull 'dev' from origin. It might not exist remotely yet."

    local target_branch="ai/${agent_name}/${feature}"
    log_info "Starting swarm branch: ${target_branch}"
    
    if git show-ref --verify --quiet refs/heads/$target_branch; then
         git checkout $target_branch
         log_info "Checked out existing branch ${target_branch}"
    else
         git checkout -b $target_branch
         log_info "Created and checked out new branch ${target_branch}"
    fi
}

action_auto_push() {
    log_info "Executing auto-push on branch: $CURRENT_BRANCH"
    
    if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "dev" ]]; then
         log_err "auto-push is restricted on 'main' and 'dev'. Use standard git workflows."
    fi

    git add -A
    
    if git diff --staged --quiet; then
        log_warn "No changes to commit."
        return 0
    fi

    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    local commit_msg="chore(swarm): automated sync from $CURRENT_BRANCH at $timestamp"
    
    git commit -m "$commit_msg"
    git push -u origin $CURRENT_BRANCH
    log_info "Successfully pushed to origin/$CURRENT_BRANCH"
}

action_squash_merge() {
    log_info "Squash merging $CURRENT_BRANCH into 'dev'"
    
    if [[ "$CURRENT_BRANCH" != ai/* ]]; then
         log_err "You can only squash-merge 'ai/*' branches into dev using this command."
    fi

    local branch_to_merge=$CURRENT_BRANCH

    # Ensure working tree is clean
    if ! git diff --quiet || ! git diff --staged --quiet; then
        log_warn "Working tree is not clean. Committing pending changes first..."
        action_auto_push
    fi

    git checkout dev
    git pull origin dev || true

    log_info "Squashing $branch_to_merge..."
    git merge --squash $branch_to_merge || log_err "Merge conflict during squash. Resolve manually."
    
    local commit_msg="feat(swarm): squash merge $branch_to_merge into dev"
    git commit -m "$commit_msg" || log_warn "Nothing to commit after squash."
    
    git push origin dev
    log_info "Successfully pushed 'dev' to origin."

    log_info "Cleaning up ephemeral branch: $branch_to_merge"
    git branch -D $branch_to_merge
    git push origin --delete $branch_to_merge || true
    
    log_info "Squash merge complete. Currently on 'dev'."
}

action_sync() {
    log_info "Fetching all remotes and pruning..."
    git fetch --all --prune
    git status
}

# --- Main Routing ---
case "$1" in
    start)
        action_start "$2" "$3"
        ;;
    auto-push)
        action_auto_push
        ;;
    squash-merge)
        action_squash_merge
        ;;
    sync)
        action_sync
        ;;
    *)
        echo -e "${YELLOW}Usage: swarm-init {start <agent> <feature> | sync | squash-merge | auto-push}${RESET}"
        exit 1
        ;;
esac
