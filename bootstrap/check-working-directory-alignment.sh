#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-working-directory-alignment.sh [repo-root] [--json] [--expected-target <name>]
EOF
}

REPO_ROOT=""
JSON_OUTPUT=0
EXPECTED_TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=1; shift ;;
    --expected-target) EXPECTED_TARGET="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then
        REPO_ROOT="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${REPO_ROOT}" ]]; then
  REPO_ROOT="$(pwd)"
fi

REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"
HOME_MYAPPZ="${HOME}/.MyAppZ"
REPO_NAME="$(basename -- "${REPO_ROOT}")"

UNDER_MYAPPZ=0
IN_TEMPLATE_REPO=0
MODE="out-of-bound"
STATUS="alignment_ok"
DETAILS=()

if [[ "${REPO_ROOT}" == "${HOME_MYAPPZ}"* ]]; then
  UNDER_MYAPPZ=1
  MODE="downstream-project"
fi

if [[ "${REPO_NAME}" == "_AI_AGENT_SYSTEM_TEMPLATE" ]]; then
  IN_TEMPLATE_REPO=1
  MODE="template-maintainer"
fi

if [[ "${REPO_ROOT}" == "${HOME_MYAPPZ}/_AI_AGENT_SYSTEM_TEMPLATE/TEMPLATE"* ]]; then
  IN_TEMPLATE_REPO=1
  MODE="template-maintainer"
fi

if [[ -n "${EXPECTED_TARGET}" && "${EXPECTED_TARGET}" != "${REPO_NAME}" ]]; then
  STATUS="alignment_fail"
  DETAILS+=("expected_target_mismatch:${EXPECTED_TARGET}!=$REPO_NAME")
fi

if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  python3 - <<'PY' "${STATUS}" "${REPO_ROOT}" "${REPO_NAME}" "${MODE}" "${UNDER_MYAPPZ}" "${IN_TEMPLATE_REPO}" "$(IFS=,; echo "${DETAILS[*]:-none}")"
import json, sys
print(json.dumps({
  "status": sys.argv[1],
  "repo_root": sys.argv[2],
  "repo_name": sys.argv[3],
  "mode": sys.argv[4],
  "under_myappz": sys.argv[5] == "1",
  "in_template_repo": sys.argv[6] == "1",
  "details": [] if sys.argv[7] == "none" else sys.argv[7].split(",")
}, indent=2))
PY
else
  echo "${STATUS}"
  echo "repo_root=${REPO_ROOT}"
  echo "repo_name=${REPO_NAME}"
  echo "mode=${MODE}"
  echo "under_myappz=${UNDER_MYAPPZ}"
  echo "in_template_repo=${IN_TEMPLATE_REPO}"
  if [[ ${#DETAILS[@]} -gt 0 ]]; then
    printf 'details=%s\n' "$(IFS=,; echo "${DETAILS[*]}")"
  fi
fi

if [[ "${STATUS}" == "alignment_fail" ]]; then
  exit 1
fi
