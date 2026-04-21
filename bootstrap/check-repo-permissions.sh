#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-repo-permissions.sh [target-repo] [--fix-modes]

Validate that repo files outside .git are owned by the current user and group,
and that they remain writable by the current user.

Options:
  --fix-modes  Add user write permission back to user-owned files and
               directories when mode drift is the only problem.
EOF
}

TARGET_REPO=""
FIX_MODES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix-modes)
      FIX_MODES=1
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
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"
EXPECTED_UID="$(id -u)"
EXPECTED_GID="$(id -g)"
EXPECTED_USER="$(id -un)"
EXPECTED_GROUP="$(id -gn)"

ownership_issues=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && ownership_issues+=("${line}")
done < <(
  find "${TARGET_REPO}" \
    -type d -name .git -prune -o \
    \( ! -uid "${EXPECTED_UID}" -o ! -gid "${EXPECTED_GID}" \) \
    -printf '%M %u:%g %P\n' | sort
)

mode_issues=()
while IFS= read -r line; do
  [[ -n "${line}" ]] && mode_issues+=("${line}")
done < <(
  find "${TARGET_REPO}" \
    -type d -name .git -prune -o \
    \( -type f -o -type d \) ! -writable \
    -printf '%M %u:%g %P\n' | sort
)

fixed=0
if [[ ${FIX_MODES} -eq 1 && ${#mode_issues[@]} -gt 0 ]]; then
  while IFS= read -r -d '' path; do
    if [[ -f "${path}" ]]; then
      chmod u+rw "${path}"
      fixed=$((fixed + 1))
    elif [[ -d "${path}" ]]; then
      chmod u+rwx "${path}"
      fixed=$((fixed + 1))
    fi
  done < <(
    find "${TARGET_REPO}" \
      -type d -name .git -prune -o \
      \( \( -type f -o -type d \) -a -uid "${EXPECTED_UID}" -a -gid "${EXPECTED_GID}" -a ! -writable \) \
      -print0
  )

  mode_issues=()
  while IFS= read -r line; do
    [[ -n "${line}" ]] && mode_issues+=("${line}")
  done < <(
    find "${TARGET_REPO}" \
      -type d -name .git -prune -o \
      \( -type f -o -type d \) ! -writable \
      -printf '%M %u:%g %P\n' | sort
  )
fi

if [[ ${fixed} -gt 0 ]]; then
  echo "repo_permission_modes_fixed count=${fixed}"
fi

if [[ ${#ownership_issues[@]} -eq 0 && ${#mode_issues[@]} -eq 0 ]]; then
  echo "repo_permissions_ok"
  exit 0
fi

echo "repo_permissions_issues_detected"

if [[ ${#ownership_issues[@]} -gt 0 ]]; then
  echo "ownership_mismatch:"
  printf '  %s\n' "${ownership_issues[@]}"
fi

if [[ ${#mode_issues[@]} -gt 0 ]]; then
  echo "not_writable_by_current_user:"
  printf '  %s\n' "${mode_issues[@]}"
fi

cat <<EOF
expected_owner: ${EXPECTED_USER}:${EXPECTED_GROUP}
suggested_repair:
  sudo chown -R <intended-user>:<intended-group> ${TARGET_REPO}
  find ${TARGET_REPO} -type d -name .git -prune -o -type d ! -writable -exec chmod u+rwx {} +
  find ${TARGET_REPO} -type d -name .git -prune -o -type f ! -writable -exec chmod u+rw {} +
EOF

exit 1
