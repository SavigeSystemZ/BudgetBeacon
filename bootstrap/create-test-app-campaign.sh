#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--root PATH] [--apply] [--json]"
  exit 2
fi
repo="$1"; shift || true
root="${HOME}/.MyAppZ/_AIAST_TEST_APPS"
apply=0
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) root="${2:-}"; shift 2 ;;
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "create-test-app-campaign.sh" "campaign"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

apps=(
  "AIAST-Test-WebSaaS"
  "AIAST-Test-LocalDesktop"
  "AIAST-Test-CLI"
  "AIAST-Test-MobileAPK"
  "AIAST-Test-FullstackDB"
  "AIAST-Test-AIAgentApp"
  "AIAST-Test-CyberTool"
  "AIAST-Test-EvidenceReporting"
  "AIAST-Test-MetasystemReviewer"
)

if [[ "$apply" -eq 1 ]]; then
  mkdir -p "$root"
  for app in "${apps[@]}"; do
    mkdir -p "${root}/${app}"
    printf "name: %s\nsource_template: %s\n" "$app" "$repo" > "${root}/${app}/campaign.yml"
  done
fi

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"root\":\"${root}\",\"count\":${#apps[@]}}" "create-test-app-campaign.sh" "$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run)"
else
  echo "test_app_campaign_ok mode=$([[ "$apply" -eq 1 ]] && echo apply || echo dry-run) root=${root}"
fi
