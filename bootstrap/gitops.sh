#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
usage: gitops.sh <command> [args]

Commands:
  status                       Show git status and branch details.
  mirror [options]             Ensure GitHub origin is a simple full mirror.
  github-mirror [options]      Alias for mirror.
  start-branch <type> <slug>   Exception-only branch helper (policy-gated).
  sync                         Fetch, rebase on origin/main, run basic validation.
  checkpoint [class]           Create snapshot checkpoint via snapshotctl.
  merge-safe <branch>          Rebase current branch onto target branch.
  release-cut <version>        Tag release with annotated tag v<version>.
  recover <slug>               Create recovery branch fix/recovery-<slug>.

Environment:
  APP_ROOT                     Optional app root path override.

Mirror options:
  --create                     Create the GitHub repo with gh if missing.
  --push                       Push local main to origin/main.
  --configure                  Apply quiet mirror-oriented GitHub repo settings.
  --org ORG                    GitHub org/user (default: policy/env/origin).
  --repo NAME                  GitHub repo name (default: local directory name).
  --remote NAME                Git remote name (default: origin).
  --branch NAME                Mirror branch (default: main).
  --visibility private|public|internal
  --dry-run                    Print intended actions without writes.
EOF
}

policy_file() {
  local candidate1="${APP_ROOT}/_system/gitops-policy.json"
  local candidate2="${APP_ROOT}/app-meta/_system/gitops-policy.json"
  if [[ -f "${candidate1}" ]]; then
    echo "${candidate1}"
    return
  fi
  if [[ -f "${candidate2}" ]]; then
    echo "${candidate2}"
    return
  fi
  echo ""
}

policy_get_scalar() {
  local key="$1"
  local default_value="$2"
  local pf
  pf="$(policy_file)"
  if [[ -z "${pf}" ]]; then
    echo "${default_value}"
    return
  fi
  python3 - "${pf}" "${key}" "${default_value}" <<'PY'
import json
import sys
path, key, default_value = sys.argv[1:]
data = json.load(open(path, "r", encoding="utf-8"))
value = data.get(key, default_value)
if isinstance(value, bool):
    print("true" if value else "false")
elif isinstance(value, (int, float)):
    print(str(value))
else:
    print(value)
PY
}

policy_branch_type_allowed() {
  local branch_type="$1"
  local branch_strategy allow_topic
  branch_strategy="$(policy_get_scalar "branch_strategy" "main_only")"
  allow_topic="$(policy_get_scalar "allow_topic_branches_by_default" "false")"
  if [[ "${branch_strategy}" == "main_only" && "${allow_topic}" != "true" && -z "${AIAST_ALLOW_TOPIC_BRANCHES:-}" ]]; then
    return 1
  fi
  local pf
  pf="$(policy_file)"
  if [[ -z "${pf}" ]]; then
    [[ "${branch_type}" == "feat" || "${branch_type}" == "fix" || "${branch_type}" == "chore" || "${branch_type}" == "hotfix" ]]
    return
  fi
  python3 - "${pf}" "${branch_type}" <<'PY'
import json
import sys
path, branch_type = sys.argv[1:]
data = json.load(open(path, "r", encoding="utf-8"))
allowed = set(data.get("allowed_branch_types", []))
raise SystemExit(0 if branch_type in allowed else 1)
PY
}

parse_github_origin() {
  local remote_name="$1"
  local remote_url
  remote_url="$(git remote get-url "${remote_name}" 2>/dev/null || true)"
  [[ -n "${remote_url}" ]] || return 1
  case "${remote_url}" in
    git@github.com:*.git)
      local slug="${remote_url#git@github.com:}"
      slug="${slug%.git}"
      printf '%s\n' "${slug}"
      return 0
      ;;
    https://github.com/*.git)
      local slug="${remote_url#https://github.com/}"
      slug="${slug%.git}"
      printf '%s\n' "${slug}"
      return 0
      ;;
    https://github.com/*)
      local slug="${remote_url#https://github.com/}"
      printf '%s\n' "${slug}"
      return 0
      ;;
  esac
  return 1
}

log_event() {
  local status="$1"
  local cmd="$2"
  local details="${3:-{}}"
  local log_dir="${APP_ROOT}/ops/logs"
  mkdir -p "${log_dir}"
  python3 - "$status" "$cmd" "$details" "${APP_ROOT}" "${log_dir}/operations.jsonl" <<'PY'
import json
import sys
from datetime import datetime, timezone
status, cmd, details_raw, app_root, out = sys.argv[1:]
try:
    details = json.loads(details_raw)
except json.JSONDecodeError:
    details = {"message": details_raw}
event = {
    "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "tool": "gitops",
    "command": cmd,
    "status": status,
    "app_root": app_root,
    "details": details,
}
with open(out, "a", encoding="utf-8") as f:
    f.write(json.dumps(event, sort_keys=True) + "\n")
PY
}

