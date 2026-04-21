#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LIB_PATH="${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ ! -f "${LIB_PATH}" ]]; then
  echo "Missing integrity helper library: ${LIB_PATH}" >&2
  exit 1
fi
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${LIB_PATH}"

usage() {
  cat <<'EOF'
Usage: verify-integrity.sh [--generate|--check] [--target <dir>] [--list-failed]

Options:
  --generate      Generate a new INTEGRITY_MANIFEST.sha256 based on template-managed files.
  --check         Verify files against the existing INTEGRITY_MANIFEST.sha256.
  --target        Directory to operate on (default: root of the template/repo).
  --list-failed   When used with --check, print only the files that failed verification.
EOF
}

MODE=""
TARGET_DIR=""
MANIFEST_REL="_system/INTEGRITY_MANIFEST.sha256"
LIST_FAILED=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --generate)
      MODE="generate"
      shift
      ;;
    --check)
      MODE="check"
      shift
      ;;
    --target)
      TARGET_DIR="${2:-}"
      shift 2
      ;;
    --list-failed)
      LIST_FAILED=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "${MODE}" ]]; then
  usage
  exit 1
fi

if [[ -z "${TARGET_DIR}" ]]; then
  if [[ "$(basename "${SCRIPT_DIR}")" == "bootstrap" ]]; then
    TARGET_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
  else
    TARGET_DIR="$(pwd)"
  fi
fi

if [[ "${MODE}" == "generate" ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

cd "${TARGET_DIR}"
MANIFEST_PATH="${MANIFEST_REL}"

if [[ "${MODE}" == "generate" ]]; then
  echo "Generating integrity manifest for ${TARGET_DIR}..."
  mkdir -p "$(dirname "${MANIFEST_PATH}")"
  : > "${MANIFEST_PATH}"
  while IFS= read -r rel; do
    sha256sum "${rel}"
  done < <(aiaast_list_manifest_files "$(pwd)") > "${MANIFEST_PATH}"
  echo "Manifest generated at ${MANIFEST_PATH}"
  exit 0
fi

if [[ ! -f "${MANIFEST_PATH}" ]]; then
  echo "Error: Manifest not found at ${MANIFEST_PATH}" >&2
  exit 1
fi

set +e
check_output="$(sha256sum -c "${MANIFEST_PATH}" 2>&1)"
check_status=$?
set -e

if [[ ${LIST_FAILED} -eq 1 ]]; then
  printf '%s\n' "${check_output}" | awk '/FAILED$/ {sub(/: FAILED$/, "", $0); sub(/^\.\//, "", $0); print}'
  exit ${check_status}
fi

echo "Verifying integrity of ${TARGET_DIR}..."
printf '%s\n' "${check_output}"
if [[ ${check_status} -ne 0 ]]; then
  exit ${check_status}
fi
echo "Integrity check passed!"
