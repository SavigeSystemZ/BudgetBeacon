#!/usr/bin/env bash
# Opt-in Caveman-style compression for human-edited prose (input token reduction).
# See _system/CONTEXT_BUDGET_STRATEGY.md — "Optional input file compression".
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: compress-context-file.sh <repo-root> <relative-file> [--dry-run]

Compress natural-language markdown using upstream caveman-compress (if installed).
Refuses governance paths, generated adapters, _system/, bootstrap/, .cursor/, and
paths outside docs/ or notes/ (v1 safety allowlist).

Environment:
  CAVEMAN_COMPRESS_HOME  Path to caveman-compress directory (contains scripts/).

Exit codes:
  0 success or dry-run allowed
  1 usage / denied path
  2 upstream not installed or compress failed
EOF
}

REPO_ROOT=""
REL=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then
        REPO_ROOT="$1"
        shift
      elif [[ -z "${REL}" ]]; then
        REL="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        usage
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${REPO_ROOT}" || -z "${REL}" ]]; then
  usage
  exit 1
fi

REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"
TARGET="${REPO_ROOT}/${REL}"
TARGET="${TARGET//\/\//\/}"

if [[ ! -f "${TARGET}" ]]; then
  echo "compress-context-file: not a file: ${TARGET}" >&2
  exit 1
fi

REL_NORM="${REL#./}"

deny_message() {
  echo "compress-context-file: REFUSED — $1" >&2
  echo "compress-context-file: See _system/CONTEXT_BUDGET_STRATEGY.md (input compression section)." >&2
  exit 1
}

case "${REL_NORM}" in
  *.original.md|*.original.txt) deny_message "backup files (*.original.md) are never compressed" ;;
esac

case "${TARGET}" in
  *.md|*.txt|*.rst) ;;
  *) deny_message "only .md, .txt, .rst are eligible (see upstream caveman-compress)" ;;
esac

case "${REL_NORM}" in
  docs/*|notes/*) ;;
  *) deny_message "v1 allowlist: path must be under docs/ or notes/ (relative to repo root)" ;;
esac

base="$(basename "${REL_NORM}")"
case "${base}" in
  AGENTS.md|CLAUDE.md|CODEX.md|GEMINI.md|WINDSURF.md|DEEPSEEK.md|PEARAI.md|LOCAL_MODELS.md)
    deny_message "host adapter / contract filenames are not compress targets"
    ;;
esac

case "${REL_NORM}" in
  _system/*|bootstrap/*|.cursor/*|.github/*|registry/*|ops/*|mobile/*|ai/*|packaging/*)
    deny_message "path prefix is contract or generated surface"
    ;;
esac

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "compress-context-file: dry-run OK — would compress: ${REL_NORM}"
  exit 0
fi

aiaast_assert_non_root_for_repo_writes

find_caveman_home() {
  local c
  for c in "${CAVEMAN_COMPRESS_HOME:-}" \
    "${HOME}/.claude/skills/caveman-compress"; do
    if [[ -n "${c}" && -d "${c}/scripts" && -f "${c}/scripts/compress.py" ]]; then
      (cd -- "${c}" && pwd)
      return 0
    fi
  done
  local template_root
  template_root="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
  local vendored="${template_root}/../_TEMPLATE_FACTORY/third_party/caveman-compress"
  if [[ -d "${vendored}/scripts" && -f "${vendored}/scripts/compress.py" ]]; then
    (cd -- "${vendored}" && pwd)
    return 0
  fi
  return 1
}

CAV_HOME=""
if ! CAV_HOME="$(find_caveman_home)"; then
  cat <<'EOF' >&2
compress-context-file: caveman-compress not found.

Install one of:
  1) Export CAVEMAN_COMPRESS_HOME to a caveman-compress directory (contains scripts/).
  2) cp -r <caveman-repo>/caveman-compress ~/.claude/skills/caveman-compress
  3) In the master AIAST repo, use the vendored copy under _TEMPLATE_FACTORY/third_party/caveman-compress

Upstream: https://github.com/JuliusBrussee/caveman/tree/main/caveman-compress
Requires: claude CLI on PATH for compression (see upstream README).
EOF
  exit 2
fi

if ! command -v claude >/dev/null 2>&1; then
  cat <<'EOF' >&2
compress-context-file: claude CLI not found on PATH.

Upstream caveman-compress calls: claude --print
Install Anthropic Claude Code CLI, then retry.
EOF
  exit 2
fi

export PYTHONPATH="${CAV_HOME}${PYTHONPATH:+:${PYTHONPATH}}"
if PYTHONPATH="${CAV_HOME}" python3 -m scripts "${TARGET}"; then
  exit 0
fi
exit 2
