#!/usr/bin/env bash
# aiaast-core.sh — ANSI/progress, asserts, time, require_*, sanitize_scope_key
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

# --- Visual progress helpers ---
# Suppress ANSI codes when stdout is not a terminal (piped mode).

_aiaast_ansi_ok=0
[[ -t 1 ]] && _aiaast_ansi_ok=1

_aiaast_bold() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[1m' || true; }
_aiaast_green() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[32m' || true; }
_aiaast_yellow() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[33m' || true; }
_aiaast_cyan() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[36m' || true; }
_aiaast_red() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[31m' || true; }
_aiaast_reset() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[0m' || true; }

aiaast_assert_non_root_for_repo_writes() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    cat >&2 <<'EOF'
Refusing to write repo-managed files as root.
Run this command as the intended repo owner instead, then repair any existing ownership drift before continuing.
EOF
    return 1
  fi
}

aiaast_section_header() {
  local title="$1"
  _aiaast_bold; _aiaast_cyan
  printf '=== %s ===\n' "${title}"
  _aiaast_reset
}

aiaast_progress_start() {
  local label="$1"
  _aiaast_yellow
  printf '  → %s...' "${label}"
  _aiaast_reset
}

aiaast_progress_step() {
  local label="$1"
  _aiaast_green
  printf '\r  ✓ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_done() {
  local label="${1:-done}"
  _aiaast_green
  printf '\r  ✓ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_warn() {
  local label="$1"
  _aiaast_yellow
  printf '  ⚠ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_fail() {
  local label="$1"
  _aiaast_red
  printf '  ✗ %s\n' "${label}"
  _aiaast_reset
}

aiaast_iso_utc_now() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

aiaast_require_file() {
  local path="$1"
  [[ -f "${path}" ]] || {
    echo "missing required file: ${path}" >&2
    return 1
  }
}

aiaast_require_dir() {
  local path="$1"
  [[ -d "${path}" ]] || {
    echo "missing required directory: ${path}" >&2
    return 1
  }
}

aiaast_sanitize_scope_key() {
  local raw="${1:-}"
  printf "%s" "${raw}" | tr '/:*?"<>| ' '_'
}
