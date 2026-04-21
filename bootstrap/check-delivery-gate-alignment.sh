#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-delivery-gate-alignment.sh [target-repo] [--strict]

Validate that delivery-gate and contract surfaces are present and discoverable
through core index/load/prompt docs.
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_REPO=""
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=1
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

must_exist=(
  "_system/DELIVERY_GATES.md"
  "_system/AI_RULES.md"
  "_system/REPO_CONVENTIONS.md"
  "_system/SECURITY_BASELINE.md"
  "_system/REQUEST_ALIGNMENT_PROTOCOL.md"
  "_system/AUTONOMOUS_GUARDRAILS_PROTOCOL.md"
)

for rel in "${must_exist[@]}"; do
  if [[ ! -f "${TARGET_REPO}/${rel}" ]]; then
    echo "Missing delivery-gate surface: ${rel}" >&2
    exit 1
  fi
done

index_file="${TARGET_REPO}/_system/CONTEXT_INDEX.md"
load_file="${TARGET_REPO}/_system/LOAD_ORDER.md"
prompt_file="${TARGET_REPO}/_system/MASTER_SYSTEM_PROMPT.md"

for req in "${index_file}" "${load_file}" "${prompt_file}"; do
  if [[ ! -f "${req}" ]]; then
    echo "Missing required documentation surface: ${req}" >&2
    exit 1
  fi
done

index_tokens=(
  "DELIVERY_GATES.md"
  "AI_RULES.md"
  "REPO_CONVENTIONS.md"
  "SECURITY_BASELINE.md"
  "REQUEST_ALIGNMENT_PROTOCOL.md"
  "AUTONOMOUS_GUARDRAILS_PROTOCOL.md"
)

for token in "${index_tokens[@]}"; do
  if ! rg -n "${token}" "${index_file}" >/dev/null 2>&1; then
    echo "Context index missing required reference: ${token}" >&2
    exit 1
  fi
done

load_tokens=(
  "DELIVERY_GATES.md"
  "AI_RULES.md"
  "REPO_CONVENTIONS.md"
  "SECURITY_BASELINE.md"
  "REQUEST_ALIGNMENT_PROTOCOL.md"
  "AUTONOMOUS_GUARDRAILS_PROTOCOL.md"
)

for token in "${load_tokens[@]}"; do
  if ! rg -n "${token}" "${load_file}" >/dev/null 2>&1; then
    echo "Load order missing required reference: ${token}" >&2
    exit 1
  fi
done

if ! rg -n 'REQUEST_ALIGNMENT_PROTOCOL\.md' "${prompt_file}" >/dev/null 2>&1; then
  echo "Master system prompt missing request-alignment reference." >&2
  exit 1
fi

if ! rg -n 'install-autonomous-guardrails\.sh' "${prompt_file}" >/dev/null 2>&1; then
  echo "Master system prompt missing autonomous guardrails install reference." >&2
  exit 1
fi

if [[ ${STRICT} -eq 1 ]]; then
  if ! rg -n '^## (Per-milestone checklist|Validation mapping|Security checks|Evidence requirement)' "${TARGET_REPO}/_system/DELIVERY_GATES.md" >/dev/null 2>&1; then
    echo "Strict mode: DELIVERY_GATES.md appears malformed (expected section headings missing)." >&2
    exit 1
  fi
fi

echo "delivery_gate_alignment_ok"
