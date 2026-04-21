#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: repair-myappz-root-ownership.sh [workspace-root] [--apply] [--include-backups] [--user USER] [--group GROUP]

Audit or repair root-owned paths inside a MyAppZ workspace.

Defaults:
  workspace-root    $HOME/.MyAppZ
  --user            current user, or $SUDO_USER when run with sudo
  --group           primary group for --user
  --include-backups off; _backups is excluded by default to avoid mutating preserved root-owned snapshots
  --apply           off; without it the script only reports the affected paths and the exact sudo command to run

Examples:
  bootstrap/repair-myappz-root-ownership.sh
  sudo bootstrap/repair-myappz-root-ownership.sh /home/whyte/.MyAppZ --apply --user whyte --group whyte
EOF
}

WORKSPACE_ROOT="${HOME}/.MyAppZ"
APPLY=0
INCLUDE_BACKUPS=0
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_GROUP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      shift
      ;;
    --include-backups)
      INCLUDE_BACKUPS=1
      shift
      ;;
    --user)
      TARGET_USER="$2"
      shift 2
      ;;
    --group)
      TARGET_GROUP="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
    *)
      WORKSPACE_ROOT="$1"
      shift
      ;;
  esac
done

if [[ -z "${TARGET_GROUP}" ]]; then
  TARGET_GROUP="$(id -gn "${TARGET_USER}" 2>/dev/null || id -gn)"
fi

if [[ ! -d "${WORKSPACE_ROOT}" ]]; then
  echo "Workspace root not found: ${WORKSPACE_ROOT}" >&2
  exit 2
fi

find_root_owned_paths() {
  if [[ "${INCLUDE_BACKUPS}" -eq 1 ]]; then
    find "${WORKSPACE_ROOT}" -xdev \( -uid 0 -o -gid 0 \) -print 2>/dev/null | sort
  else
    find "${WORKSPACE_ROOT}" -xdev -path "${WORKSPACE_ROOT}/_backups" -prune -o \
      \( -uid 0 -o -gid 0 \) -print 2>/dev/null | sort
  fi
}

mapfile -t ROOT_OWNED_PATHS < <(find_root_owned_paths)

if [[ "${#ROOT_OWNED_PATHS[@]}" -eq 0 ]]; then
  echo "workspace_root_ownership_ok"
  exit 0
fi

printf 'workspace_root_owned_paths=%s\n' "${#ROOT_OWNED_PATHS[@]}"
printf '%s\n' "${ROOT_OWNED_PATHS[@]}"

printf '\naffected_top_level_entries:\n'
printf '%s\n' "${ROOT_OWNED_PATHS[@]}" | awk -v root="${WORKSPACE_ROOT}/" '
{
  path = $0
  sub("^" root, "", path)
  split(path, parts, "/")
  print parts[1]
}' | sort -u

if [[ "${APPLY}" -eq 0 ]]; then
  printf '\nrun_to_repair:\n'
  printf 'sudo %q %q --apply --user %q --group %q' \
    "$0" "${WORKSPACE_ROOT}" "${TARGET_USER}" "${TARGET_GROUP}"
  if [[ "${INCLUDE_BACKUPS}" -eq 1 ]]; then
    printf ' --include-backups'
  fi
  printf '\n'
  exit 1
fi

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Repair mode requires root. Re-run the printed command with sudo." >&2
  exit 2
fi

find_args=("${WORKSPACE_ROOT}" -xdev)
if [[ "${INCLUDE_BACKUPS}" -eq 0 ]]; then
  find_args+=(-path "${WORKSPACE_ROOT}/_backups" -prune -o)
fi
find_args+=("(" -uid 0 -o -gid 0 ")" -exec chown "${TARGET_USER}:${TARGET_GROUP}" "{}" +)
find "${find_args[@]}"

mapfile -t REMAINING_PATHS < <(find_root_owned_paths)
if [[ "${#REMAINING_PATHS[@]}" -gt 0 ]]; then
  echo "workspace_root_ownership_repair_incomplete" >&2
  printf '%s\n' "${REMAINING_PATHS[@]}" >&2
  exit 1
fi

echo "workspace_root_ownership_repaired"
