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

# ---- S22b WS10: signed integrity manifest --------------------------------
# Tamper-evidence for the manifest itself. Without this, anyone/anything
# that rewrites INTEGRITY_MANIFEST.sha256 (or regenerates it after editing
# a managed file) passes `--check` silently. We HMAC the manifest with a
# per-repo seed that lives under _system/agent-state/ (already gitignored,
# never propagated, leak-guarded) — a genuine local secret. Editing the
# manifest without the seed yields a signature mismatch.
SIG_PATH="${MANIFEST_PATH}.sig"
SEED_PATH="_system/agent-state/integrity/seed"

_integrity_seed_ensure() {  # create the per-repo seed if absent
  if [[ ! -f "${SEED_PATH}" ]]; then
    mkdir -p "$(dirname "${SEED_PATH}")"
    openssl rand -base64 32 > "${SEED_PATH}"
    chmod 600 "${SEED_PATH}" 2>/dev/null || true
  fi
}

_integrity_hmac() {  # $1=manifest -> hex hmac (stdout), keyed by the seed
  openssl dgst -sha256 -hmac "$(cat "${SEED_PATH}")" "$1" 2>/dev/null \
    | sed 's/^.*= //'
}

_integrity_sign() {
  _integrity_seed_ensure
  _integrity_hmac "${MANIFEST_PATH}" > "${SIG_PATH}"
}

# rc 0 = signature valid OR unsigned (back-compat advisory);
# rc 3 = signature MISMATCH (tamper-evident hard failure).
_integrity_verify_sig() {
  if [[ ! -f "${SEED_PATH}" || ! -f "${SIG_PATH}" ]]; then
    echo "integrity_signature: unsigned (no seed/sig — run --generate to sign)"
    return 0
  fi
  local want have
  want="$(cat "${SIG_PATH}")"
  have="$(_integrity_hmac "${MANIFEST_PATH}")"
  if [[ -n "${want}" && "${want}" == "${have}" ]]; then
    echo "integrity_signature: valid"
    return 0
  fi
  echo "integrity_signature: MISMATCH (manifest tampered or re-signed without the repo seed)" >&2
  bash "${SCRIPT_DIR}/emit-bleed-event.sh" \
    --severity high --type integrity-signature-mismatch \
    --summary "INTEGRITY_MANIFEST.sha256 signature mismatch in ${TARGET_DIR}" \
    >/dev/null 2>&1 || true
  return 3
}

if [[ "${MODE}" == "generate" ]]; then
  echo "Generating integrity manifest for ${TARGET_DIR}..."
  mkdir -p "$(dirname "${MANIFEST_PATH}")"
  : > "${MANIFEST_PATH}"
  while IFS= read -r rel; do
    sha256sum "${rel}"
  done < <(aiaast_list_manifest_files "$(pwd)") > "${MANIFEST_PATH}"
  echo "Manifest generated at ${MANIFEST_PATH}"
  _integrity_sign
  echo "Manifest signed at ${SIG_PATH}"
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

# sha256sum -c exits 0 when only some lines are malformed alongside valid ones;
# treat any "improperly formatted" warning as a hard failure so manifest tampering
# (e.g. truncated or rewritten lines) does not silently pass.
if printf '%s\n' "${check_output}" | grep -qE 'improperly formatted|no properly formatted checksum lines found'; then
  if [[ ${check_status} -eq 0 ]]; then
    check_status=1
  fi
fi

if [[ ${LIST_FAILED} -eq 1 ]]; then
  printf '%s\n' "${check_output}" | awk '/FAILED$/ {sub(/: FAILED$/, "", $0); sub(/^\.\//, "", $0); print}'
  printf '%s\n' "${check_output}" | grep -E 'improperly formatted|no properly formatted checksum lines found' >&2 || true
  exit ${check_status}
fi

echo "Verifying integrity of ${TARGET_DIR}..."
printf '%s\n' "${check_output}"
if [[ ${check_status} -ne 0 ]]; then
  exit ${check_status}
fi
# Manifest content verified — now verify the manifest itself is untampered.
set +e
_integrity_verify_sig
sig_status=$?
set -e
if [[ ${sig_status} -ne 0 ]]; then
  exit ${sig_status}
fi
echo "Integrity check passed!"
