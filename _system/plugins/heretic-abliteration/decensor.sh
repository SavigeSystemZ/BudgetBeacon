#!/usr/bin/env bash
# Wrapper for the host-local Heretic model abliteration tool.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: decensor.sh <model_name_or_path> [additional_heretic_args...]

Optional:
  HERETIC_DIR=/path/to/heretic-master  Override the host-local Heretic checkout.
EOF
}

resolve_heretic_dir() {
  local candidate

  if [[ -n "${HERETIC_DIR:-}" ]]; then
    [[ -d "${HERETIC_DIR}" ]] && { printf '%s\n' "${HERETIC_DIR}"; return 0; }
    printf 'Error: HERETIC_DIR does not exist: %s\n' "${HERETIC_DIR}" >&2
    return 1
  fi

  local candidates=(
    "${HOME}/.MyAppZ/_HERETIC_META_SYSTEM_ENHANCMENTS/heretic-master"
    "${HOME}/.MyAppZ/_HERETIC_META_SYSTEM_ENHANCEMENTS/heretic-master"
  )

  for candidate in "${candidates[@]}"; do
    if [[ -d "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  printf 'Error: Heretic master installation not found. Checked:\n' >&2
  for candidate in "${candidates[@]}"; do
    printf '  - %s\n' "${candidate}" >&2
  done
  printf 'Set HERETIC_DIR=/path/to/heretic-master to override.\n' >&2
  return 1
}

if [[ $# -eq 0 || "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  [[ $# -eq 0 ]] && exit 1 || exit 0
fi

if ! command -v uv >/dev/null 2>&1; then
  printf 'Error: uv is required to run Heretic but was not found on PATH.\n' >&2
  exit 1
fi

HERETIC_ROOT="$(resolve_heretic_dir)"
cd "${HERETIC_ROOT}"
printf 'Running Heretic abliteration from %s on %s...\n' "${HERETIC_ROOT}" "$1"
uv run heretic "$@"
