#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: emit-session-environment.sh [repo-root] [--json]
EOF
}

REPO_ROOT=""
JSON_OUTPUT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then REPO_ROOT="$1"; shift; else echo "Unexpected argument: $1" >&2; exit 1; fi
      ;;
  esac
done

if [[ -z "${REPO_ROOT}" ]]; then
  REPO_ROOT="$(pwd)"
fi
REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"
REPO_NAME="$(basename -- "${REPO_ROOT}")"
UNDER_MYAPPZ=0
IN_TEMPLATE_REPO=0
MODE="out-of-bound"

if [[ "${REPO_ROOT}" == "${HOME}/.MyAppZ/"* ]]; then
  UNDER_MYAPPZ=1
  MODE="downstream-project"
fi
if [[ "${REPO_NAME}" == "_AI_AGENT_SYSTEM_TEMPLATE" ]]; then
  IN_TEMPLATE_REPO=1
  MODE="template-maintainer"
fi

if [[ "${REPO_ROOT}" == "${HOME}/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/TEMPLATE"* ]]; then
  IN_TEMPLATE_REPO=1
  MODE="template-maintainer"
fi

orphan_branch_exists=0
branch="none"
remote="none"

if git -C "${REPO_ROOT}" rev-parse --git-dir >/dev/null 2>&1; then
  branch="$(git -C "${REPO_ROOT}" branch --show-current 2>/dev/null || echo "none")"
  remote="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || echo "none")"
  if git -C "${REPO_ROOT}" show-ref --verify --quiet refs/heads/orphan/meta-build-continuity >/dev/null 2>&1; then
    orphan_branch_exists=1
  fi
fi

if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  python3 - <<'PY' "${REPO_ROOT}" "${REPO_NAME}" "${MODE}" "${UNDER_MYAPPZ}" "${IN_TEMPLATE_REPO}" "${branch}" "${remote}" "${orphan_branch_exists}"
import json, sys
print(json.dumps({
  "repo_root": sys.argv[1],
  "repo_name": sys.argv[2],
  "mode": sys.argv[3],
  "under_myappz": sys.argv[4] == "1",
  "in_template_repo": sys.argv[5] == "1",
  "git_branch": sys.argv[6],
  "git_remote_origin": sys.argv[7],
  "orphan_meta_branch_exists": sys.argv[8] == "1",
}, indent=2))
PY
else
  echo "session_environment_report"
  echo "repo_root=${REPO_ROOT}"
  echo "repo_name=${REPO_NAME}"
  echo "mode=${MODE}"
  echo "under_myappz=${UNDER_MYAPPZ}"
  echo "in_template_repo=${IN_TEMPLATE_REPO}"
  echo "git_branch=${branch}"
  echo "git_remote_origin=${remote}"
  echo "orphan_meta_branch_exists=${orphan_branch_exists}"
fi
