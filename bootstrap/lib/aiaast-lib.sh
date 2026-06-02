#!/usr/bin/env bash

# Shared helpers for AIAST bootstrap and maintenance scripts.
#
# S22b WS6: this file is now a thin LOADER. The implementation was split
# into cohesive modules (aiaast-<area>.sh) in this same directory. The
# public contract is unchanged and fully back-compatible: scripts still
# `source .../lib/aiaast-lib.sh` and get the exact same function set, by
# the same names, with the same signatures and behaviour. Modules are
# sourced relative to THIS file's directory, so behaviour is identical in
# the TEMPLATE source and in every scaffolded downstream repo.
#
# Module order is dependency-safe: core (colors/asserts/state) first, then
# json, classify, repo, sync, managed, lock.

_AIAAST_LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/aiaast-core.sh
for _aiaast_mod in core json classify repo sync managed lock; do
  _aiaast_mod_path="${_AIAAST_LIB_DIR}/aiaast-${_aiaast_mod}.sh"
  if [[ ! -f "${_aiaast_mod_path}" ]]; then
    printf 'aiaast-lib: missing module: %s\n' "${_aiaast_mod_path}" >&2
    return 1 2>/dev/null || exit 1
  fi
  # shellcheck disable=SC1090
  source "${_aiaast_mod_path}"
done
unset _aiaast_mod _aiaast_mod_path
