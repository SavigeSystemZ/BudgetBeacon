#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/install/lib/runtime-foundation.sh
source "${SCRIPT_DIR}/lib/runtime-foundation.sh"

MODE="system"
DRY_RUN=0
PURGE_DATA=0
PURGE_CONFIG=0

usage() {
  cat <<'EOF'
Usage: uninstall.sh [--mode system|user] [--dry-run] [--purge-data] [--purge-config]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --purge-data)
      PURGE_DATA=1
      shift
      ;;
    --purge-config)
      PURGE_CONFIG=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

require_root_if_system_mode "${MODE}"

UNIT_DIR="${SYSTEMD_USER_DIR}"
DESKTOP_DIR="${DESKTOP_ENTRY_USER_DIR}"
if [[ "${MODE}" == "system" ]]; then
  UNIT_DIR="${SYSTEMD_SYSTEM_DIR}"
  DESKTOP_DIR="${DESKTOP_ENTRY_SYSTEM_DIR}"
fi

if command_exists systemctl; then
  if [[ "${MODE}" == "system" ]]; then
    run_step systemctl disable --now "${APP_SLUG}.service" || true
  else
    run_step systemctl --user disable --now "${APP_SLUG}.service" || true
  fi
fi

run_step rm -f "${UNIT_DIR}/${APP_SLUG}.service"
run_step rm -f "${DESKTOP_DIR}/${APP_ID}.desktop"

if [[ "${PURGE_DATA}" -eq 1 ]]; then
  run_step rm -rf "${DATA_DIR}"
fi

if [[ "${PURGE_CONFIG}" -eq 1 ]]; then
  run_step rm -rf "${CONFIG_DIR}"
  run_step rm -f "${ENV_FILE_ABS}"
fi

log "uninstall scaffold completed"
log "shared dependencies such as PostgreSQL, Docker, or Podman were intentionally preserved"
