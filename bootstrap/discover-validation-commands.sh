#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--json]"
  exit 2
fi
repo="$1"; shift || true
json_mode=0
[[ "${1:-}" == "--json" ]] && json_mode=1

has_file() { [[ -f "$1" ]] && echo found || echo missing; }

format="$(has_file "${repo}/pyproject.toml")"
lint="$(has_file "${repo}/pyproject.toml")"
typecheck="$(has_file "${repo}/pyproject.toml")"
test="$(has_file "${repo}/TEST_STRATEGY.md")"
build="$(has_file "${repo}/packaging/README.md")"
security="$(has_file "${repo}/bootstrap/scan-security.sh")"
install_smoke="$(has_file "${repo}/bootstrap/check-runtime-foundations.sh")"
launch_render="not_applicable"

payload="$(cat <<EOF
{"format":"$format","lint":"$lint","typecheck":"$typecheck","test":"$test","build":"$build","security_audit":"$security","install_smoke":"$install_smoke","launch_render":"$launch_render","commands":["validate-system.sh --strict","aiast-cli check-awareness","check-runtime-foundations.sh","check-network-bindings.sh"]}
EOF
)"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "$payload" "discover-validation-commands.sh" "validation"
else
  echo "$payload"
fi
