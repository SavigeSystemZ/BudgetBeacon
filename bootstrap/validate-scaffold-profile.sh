#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 3 ]]; then
  echo "usage: $0 <target-repo> --profile <name> [--json]"
  exit 2
fi
repo="$1"; shift
profile=""
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="$2"; shift 2 ;;
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-scaffold-profile.sh" "validation"
      else
        echo "unknown arg: $1"
      fi
      exit 2 ;;
  esac
done
if [[ -z "$profile" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "invalid_argument" "profile required" "validate-scaffold-profile.sh" "validation"
  else
    echo "profile required"
  fi
  exit 2
fi
matrix="${repo}/_system/SCAFFOLD_PROFILE_MATRIX.md"
aiaast_require_file "$matrix"
if ! rg -F --quiet -- "\`${profile}\`" "$matrix"; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "profile_not_declared" "profile not declared: $profile" "validate-scaffold-profile.sh" "validation"
  else
    echo "profile not declared: $profile"
  fi
  exit 1
fi
manifest="$(aiaast_scaffold_profile_manifest_path "${repo}")" || {
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing scaffold profile manifest" "validate-scaffold-profile.sh" "validation"
  [[ "$json_mode" -eq 0 ]] && echo "missing scaffold profile manifest"
  exit 1
}
aiaast_require_file "$manifest"
python3 - "$manifest" "$profile" <<'PY'
import json, sys
manifest, profile = sys.argv[1:]
with open(manifest, "r", encoding="utf-8") as f:
    data = json.load(f)
profiles = data.get("profiles", [])
required_root = {"version", "profiles"}
if not required_root.issubset(set(data.keys())):
    raise SystemExit(1)
for item in profiles:
    if item.get("id") != profile:
        continue
    required = {"id", "installable", "maintainer_only", "downstream_mutable"}
    if not required.issubset(item):
        raise SystemExit(1)
    raise SystemExit(0)
raise SystemExit(1)
PY
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "$(python3 - "$profile" <<'PY'
import json, sys
print(json.dumps({"profile": sys.argv[1]}))
PY
)" "validate-scaffold-profile.sh" "validation"
else
  echo "scaffold profile validation: PASS ($profile)"
fi
