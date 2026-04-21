#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-bootstrap-permissions.sh [target-repo] [--fix]

Validate that all bootstrap/*.sh scripts are executable and readable.
With --fix, automatically repair missing execute permissions.

Exit codes:
  0  all permissions correct
  1  permission issues found (without --fix) or fix failed
EOF
}

TARGET_REPO=""
FIX=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix) FIX=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

BOOTSTRAP_DIR="${TARGET_REPO}/bootstrap"

if [[ ! -d "${BOOTSTRAP_DIR}" ]]; then
  echo "bootstrap/ directory not found in ${TARGET_REPO}" >&2
  exit 1
fi

issues=0
fixed=0

while IFS= read -r -d '' script; do
  rel="${script#"${TARGET_REPO}/"}"

  if [[ ! -r "${script}" ]]; then
    echo "[fail] ${rel}: not readable"
    issues=$((issues + 1))
    continue
  fi

  if [[ ! -x "${script}" ]]; then
    if [[ ${FIX} -eq 1 ]]; then
      chmod +x "${script}"
      echo "[fixed] ${rel}: added execute permission"
      fixed=$((fixed + 1))
    else
      echo "[fail] ${rel}: not executable (run with --fix to repair)"
      issues=$((issues + 1))
    fi
  fi
done < <(find "${BOOTSTRAP_DIR}" -name '*.sh' -type f -print0 | sort -z)

# Also check lib/*.sh if it exists
if [[ -d "${BOOTSTRAP_DIR}/lib" ]]; then
  while IFS= read -r -d '' script; do
    rel="${script#"${TARGET_REPO}/"}"
    if [[ ! -x "${script}" ]]; then
      if [[ ${FIX} -eq 1 ]]; then
        chmod +x "${script}"
        echo "[fixed] ${rel}: added execute permission"
        fixed=$((fixed + 1))
      else
        echo "[fail] ${rel}: not executable (run with --fix to repair)"
        issues=$((issues + 1))
      fi
    fi
  done < <(find "${BOOTSTRAP_DIR}/lib" -name '*.sh' -type f -print0 | sort -z)
fi

if [[ ${fixed} -gt 0 ]]; then
  echo "bootstrap_permissions_fixed count=${fixed}"
fi

if [[ ${issues} -gt 0 ]]; then
  echo "bootstrap_permissions_issues count=${issues}"
  exit 1
fi

echo "bootstrap_permissions_ok"
