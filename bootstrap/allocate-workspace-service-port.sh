#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 2 ]]; then
  echo "usage: $0 <target-repo> <service-name> [--apply] [--json]"
  exit 2
fi
repo="$1"; service="$2"; shift 2 || true
apply=0; json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "allocate-workspace-service-port.sh" "port-allocation"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

port="$(python3 - <<'PY'
import random
print(random.randint(20000, 45000))
PY
)"
sink="${AIAST_WORKSPACE_SERVICE_REGISTRY:-$HOME/.MyAppZ/_AIAST_SHARED/workspace-service-registry.yaml}"
entry="${service}: ${port}"

if [[ "$apply" -eq 1 ]]; then
  mkdir -p "$(dirname "$sink")"
  printf "%s\n" "$entry" >> "$sink"
fi

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"service\":\"${service}\",\"port\":${port},\"sink\":\"${sink}\"}" "allocate-workspace-service-port.sh" "$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run)"
else
  echo "workspace_port_allocated service=${service} port=${port} mode=$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run)"
fi
