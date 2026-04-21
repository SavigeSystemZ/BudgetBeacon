#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: generate-systemd-unit.sh --preset <http|worker|timer> --service-name <name> --exec-start <command> --working-directory <dir> --user <user> [--group <group>] [--environment-file <path>] [--schedule <calendar>] [--output-dir <dir>]

Generate hardened systemd service units. Timer preset writes both .service and .timer.
EOF
}

PRESET=""
SERVICE_NAME=""
EXEC_START=""
WORKING_DIRECTORY=""
USER_NAME=""
GROUP_NAME=""
ENVIRONMENT_FILE=""
SCHEDULE=""
OUTPUT_DIR="."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --preset)
      PRESET="${2:-}"
      shift 2
      ;;
    --service-name)
      SERVICE_NAME="${2:-}"
      shift 2
      ;;
    --exec-start)
      EXEC_START="${2:-}"
      shift 2
      ;;
    --working-directory)
      WORKING_DIRECTORY="${2:-}"
      shift 2
      ;;
    --user)
      USER_NAME="${2:-}"
      shift 2
      ;;
    --group)
      GROUP_NAME="${2:-}"
      shift 2
      ;;
    --environment-file)
      ENVIRONMENT_FILE="${2:-}"
      shift 2
      ;;
    --schedule)
      SCHEDULE="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
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

if [[ -z "${PRESET}" || -z "${SERVICE_NAME}" || -z "${EXEC_START}" || -z "${WORKING_DIRECTORY}" || -z "${USER_NAME}" ]]; then
  usage
  exit 1
fi

if [[ "${PRESET}" == "timer" && -z "${SCHEDULE}" ]]; then
  echo "Timer preset requires --schedule" >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

group_line=""
env_line=""
timer_unit=""
service_type="simple"
service_description="AIAST-managed service"

[[ -n "${GROUP_NAME}" ]] && group_line="Group=${GROUP_NAME}"
[[ -n "${ENVIRONMENT_FILE}" ]] && env_line="EnvironmentFile=-${ENVIRONMENT_FILE}"

case "${PRESET}" in
  http)
    service_description="AIAST HTTP service"
    ;;
  worker)
    service_description="AIAST background worker"
    ;;
  timer)
    service_description="AIAST scheduled task"
    service_type="oneshot"
    timer_unit="[Unit]
Description=${SERVICE_NAME} timer

[Timer]
OnCalendar=${SCHEDULE}
Persistent=true
Unit=${SERVICE_NAME}.service

[Install]
WantedBy=timers.target
"
    ;;
  *)
    echo "Unsupported preset: ${PRESET}" >&2
    exit 1
    ;;
esac

cat > "${OUTPUT_DIR}/${SERVICE_NAME}.service" <<EOF
[Unit]
Description=${service_description}
After=network.target

[Service]
Type=${service_type}
User=${USER_NAME}
${group_line}
WorkingDirectory=${WORKING_DIRECTORY}
${env_line}
ExecStart=${EXEC_START}
Restart=on-failure
RestartSec=2
UMask=0077
NoNewPrivileges=yes
PrivateTmp=yes
PrivateDevices=yes
DevicePolicy=closed
ProtectSystem=strict
ProtectHome=read-only
ProtectKernelModules=yes
ProtectKernelTunables=yes
ProtectControlGroups=yes
RestrictSUIDSGID=yes
RestrictRealtime=yes
LockPersonality=yes
MemoryDenyWriteExecute=yes
RestrictNamespaces=yes
SystemCallArchitectures=native
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
CapabilityBoundingSet=

[Install]
WantedBy=multi-user.target
EOF

if [[ "${PRESET}" == "timer" ]]; then
  printf '%s' "${timer_unit}" > "${OUTPUT_DIR}/${SERVICE_NAME}.timer"
fi

echo "Generated ${OUTPUT_DIR}/${SERVICE_NAME}.service"
if [[ "${PRESET}" == "timer" ]]; then
  echo "Generated ${OUTPUT_DIR}/${SERVICE_NAME}.timer"
fi