ensure_git_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    echo "gitops: current directory is not a git repo" >&2
    exit 1
  }
}

detect_app_root() {
  local cwd
  cwd="$(pwd)"
  if [[ -n "${APP_ROOT:-}" ]]; then
    echo "${APP_ROOT}"
    return
  fi
  if [[ "${cwd}" == */app-runtime ]] || [[ "${cwd}" == */app-meta ]]; then
    dirname "${cwd}"
    return
  fi
  echo "${cwd}"
}

validate_private_remote() {
  local remote_url
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ -z "${remote_url}" ]]; then
    echo "gitops: no origin remote configured" >&2
    return 1
  fi
  local require_private
  require_private="$(policy_get_scalar "require_private_remotes" "false")"
  if [[ "${require_private}" == "true" ]] && [[ "${remote_url}" == https://github.com/* ]]; then
    echo "gitops: HTTPS origin detected; enforce private SSH remotes by policy" >&2
    return 1
  fi
  # Best-effort guard: reject obvious public HTTPS remotes.
  if [[ "${remote_url}" == https://github.com/* ]] && [[ "${remote_url}" != *".git" ]]; then
    echo "gitops: unable to verify private remote policy for ${remote_url}" >&2
  fi
  return 0
}

run_basic_validation() {
  if [[ -x "${SCRIPT_DIR}/validate-system.sh" ]]; then
    bash "${SCRIPT_DIR}/validate-system.sh" . >/dev/null
  fi
}

cmd_status() {
  git status --short --branch
  git remote -v
  log_event "ok" "status" "{}"
}

cmd_mirror() {
  local create=0 push=0 configure=0 dry_run=0
  local org="" repo="" remote branch visibility
  remote="$(policy_get_scalar "github_remote_name" "origin")"
  branch="$(policy_get_scalar "default_base_branch" "main")"
  visibility="$(policy_get_scalar "github_repo_visibility" "private")"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --create) create=1; shift ;;
      --push) push=1; shift ;;
      --configure) configure=1; shift ;;
      --dry-run) dry_run=1; shift ;;
      --org) org="${2:-}"; shift 2 ;;
      --repo) repo="${2:-}"; shift 2 ;;
      --remote) remote="${2:-origin}"; shift 2 ;;
      --branch) branch="${2:-main}"; shift 2 ;;
      --visibility) visibility="${2:-private}"; shift 2 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "gitops: mirror: unknown option: $1" >&2; exit 2 ;;
    esac
  done

  local parsed=""
  parsed="$(parse_github_origin "${remote}" || true)"
  if [[ -z "${org}" ]]; then
    org="${AIAST_GITHUB_ORG:-${GITHUB_APPS_ORG:-$(policy_get_scalar "github_org" "")}}"
    [[ -z "${org}" && "${parsed}" == */* ]] && org="${parsed%%/*}"
  fi
  if [[ -z "${repo}" ]]; then
    if [[ "${parsed}" == */* ]]; then
      repo="${parsed#*/}"
    else
      repo="$(basename "${APP_ROOT}")"
    fi
  fi

  [[ -n "${org}" ]] || { echo "gitops: mirror requires --org, AIAST_GITHUB_ORG/GITHUB_APPS_ORG, policy github_org, or an existing GitHub origin" >&2; exit 2; }
  [[ -n "${repo}" ]] || { echo "gitops: mirror could not determine repo name" >&2; exit 2; }

  case "${visibility}" in private|public|internal) ;; *) echo "gitops: invalid visibility: ${visibility}" >&2; exit 2 ;; esac

  local current_branch
  current_branch="$(git branch --show-current 2>/dev/null || true)"
  if [[ ${push} -eq 1 && "${current_branch}" != "${branch}" ]]; then
    echo "gitops: mirror policy pushes ${branch}; current branch is '${current_branch:-detached}'. Switch to ${branch} or pass --branch intentionally." >&2
    exit 1
  fi
  if [[ ${push} -eq 1 && -n "$(git status --porcelain 2>/dev/null)" ]]; then
    echo "gitops: refusing to mirror-push with a dirty working tree; commit or stash first" >&2
    exit 1
  fi

  local full="${org}/${repo}"
  local ssh_url="git@github.com:${full}.git"
  echo "github_mirror_plan repo=${full} remote=${remote} branch=${branch} visibility=${visibility} create=${create} push=${push} configure=${configure} dry_run=${dry_run}"

  if [[ ${dry_run} -eq 1 ]]; then
    return 0
  fi

  if [[ ${create} -eq 1 || ${configure} -eq 1 ]]; then
    command -v gh >/dev/null 2>&1 || {
      echo "gitops: gh CLI is required for --create/--configure" >&2
      exit 1
    }
    gh auth status -h github.com >/dev/null 2>&1 || {
      echo "gitops: gh is not authenticated for github.com; run 'gh auth login' as the repo owner" >&2
      exit 1
    }
  fi

  if [[ ${create} -eq 1 ]]; then
    if ! gh repo view "${full}" >/dev/null 2>&1; then
      local vis_flag="--private"
      [[ "${visibility}" == "public" ]] && vis_flag="--public"
      [[ "${visibility}" == "internal" ]] && vis_flag="--internal"
      gh repo create "${full}" "${vis_flag}" --disable-issues --disable-wiki
    fi
  fi

  if git remote get-url "${remote}" >/dev/null 2>&1; then
    git remote set-url "${remote}" "${ssh_url}"
  else
    git remote add "${remote}" "${ssh_url}"
  fi

  if [[ ${push} -eq 1 ]]; then
    git push -u "${remote}" "${branch}"
  fi

  if [[ ${configure} -eq 1 ]]; then
    gh repo edit "${full}" \
      --default-branch "${branch}" \
      --enable-projects=false \
      --enable-wiki=false \
      --enable-issues=false \
      --delete-branch-on-merge
  fi

  log_event "ok" "mirror" "{\"repo\":\"${full}\",\"remote\":\"${remote}\",\"branch\":\"${branch}\",\"pushed\":${push}}"
  echo "github_mirror_ok repo=${full} remote=${remote} branch=${branch} pushed=${push}"
}

