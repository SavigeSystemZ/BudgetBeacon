#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--source PATH] [--json]"
  exit 2
fi
repo="$1"; shift || true
source_path="${HOME}/.MyAppZ"
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_path="${2:-}"; shift 2 ;;
    --json) json_mode=1; shift ;;
    *) exit 2 ;;
  esac
done

out="${repo}/_META_AGENT_SYSTEM/evidence/HARVEST_SURFACE_REPORT_$(date -u +%Y-%m-%d).md"
mkdir -p "$(dirname "$out")"
{
  echo "# Harvest Surface Report"
  echo "- source: ${source_path}"
  echo "- mode: read-only"
  echo "- note: secrets/tokens/app-specific private data excluded by policy"
} > "$out"

if [[ "$json_mode" -eq 1 ]]; then
  printf '{"ok":true,"script":"harvest-agent-surfaces.sh","mode":"harvest","result":{"output":"%s"}}\n' "$out"
else
  echo "harvest_agent_surfaces_ok output=${out}"
fi
