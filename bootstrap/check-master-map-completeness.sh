#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo>"
  exit 2
fi

target="$1"
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "check-master-map-completeness.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2
      ;;
  esac
done
map_file="${target}/_system/SUPER_TEMPLATE_MASTER_MAP.md"
registry="${target}/_system/SYSTEM_REGISTRY.json"

[[ -f "$map_file" ]] || {
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_file" "missing: $map_file" "check-master-map-completeness.sh" "validation"
  else
    echo "missing: $map_file"
  fi
  exit 1
}
[[ -f "$registry" ]] || {
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_file" "missing: $registry" "check-master-map-completeness.sh" "validation"
  else
    echo "missing: $registry"
  fi
  exit 1
}

missing=0
total=0
while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  total=$((total + 1))
  if ! rg -F --quiet -- "$path" "$map_file"; then
    if [[ "$json_mode" -eq 1 ]]; then
      echo "missing in master map: $path" >&2
    else
      echo "missing in master map: $path"
    fi
    missing=1
  fi
done < <(python3 - "$registry" <<'PY'
import json, sys
with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)
entries = data.get("entries")
if isinstance(entries, list):
    for item in entries:
        if isinstance(item, dict):
            path = str(item.get("path", "")).strip()
            if path:
                print(path)
else:
    for p in data.get("files", []):
        path = str(p).strip()
        if path:
            print(path)
PY
)

if [[ "$total" -eq 0 ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "empty_registry" "system registry has zero managed entries" "check-master-map-completeness.sh" "validation"
  else
    echo "system registry has zero managed entries"
  fi
  exit 1
fi

if ! rg -N --quiet -- "^- Managed file count: [1-9][0-9]*" "$map_file"; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "invalid_managed_count" "master map managed file count is zero or missing" "check-master-map-completeness.sh" "validation"
  else
    echo "master map managed file count is zero or missing"
  fi
  exit 1
fi

if [[ "$missing" -ne 0 ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "master_map_incomplete" "master map completeness check failed" "check-master-map-completeness.sh" "validation"
  else
    echo "master map completeness check: FAIL"
  fi
  exit 1
fi

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass"}' "check-master-map-completeness.sh" "validation"
else
  echo "master map completeness check: PASS"
fi

