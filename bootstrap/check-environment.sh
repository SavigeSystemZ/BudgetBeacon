#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-environment.sh <target-repo> [--json]

Validate runtime environment prerequisites based on the project profile.
Checks: required CLI tools, port availability, disk space, env vars.
EOF
}

TARGET=""
JSON_OUTPUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET}" ]]; then
        TARGET="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  usage; exit 1
fi

PROFILE="${TARGET}/_system/PROJECT_PROFILE.md"
WARN_COUNT=0
FAIL_COUNT=0
RESULTS=()

add_result() {
  local check="$1" status="$2" detail="$3"
  RESULTS+=("{\"check\":\"${check}\",\"status\":\"${status}\",\"detail\":\"${detail}\"}")
  if [[ "${status}" == "warn" ]]; then ((WARN_COUNT++)) || true; fi
  if [[ "${status}" == "fail" ]]; then ((FAIL_COUNT++)) || true; fi
  if [[ ${JSON_OUTPUT} -eq 0 ]]; then
    printf "  [%s] %s: %s\n" "${status}" "${check}" "${detail}"
  fi
}

# 1. Check disk space (minimum 500MB free)
if [[ ${JSON_OUTPUT} -eq 0 ]]; then echo "Checking disk space..."; fi
FREE_KB=$(df --output=avail "${TARGET}" 2>/dev/null | tail -1 | tr -d ' ' || echo "0")
if [[ ${FREE_KB} -gt 512000 ]]; then
  add_result "disk_space" "pass" "$((FREE_KB / 1024))MB free"
else
  add_result "disk_space" "warn" "Low disk space: $((FREE_KB / 1024))MB free (recommend >500MB)"
fi

# 2. Check common CLI tools
if [[ ${JSON_OUTPUT} -eq 0 ]]; then echo "Checking CLI tools..."; fi
COMMON_TOOLS=(git bash python3 jq)
for tool in "${COMMON_TOOLS[@]}"; do
  if command -v "${tool}" >/dev/null 2>&1; then
    add_result "tool_${tool}" "pass" "$(command -v "${tool}")"
  else
    add_result "tool_${tool}" "fail" "not found in PATH"
  fi
done

# 3. Check stack-specific tools from profile
if [[ -f "${PROFILE}" ]]; then
  # Detect languages from profile
  for lang_tool in node npm npx python3 pip uv cargo rustc go flutter dart java mvn gradle dotnet; do
    if grep -qi "${lang_tool}" "${PROFILE}" 2>/dev/null; then
      if command -v "${lang_tool}" >/dev/null 2>&1; then
        add_result "tool_${lang_tool}" "pass" "found"
      else
        add_result "tool_${lang_tool}" "warn" "referenced in profile but not found"
      fi
    fi
  done
fi

# 4. Check port availability for common development ports
if [[ ${JSON_OUTPUT} -eq 0 ]]; then echo "Checking port availability..."; fi
if [[ -f "${PROFILE}" ]]; then
  while IFS= read -r port; do
    port=$(echo "${port}" | tr -dc '0-9')
    if [[ -n "${port}" && "${port}" -gt 0 && "${port}" -lt 65536 ]]; then
      if ss -tlnp 2>/dev/null | grep -q ":${port} " 2>/dev/null; then
        add_result "port_${port}" "warn" "port ${port} already in use"
      else
        add_result "port_${port}" "pass" "port ${port} available"
      fi
    fi
  done < <(grep -oP '(?:port|Port|PORT)[:\s]*\K\d+' "${PROFILE}" 2>/dev/null || true)
fi

# 5. Check env file
ENV_EXAMPLE="${TARGET}/ops/env/.env.example"
if [[ -f "${ENV_EXAMPLE}" ]]; then
  add_result "env_example" "pass" "ops/env/.env.example exists"
  if grep -q '^PUBLISH_REDIS_PORT=false$' "${ENV_EXAMPLE}" 2>/dev/null; then
    add_result "redis_publish_default" "pass" "redis host publishing disabled by default"
  else
    add_result "redis_publish_default" "warn" "ops/env/.env.example missing PUBLISH_REDIS_PORT=false"
  fi
  if grep -q '^PUBLISH_POSTGRES_PORT=false$' "${ENV_EXAMPLE}" 2>/dev/null; then
    add_result "postgres_publish_default" "pass" "postgres host publishing disabled by default"
  else
    add_result "postgres_publish_default" "warn" "ops/env/.env.example missing PUBLISH_POSTGRES_PORT=false"
  fi
else
  # Also check generated runtime foundations
  ENV_ALT="${TARGET}/bootstrap/templates/runtime/ops/env/.env.example"
  if [[ -f "${ENV_ALT}" ]]; then
    add_result "env_example" "pass" "template env example exists"
  fi
fi

TOOLS_CHECK="${TARGET}/tools/check-port-collisions.py"
if [[ -f "${TOOLS_CHECK}" ]]; then
  if python3 "${TOOLS_CHECK}" "${TARGET}" >/dev/null 2>&1; then
    add_result "port_registry" "pass" "port registry has no collisions"
  else
    add_result "port_registry" "warn" "port registry check reported collisions or invalid data"
  fi
fi

GOV_FILE="${TARGET}/registry/port_governance.yaml"
LIB_FILE="${TARGET}/tools/port_registry_lib.py"
if [[ -f "${GOV_FILE}" ]]; then
  if [[ -f "${LIB_FILE}" ]]; then
    add_result "port_governance_tooling" "pass" "port governance files paired with tools/port_registry_lib.py"
  else
    add_result "port_governance_tooling" "warn" "registry/port_governance.yaml present without tools/port_registry_lib.py"
  fi
fi

PREFLIGHT="${TARGET}/tools/preflight_port_scan.py"
if [[ -f "${PREFLIGHT}" && -f "${GOV_FILE}" ]]; then
  if python3 "${PREFLIGHT}" "${TARGET}" >/dev/null 2>&1; then
    add_result "port_preflight" "pass" "preflight_port_scan reports binds available"
  else
    add_result "port_preflight" "warn" "preflight_port_scan reported bind conflicts or errors"
  fi
fi

# Output
if [[ ${JSON_OUTPUT} -eq 1 ]]; then
  printf '{"checks":[%s],"warnings":%d,"failures":%d}\n' \
    "$(IFS=,; echo "${RESULTS[*]}")" "${WARN_COUNT}" "${FAIL_COUNT}"
else
  echo ""
  if [[ ${FAIL_COUNT} -gt 0 ]]; then
    echo "environment_check: ${FAIL_COUNT} failure(s), ${WARN_COUNT} warning(s)"
    exit 1
  elif [[ ${WARN_COUNT} -gt 0 ]]; then
    echo "environment_check: ${WARN_COUNT} warning(s), 0 failures"
  else
    echo "environment_check: all checks passed"
  fi
fi