cmd_start_branch() {
  local type="$1"
  local slug="$2"
  policy_branch_type_allowed "${type}" || {
    echo "gitops: invalid or policy-disallowed branch type '${type}'" >&2
    exit 2
  }
  git fetch --all --prune
  git checkout -b "${type}/${slug}"
  log_event "ok" "start-branch" "{\"branch\":\"${type}/${slug}\"}"
}

cmd_sync() {
  validate_private_remote || true
  local base_branch
  base_branch="$(policy_get_scalar "default_base_branch" "main")"
  git fetch --all --prune
  if git show-ref --verify --quiet "refs/remotes/origin/${base_branch}"; then
    git rebase "origin/${base_branch}"
  fi
  run_basic_validation
  log_event "ok" "sync" "{}"
}

cmd_checkpoint() {
  local class="${1:-checkpoint}"
  bash "${SCRIPT_DIR}/snapshotctl.sh" create --class "${class}"
  log_event "ok" "checkpoint" "{\"class\":\"${class}\"}"
}

cmd_merge_safe() {
  local target="$1"
  git fetch --all --prune
  git rebase "${target}"
  run_basic_validation
  log_event "ok" "merge-safe" "{\"target\":\"${target}\"}"
}

cmd_release_cut() {
  local version="$1"
  git tag -a "v${version}" -m "release v${version}"
  log_event "ok" "release-cut" "{\"tag\":\"v${version}\"}"
}

cmd_recover() {
  local slug="$1"
  local branch="fix/recovery-${slug}"
  git checkout -b "${branch}"
  log_event "warn" "recover" "{\"branch\":\"${branch}\"}"
}

main() {
  local cmd="${1:-}"
  [[ -n "${cmd}" ]] || { usage; exit 2; }
  shift || true

  APP_ROOT="$(detect_app_root)"
  ensure_git_repo

  case "${cmd}" in
    status) cmd_status ;;
    mirror|github-mirror) cmd_mirror "$@" ;;
    start-branch) cmd_start_branch "${1:-}" "${2:-}" ;;
    sync) cmd_sync ;;
    checkpoint) cmd_checkpoint "${1:-checkpoint}" ;;
    merge-safe) cmd_merge_safe "${1:-}" ;;
    release-cut) cmd_release_cut "${1:-}" ;;
    recover) cmd_recover "${1:-}" ;;
    *)
      usage
      exit 2
      ;;
  esac
}

main "$@"
