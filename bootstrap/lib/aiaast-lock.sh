#!/usr/bin/env bash
# aiaast-lock.sh — atomic lock primitives (S22a WS2)
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

# ---- Atomic lock primitives (S22a WS2) ------------------------------------
# Single-writer locking that is race-free under real concurrency. The lock
# identity is a guard DIRECTORY (<locks_dir>/<scope_key>.lock.d): `mkdir` is
# atomic on POSIX filesystems, so exactly one of N racing acquirers wins —
# unlike the legacy check-then-create (`[[ -f ]]` then write) pattern, which
# has a TOCTOU window. Authoritative metadata stays at the legacy path
# <locks_dir>/<scope_key>.lock.json (a regular file) so every existing
# reader (check-agent-locks.sh, agent-unlock.sh, agent-reclaim-lock.sh)
# keeps working unchanged. Stale reclaim is lease-aware: an expired
# `lease_expires_at` in the json makes the lock reclaimable (this also
# fixes a latent bug where expired leases blocked acquisition forever);
# when no json is present, a guard-dir mtime older than the fallback TTL
# is treated as stale.

aiaast_lock_guarddir() { printf '%s/%s.lock.d\n' "$1" "$2"; }
aiaast_lock_jsonpath() { printf '%s/%s.lock.json\n' "$1" "$2"; }

# aiaast_lock_is_stale <locks_dir> <scope_key> [fallback_ttl_seconds]
# rc 0 = stale/reclaimable (or no guard at all), rc 1 = live.
aiaast_lock_is_stale() {
  local locks_dir="$1"
  local scope_key="$2"
  local fallback_ttl="${3:-300}"
  local guard json
  guard="$(aiaast_lock_guarddir "${locks_dir}" "${scope_key}")"
  json="$(aiaast_lock_jsonpath "${locks_dir}" "${scope_key}")"
  [[ -d "${guard}" ]] || return 0
  if [[ -f "${json}" ]]; then
    if python3 - "${json}" <<'PY'
import json, sys
from datetime import datetime, timezone
try:
    d = json.load(open(sys.argv[1]))
    exp = datetime.strptime(d["lease_expires_at"], "%Y-%m-%dT%H:%M:%SZ").replace(tzinfo=timezone.utc)
except Exception:
    raise SystemExit(0)  # unparseable / missing lease -> treat as stale
raise SystemExit(0 if exp < datetime.now(timezone.utc) else 1)
PY
    then
      return 0
    fi
    return 1
  fi
  local mtime age
  mtime="$(stat -c %Y "${guard}" 2>/dev/null || echo 0)"
  age=$(( $(date +%s) - mtime ))
  [[ ${age} -gt ${fallback_ttl} ]]
}

# aiaast_lock_acquire <locks_dir> <scope_key> [fallback_ttl_seconds]
# rc 0 = acquired (guard dir now owned by caller; caller writes the json),
# rc 1 = held by a live lock.
aiaast_lock_acquire() {
  local locks_dir="$1"
  local scope_key="$2"
  local fallback_ttl="${3:-300}"
  local guard json
  guard="$(aiaast_lock_guarddir "${locks_dir}" "${scope_key}")"
  json="$(aiaast_lock_jsonpath "${locks_dir}" "${scope_key}")"
  mkdir -p "${locks_dir}"
  if mkdir "${guard}" 2>/dev/null; then
    return 0
  fi
  if aiaast_lock_is_stale "${locks_dir}" "${scope_key}" "${fallback_ttl}"; then
    rm -rf "${guard}" 2>/dev/null || true
    rm -f "${json}" 2>/dev/null || true
    if mkdir "${guard}" 2>/dev/null; then
      return 0
    fi
  fi
  return 1
}

# aiaast_lock_release <locks_dir> <scope_key>
aiaast_lock_release() {
  local locks_dir="$1"
  local scope_key="$2"
  rm -rf "$(aiaast_lock_guarddir "${locks_dir}" "${scope_key}")" 2>/dev/null || true
  rm -f "$(aiaast_lock_jsonpath "${locks_dir}" "${scope_key}")" 2>/dev/null || true
}
