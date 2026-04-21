#!/usr/bin/env bash
set -euo pipefail

APP_NAME="__AIAST_APP_NAME__"
APP_SLUG="__AIAST_APP_SLUG__"
APP_ID="__AIAST_APP_ID__"
APP_VERSION="__AIAST_VERSION__"
DEFAULT_BIND_ADDRESS="__AIAST_BIND_ADDRESS__"
DEFAULT_PORT_RANGE_START="__AIAST_PORT_RANGE_START__"
DEFAULT_PORT_RANGE_END="__AIAST_PORT_RANGE_END__"

INSTALL_ROOT="/opt/${APP_SLUG}"
DATA_DIR="/var/lib/${APP_SLUG}"
CONFIG_DIR="/etc/${APP_SLUG}"
SYSTEMD_SYSTEM_DIR="/etc/systemd/system"
SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
DESKTOP_ENTRY_SYSTEM_DIR="/usr/local/share/applications"
DESKTOP_ENTRY_USER_DIR="${HOME}/.local/share/applications"
SERVICE_USER="${APP_SLUG}"
SERVICE_GROUP="${APP_SLUG}"
ENV_TEMPLATE_PATH="ops/env/.env.example"
ENV_FILE_PATH="ops/env/.env"
PORT_ALLOCATOR="ops/install/lib/port_allocator.py"
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../.." && pwd)"
ENV_TEMPLATE_ABS="${ROOT_DIR}/${ENV_TEMPLATE_PATH}"
ENV_FILE_ABS="${ROOT_DIR}/${ENV_FILE_PATH}"
PORT_ALLOCATOR_ABS="${ROOT_DIR}/${PORT_ALLOCATOR}"
SYSTEM_PACKAGES="${SYSTEM_PACKAGES:-python3 python3-venv curl}"

log() {
  printf '[%s] %s\n' "${APP_SLUG}" "$*"
}

warn() {
  printf '[%s][warn] %s\n' "${APP_SLUG}" "$*" >&2
}

die() {
  printf '[%s][error] %s\n' "${APP_SLUG}" "$*" >&2
  exit 1
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_root_if_system_mode() {
  local mode="$1"
  if [[ "${mode}" == "system" && "${EUID}" -ne 0 ]]; then
    die "system mode requires root privileges"
  fi
}

run_step() {
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

run_shell_step() {
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  bash -lc "$*"
}

detect_os() {
  if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    printf '%s\n' "${ID:-unknown}"
    return
  fi
  uname -s | tr '[:upper:]' '[:lower:]'
}

detect_arch() {
  uname -m
}

detect_package_manager() {
  local pm=""
  for candidate in apt-get dnf yum zypper pacman apk; do
    if command_exists "${candidate}"; then
      pm="${candidate}"
      break
    fi
  done
  printf '%s\n' "${pm}"
}

install_system_packages() {
  local pm="$1"
  [[ -z "${pm}" ]] && return 0
  [[ -z "${SYSTEM_PACKAGES}" ]] && return 0

  case "${pm}" in
    apt-get)
      run_step apt-get update
      run_step apt-get install -y ${SYSTEM_PACKAGES}
      ;;
    dnf)
      run_step dnf install -y ${SYSTEM_PACKAGES}
      ;;
    yum)
      run_step yum install -y ${SYSTEM_PACKAGES}
      ;;
    zypper)
      run_step zypper --non-interactive install ${SYSTEM_PACKAGES}
      ;;
    pacman)
      run_step pacman -Sy --noconfirm ${SYSTEM_PACKAGES}
      ;;
    apk)
      run_step apk add --no-cache ${SYSTEM_PACKAGES}
      ;;
    *)
      warn "no installer mapping for package manager ${pm}"
      ;;
  esac
}

ensure_service_account() {
  local mode="$1"
  if [[ "${mode}" != "system" ]]; then
    return 0
  fi

  if ! getent group "${SERVICE_GROUP}" >/dev/null 2>&1; then
    run_step groupadd --system "${SERVICE_GROUP}"
  fi
  if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
    run_step useradd --system --home-dir "${DATA_DIR}" --shell /usr/sbin/nologin --gid "${SERVICE_GROUP}" "${SERVICE_USER}"
  fi
}

ensure_directories() {
  local mode="$1"
  local desktop_dir="${DESKTOP_ENTRY_USER_DIR}"

  run_step install -d -m 0755 "${ROOT_DIR}/dist"
  run_step install -d -m 0700 "$(dirname "${ENV_FILE_ABS}")"

  if [[ "${mode}" == "system" ]]; then
    run_step install -d -m 0750 "${DATA_DIR}"
    run_step install -d -m 0750 "${CONFIG_DIR}"
    desktop_dir="${DESKTOP_ENTRY_SYSTEM_DIR}"
  else
    run_step install -d -m 0700 "${HOME}/.config/${APP_SLUG}"
    run_step install -d -m 0700 "${HOME}/.local/share/${APP_SLUG}"
  fi

  run_step install -d -m 0755 "${desktop_dir}"
}

