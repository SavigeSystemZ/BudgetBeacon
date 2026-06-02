#!/usr/bin/env bash
# SHIM: Logic migrated to aiast-cli (Phase 2.3)
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/aiast-cli" check-evidence-quality "$@"
