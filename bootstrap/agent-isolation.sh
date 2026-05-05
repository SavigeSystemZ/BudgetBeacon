#!/usr/bin/env bash
set -Eeuo pipefail

usage() {
  cat <<'EOF'
Usage:
  agent-isolation.sh [--repo-root <path>] [--print-env] [--apply]

Purpose:
  Isolate temp/cache/state paths per active repo session so many concurrent
  agent runtimes do not collide across projects.
EOF
}

ROOT_ARG=""
PRINT_ENV="false"
APPLY="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-root)
      ROOT_ARG="${2:-}"
      shift 2
      ;;
    --print-env)
      PRINT_ENV="true"
      shift
      ;;
    --apply)
      APPLY="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unexpected argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -n "$ROOT_ARG" ]; then
  REPO_ROOT="$ROOT_ARG"
else
  REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
fi

if [ ! -d "$REPO_ROOT" ]; then
  echo "Error: repo root not found: $REPO_ROOT" >&2
  exit 2
fi

ISOLATION_ROOT="$REPO_ROOT/.agent-runtime"
TMP_PATH="$ISOLATION_ROOT/tmp"
XDG_CACHE_PATH="$ISOLATION_ROOT/xdg-cache"
XDG_STATE_PATH="$ISOLATION_ROOT/xdg-state"
XDG_DATA_PATH="$ISOLATION_ROOT/xdg-data"
XDG_CONFIG_PATH="$ISOLATION_ROOT/xdg-config"

if [ "$APPLY" = "true" ]; then
  mkdir -p "$TMP_PATH" "$XDG_CACHE_PATH" "$XDG_STATE_PATH" "$XDG_DATA_PATH" "$XDG_CONFIG_PATH"
fi

if [ "$PRINT_ENV" = "true" ]; then
  cat <<EOF
export TMPDIR="$TMP_PATH"
export XDG_CACHE_HOME="$XDG_CACHE_PATH"
export XDG_STATE_HOME="$XDG_STATE_PATH"
export XDG_DATA_HOME="$XDG_DATA_PATH"
export XDG_CONFIG_HOME="$XDG_CONFIG_PATH"
EOF
fi

cat <<EOF
repo_root=$REPO_ROOT
isolation_root=$ISOLATION_ROOT
applied=$APPLY
print_env=$PRINT_ENV
next_action="source <(bash TEMPLATE/bootstrap/agent-isolation.sh --print-env) before launching parallel agent sessions"
EOF
