#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: install-autonomous-guardrails.sh [target-repo] [--source <template-root>] [--mode <quick|full>] [--interval <minutes>] [--strict] [--force-cron] [--fail-on-warn] [--dry-run]

Install recurring autonomous guardrail checks for a repo.

Default behavior:
- prefer user-level systemd timer when available
- fallback to user crontab when systemd user services are unavailable

Use `--dry-run` to print the exact unit/cron payload without mutating systemd,
crontab, or disk outside the repo (safe for CI and proof runs).

This script does not require root and should be run as the repo owner.
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_REPO=""
SOURCE=""
MODE="full"
INTERVAL_MINUTES=120
STRICT=0
FORCE_CRON=0
FAIL_ON_WARN=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --interval)
      INTERVAL_MINUTES="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --force-cron)
      FORCE_CRON=1
      shift
      ;;
    --fail-on-warn)
      FAIL_ON_WARN=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="${DEFAULT_TARGET}"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

case "${MODE}" in
  quick|full) ;;
  *)
    echo "Unsupported mode: ${MODE}" >&2
    exit 1
    ;;
esac

if ! [[ "${INTERVAL_MINUTES}" =~ ^[0-9]+$ ]] || [[ "${INTERVAL_MINUTES}" -lt 5 ]]; then
  echo "Interval must be an integer >= 5 minutes." >&2
  exit 1
fi

RUNNER="${SCRIPT_DIR}/run-autonomous-guardrails.sh"
if [[ ! -x "${RUNNER}" ]]; then
  chmod +x "${RUNNER}"
fi

strict_flag=""
[[ ${STRICT} -eq 1 ]] && strict_flag=" --strict"
source_flag=""
if [[ -n "${SOURCE}" ]]; then
  source_flag=" --source \"${SOURCE}\""
fi

quoted_target="$(printf '%q' "${TARGET_REPO}")"
runner_cmd="\"${RUNNER}\" ${quoted_target}${source_flag} --mode ${MODE}${strict_flag}"
if [[ ${FAIL_ON_WARN} -eq 0 ]]; then
  runner_cmd="${runner_cmd} --allow-warn"
fi

use_systemd=0
if [[ ${FORCE_CRON} -eq 0 ]] && command -v systemctl >/dev/null 2>&1; then
  if systemctl --user show-environment >/dev/null 2>&1; then
    use_systemd=1
  fi
fi

service_name="aiaast-guardrails"
unit_root="${HOME}/.config/systemd/user"
service_file="${unit_root}/${service_name}.service"
timer_file="${unit_root}/${service_name}.timer"

service_unit=$(
  cat <<EOF
[Unit]
Description=AIAST autonomous guardrails check

[Service]
Type=oneshot
WorkingDirectory=${TARGET_REPO}
ExecStart=/usr/bin/env bash -lc ${runner_cmd}
EOF
)

timer_unit=$(
  cat <<EOF
[Unit]
Description=Run AIAST autonomous guardrails every ${INTERVAL_MINUTES} minutes

[Timer]
OnBootSec=5min
OnUnitActiveSec=${INTERVAL_MINUTES}min
Persistent=true
Unit=${service_name}.service

[Install]
WantedBy=timers.target
EOF
)

if [[ ${use_systemd} -eq 1 ]]; then
  if [[ ${DRY_RUN} -eq 1 ]]; then
    echo "autonomous_guardrails_dry_run scheduler=systemd-user interval_min=${INTERVAL_MINUTES}"
    echo "would_write_service_file=${service_file}"
    echo "would_write_timer_file=${timer_file}"
    echo ""
    echo "--- ${service_name}.service ---"
    printf '%s\n' "${service_unit}"
    echo ""
    echo "--- ${service_name}.timer ---"
    printf '%s\n' "${timer_unit}"
    echo ""
    echo "dry_run_complete no_mutations=true"
    exit 0
  fi

  mkdir -p "${unit_root}"
  printf '%s\n' "${service_unit}" > "${service_file}"
  printf '%s\n' "${timer_unit}" > "${timer_file}"

  systemctl --user daemon-reload
  systemctl --user enable --now "${service_name}.timer"

  echo "autonomous_guardrails_installed scheduler=systemd-user timer=${service_name}.timer interval_min=${INTERVAL_MINUTES}"
  exit 0
fi

# cron fallback
if ! command -v crontab >/dev/null 2>&1; then
  echo "Neither user systemd timers nor crontab are available on this host." >&2
  exit 1
fi

cron_marker="# AIAST_AUTONOMOUS_GUARDRAILS"
# Minute field is 0–59; large intervals need hourly approximation.
if [[ "${INTERVAL_MINUTES}" -le 59 ]]; then
  cron_expr="*/${INTERVAL_MINUTES} * * * *"
else
  cron_hours=$(( (INTERVAL_MINUTES + 59) / 60 ))
  cron_expr="0 */${cron_hours} * * *"
fi
cron_cmd="/usr/bin/env bash -lc ${runner_cmd} >/dev/null 2>&1 ${cron_marker}"

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "autonomous_guardrails_dry_run scheduler=cron interval_min=${INTERVAL_MINUTES}"
  echo "would_append_crontab_line:"
  printf '%s %s\n' "${cron_expr}" "${cron_cmd}"
  echo "dry_run_complete no_mutations=true"
  exit 0
fi

tmp_cron="$(mktemp)"
trap 'rm -f "${tmp_cron}"' EXIT

crontab -l 2>/dev/null | rg -v "${cron_marker}" > "${tmp_cron}" || true
printf '%s %s\n' "${cron_expr}" "${cron_cmd}" >> "${tmp_cron}"
crontab "${tmp_cron}"

echo "autonomous_guardrails_installed scheduler=cron interval_min=${INTERVAL_MINUTES}"