ensure_env_file() {
  local bind_address="$1"
  local port_override="$2"

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '[dry-run] prepare env file %s with bind=%s port=%s\n' "${ENV_FILE_ABS}" "${bind_address}" "${port_override:-auto}"
    return 0
  fi

  if [[ ! -f "${ENV_FILE_ABS}" ]]; then
    run_step install -m 0600 "${ENV_TEMPLATE_ABS}" "${ENV_FILE_ABS}"
  fi

  if [[ -n "${port_override}" ]]; then
    python3 "${PORT_ALLOCATOR_ABS}" "${ENV_FILE_ABS}" --key APP_PORT --bind-address "${bind_address}" --port "${port_override}"
  else
    python3 "${PORT_ALLOCATOR_ABS}" "${ENV_FILE_ABS}" --key APP_PORT --bind-address "${bind_address}" --start "${DEFAULT_PORT_RANGE_START}" --end "${DEFAULT_PORT_RANGE_END}"
  fi

  python3 - <<'PY' "${ENV_FILE_ABS}" "${bind_address}"
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
bind_address = sys.argv[2]
text = path.read_text() if path.exists() else ""
if "APP_BIND_ADDRESS=" in text:
    text = re.sub(r"^APP_BIND_ADDRESS=.*$", f"APP_BIND_ADDRESS={bind_address}", text, flags=re.MULTILINE)
else:
    text += f"\nAPP_BIND_ADDRESS={bind_address}\n"
path.write_text(text.lstrip("\n"))
path.chmod(0o600)
PY
}

current_port() {
  if [[ ! -f "${ENV_FILE_ABS}" ]]; then
    return 0
  fi
  awk -F= '$1=="APP_PORT" {print $2}' "${ENV_FILE_ABS}" | tail -n 1
}

write_desktop_entry() {
  local mode="$1"
  local desktop_dir="${DESKTOP_ENTRY_USER_DIR}"

  if [[ "${mode}" == "system" ]]; then
    desktop_dir="${DESKTOP_ENTRY_SYSTEM_DIR}"
  fi

  local path="${desktop_dir}/${APP_ID}.desktop"
  local exec_line="${ROOT_DIR}/ops/install/install.sh --launch"

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '[dry-run] write desktop entry %s\n' "${path}"
    return 0
  fi

  cat > "${path}" <<EOF
[Desktop Entry]
Type=Application
Version=1.0
Name=${APP_NAME}
Comment=${APP_NAME} launcher
Exec=${exec_line}
Icon=${APP_ID}
Terminal=false
Categories=Utility;
EOF
}

generate_systemd_unit() {
  local mode="$1"
  local env_file="$2"
  local unit_dir="${ROOT_DIR}/ops/install/build/systemd"
  local output_dir="${unit_dir}"
  local install_dir="${SYSTEMD_USER_DIR}"

  if [[ "${mode}" == "system" ]]; then
    install_dir="${SYSTEMD_SYSTEM_DIR}"
  fi

  run_step mkdir -p "${output_dir}"

  local exec_start="${ROOT_DIR}/ops/install/install.sh --launch"
  local user_name="${USER}"
  local group_name=""
  if [[ "${mode}" == "system" ]]; then
    user_name="${SERVICE_USER}"
    group_name="${SERVICE_GROUP}"
  fi

  local args=(
    bash "${ROOT_DIR}/bootstrap/generate-systemd-unit.sh"
    --preset http
    --service-name "${APP_SLUG}"
    --exec-start "${exec_start}"
    --working-directory "${ROOT_DIR}"
    --user "${user_name}"
    --environment-file "${env_file}"
    --output-dir "${output_dir}"
  )
  if [[ -n "${group_name}" ]]; then
    args+=(--group "${group_name}")
  fi

  run_step "${args[@]}"

  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    printf '[dry-run] install systemd unit %s.service to %s\n' "${APP_SLUG}" "${install_dir}"
    return 0
  fi

  install -d -m 0755 "${install_dir}"
  install -m 0644 "${output_dir}/${APP_SLUG}.service" "${install_dir}/${APP_SLUG}.service"
}

run_launch_command() {
  if [[ ! -f "${ENV_FILE_ABS}" ]]; then
    die "missing ${ENV_FILE_PATH}; run install.sh first"
  fi
  # shellcheck disable=SC1090
  source "${ENV_FILE_ABS}"
  : "${APP_EXEC_START:=python3 -m http.server ${APP_PORT:-8000} --bind ${APP_BIND_ADDRESS:-127.0.0.1}}"
  exec bash -lc "${APP_EXEC_START}"
}

best_artifact() {
  local arch="$1"
  local dist_dir="${ROOT_DIR}/dist"
  local artifact=""

  [[ ! -d "${dist_dir}" ]] && return 0

  if artifact="$(find "${dist_dir}" -maxdepth 1 -type f \( -name "*.deb" -o -name "*.rpm" -o -name "*.AppImage" -o -name "*.snap" \) | sort | head -n 1)"; then
    printf '%s\n' "${artifact}"
  fi
}
