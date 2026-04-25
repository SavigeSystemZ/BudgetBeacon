#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: snapshot-meta-to-orphan-branch.sh [repo-root] [--branch <name>] [--dry-run]
EOF
}

REPO_ROOT=""
BRANCH_NAME=""
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch) BRANCH_NAME="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then REPO_ROOT="$1"; shift; else echo "Unexpected argument: $1" >&2; exit 1; fi
      ;;
  esac
done

if [[ -z "${REPO_ROOT}" ]]; then REPO_ROOT="$(pwd)"; fi
REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"
REPO_NAME="$(basename -- "${REPO_ROOT}")"
if [[ -z "${BRANCH_NAME}" ]]; then
  BRANCH_NAME="orphan/meta-system/${REPO_NAME}"
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "dry_run_orphan_snapshot_branch=${BRANCH_NAME}"
  exit 0
fi

current_branch="$(git -C "${REPO_ROOT}" branch --show-current)"
if ! git -C "${REPO_ROOT}" show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
  git -C "${REPO_ROOT}" checkout --orphan "${BRANCH_NAME}"
  git -C "${REPO_ROOT}" reset --hard
else
  git -C "${REPO_ROOT}" checkout "${BRANCH_NAME}"
fi

git -C "${REPO_ROOT}" rm -r --cached . >/dev/null 2>&1 || true

include_paths=(AGENTS.md _system .cursor .github .cursorrules CODEX.md CLAUDE.md GEMINI.md WINDSURF.md DEEPSEEK.md PEARAI.md LOCAL_MODELS.md)
for p in "${include_paths[@]}"; do
  if [[ -e "${REPO_ROOT}/${p}" ]]; then
    git -C "${REPO_ROOT}" add "${p}"
  fi
done

git -C "${REPO_ROOT}" commit -m "chore(meta): snapshot project-local metasystem $(date -u +%Y-%m-%dT%H:%M:%SZ)" || true
git -C "${REPO_ROOT}" checkout "${current_branch}"
echo "orphan_snapshot_complete=${BRANCH_NAME}"
