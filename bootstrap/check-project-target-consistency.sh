#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-project-target-consistency.sh [repo-root] [--expected-target <name>] [--json]
EOF
}

REPO_ROOT=""
EXPECTED_TARGET=""
JSON_OUTPUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --expected-target) EXPECTED_TARGET="${2:-}"; shift 2 ;;
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then
        REPO_ROOT="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${REPO_ROOT}" ]]; then
  REPO_ROOT="$(pwd)"
fi
REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"
REPO_NAME="$(basename -- "${REPO_ROOT}")"

normalize_name() {
  python3 - <<'PY' "${1:-}"
import re
import sys

raw = (sys.argv[1] or "").strip().lower()
normalized = re.sub(r"[^a-z0-9]+", "-", raw)
normalized = re.sub(r"-+", "-", normalized).strip("-")
print(normalized)
PY
}

STATUS="target_consistency_ok"
WARNINGS=()
FAILURES=()

if [[ -n "${EXPECTED_TARGET}" && "${EXPECTED_TARGET}" != "${REPO_NAME}" ]]; then
  FAILURES+=("expected_target_mismatch:${EXPECTED_TARGET}!=$REPO_NAME")
fi

if [[ -f "${REPO_ROOT}/.git/config" ]]; then
  remote_url="$(git -C "${REPO_ROOT}" remote get-url origin 2>/dev/null || true)"
  if [[ -n "${remote_url}" ]]; then
    remote_base="${remote_url##*/}"
    remote_base="${remote_base%.git}"
    if [[ "${remote_base}" != "${REPO_NAME}" ]]; then
      WARNINGS+=("remote_repo_name_differs:${remote_base}!=$REPO_NAME")
    fi
  fi
fi

profile="${REPO_ROOT}/_system/PROJECT_PROFILE.md"
if [[ -f "${profile}" ]]; then
  app_name="$(python3 - <<'PY' "${profile}"
import re, sys
text=open(sys.argv[1]).read()
m=re.search(r"^- App name:[ \t]*(.*?)\s*$", text, re.M)
print((m.group(1).strip() if m else ""))
PY
)"
  if [[ -n "${app_name}" ]]; then
    normalized_app_name="$(normalize_name "${app_name}")"
    normalized_repo_name="$(normalize_name "${REPO_NAME}")"
  else
    normalized_app_name=""
    normalized_repo_name="$(normalize_name "${REPO_NAME}")"
  fi
  if [[ -n "${app_name}" && "${normalized_app_name}" != "${normalized_repo_name}" ]]; then
    WARNINGS+=("project_profile_app_name_differs:${app_name}!=$REPO_NAME")
  fi
fi

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  STATUS="target_consistency_fail"
elif [[ ${#WARNINGS[@]} -gt 0 ]]; then
  STATUS="target_consistency_warn"
fi

if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  python3 - <<'PY' "${STATUS}" "${REPO_ROOT}" "${REPO_NAME}" "$(IFS=,; echo "${WARNINGS[*]:-none}")" "$(IFS=,; echo "${FAILURES[*]:-none}")"
import json, sys
def parse(v): return [] if v == "none" else v.split(",")
print(json.dumps({
  "status": sys.argv[1],
  "repo_root": sys.argv[2],
  "repo_name": sys.argv[3],
  "warnings": parse(sys.argv[4]),
  "failures": parse(sys.argv[5]),
}, indent=2))
PY
else
  echo "${STATUS}"
  if [[ ${#WARNINGS[@]} -gt 0 ]]; then printf 'warnings=%s\n' "$(IFS=,; echo "${WARNINGS[*]}")"; fi
  if [[ ${#FAILURES[@]} -gt 0 ]]; then printf 'failures=%s\n' "$(IFS=,; echo "${FAILURES[*]}")"; fi
fi

[[ "${STATUS}" != "target_consistency_fail" ]]
