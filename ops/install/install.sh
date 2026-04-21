#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ops/install/lib/runtime-foundation.sh
source "${SCRIPT_DIR}/lib/runtime-foundation.sh"

MODE="system"
DRY_RUN=0
INSTALL_DEPS=0
SKIP_DB=0
SKIP_SERVICE=0
SKIP_DESKTOP=0
FORCE_SOURCE=0
PORT_OVERRIDE=""
BIND_ADDRESS="${DEFAULT_BIND_ADDRESS}"
LAUNCH_ONLY=0

usage() {
  cat <<'EOF'
Usage: install.sh [--mode system|user] [--dry-run] [--install-system-deps] [--skip-db] [--skip-service] [--skip-desktop] [--from-source] [--bind-address ADDRESS] [--port PORT] [--launch]
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
    --install-system-deps)
      INSTALL_DEPS=1
      shift
      ;;
    --skip-db)
      SKIP_DB=1
      shift
      ;;
    --skip-service)
      SKIP_SERVICE=1
      shift
      ;;
    --skip-desktop)
      SKIP_DESKTOP=1
      shift
      ;;
    --from-source)
      FORCE_SOURCE=1
      shift
      ;;
    --bind-address)
      BIND_ADDRESS="${2:-}"
      shift 2
      ;;
    --port)
      PORT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --launch)
      LAUNCH_ONLY=1
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

if [[ "${LAUNCH_ONLY}" -eq 1 ]]; then
  run_launch_command
fi

require_root_if_system_mode "${MODE}"

OS_ID="$(detect_os)"
ARCH="$(detect_arch)"
PACKAGE_MANAGER="$(detect_package_manager)"
ARTIFACT="$(best_artifact "${ARCH}" || true)"

log "installing ${APP_NAME} version ${APP_VERSION}"
log "os=${OS_ID} arch=${ARCH} package_manager=${PACKAGE_MANAGER:-none} mode=${MODE}"

if [[ "${INSTALL_DEPS}" -eq 1 ]]; then
  if [[ "${MODE}" != "system" ]]; then
    warn "system package installation is only supported in system mode"
  else
    install_system_packages "${PACKAGE_MANAGER}"
  fi
fi

ensure_service_account "${MODE}"
ensure_directories "${MODE}"
ensure_env_file "${BIND_ADDRESS}" "${PORT_OVERRIDE}"

if [[ "${SKIP_DB}" -eq 0 ]]; then
  if command_exists psql; then
    warn "database provisioning scaffold detected PostgreSQL client; review ops/env/.env before enabling app-specific database creation"
  else
    warn "PostgreSQL client not found; leaving database provisioning as a manual follow-up"
  fi
fi

if [[ -n "${ARTIFACT}" && "${FORCE_SOURCE}" -eq 0 ]]; then
  log "package artifact detected: ${ARTIFACT}"
  warn "automatic package installation is intentionally conservative in this scaffold; review and install the artifact explicitly"
else
  log "falling back to source-style deployment scaffold"
fi

if [[ "${SKIP_SERVICE}" -eq 0 ]]; then
  generate_systemd_unit "${MODE}" "${ENV_FILE_ABS}"
fi

if [[ "${SKIP_DESKTOP}" -eq 0 ]]; then
  write_desktop_entry "${MODE}"
fi

log "selected bind address ${BIND_ADDRESS}"
log "persisted app port $(current_port)"
log "review ${ENV_FILE_PATH} and replace APP_EXEC_START before enabling the service"
