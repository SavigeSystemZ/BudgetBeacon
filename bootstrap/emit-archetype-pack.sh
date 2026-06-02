#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"
if [[ $# -lt 3 ]]; then
  echo "usage: $0 <target-repo> --archetype <name> [--dry-run] [--json]"
  exit 2
fi
repo="$1"; shift
archetype=""
dry_run=0
json_mode=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archetype) archetype="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      if [[ "$json_mode" -eq 1 ]]; then
        aiaast_json_error "invalid_argument" "unknown arg: $1" "emit-archetype-pack.sh" "emit"
      else
        echo "unknown arg: $1"
      fi
      exit 2 ;;
  esac
done
file="${repo}/_system/archetypes/${archetype}.md"
if [[ -z "$archetype" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "invalid_argument" "archetype required" "emit-archetype-pack.sh" "emit"
  else
    echo "archetype required"
  fi
  exit 2
fi
if ! aiaast_require_file "$file"; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_archetype_doc" "missing archetype doc: $file" "emit-archetype-pack.sh" "emit"
  fi
  exit 1
fi
manifest="${repo}/_system/archetypes/archetype-manifest.json"
if ! aiaast_require_file "$manifest"; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_manifest" "missing archetype manifest: $manifest" "emit-archetype-pack.sh" "emit"
  fi
  exit 1
fi
if ! python3 - "$manifest" "$archetype" <<'PY'
import json, sys
manifest, archetype = sys.argv[1:]
with open(manifest, "r", encoding="utf-8") as f:
    data = json.load(f)
known = {a.get("id") for a in data.get("archetypes", [])}
raise SystemExit(0 if archetype in known else 1)
PY
then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "unknown_archetype" "archetype not declared in manifest: $archetype" "emit-archetype-pack.sh" "emit"
  else
    echo "archetype not declared in manifest: $archetype"
  fi
  exit 1
fi
if [[ "$dry_run" -eq 1 ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "$(python3 - "$archetype" <<'PY'
import json, sys
print(json.dumps({"mode": "dry-run", "archetype": sys.argv[1]}))
PY
)" "emit-archetype-pack.sh" "emit"
  else
    echo "would emit archetype pack for: $archetype"
  fi
else
  echo "archetype: ${archetype}" > "${repo}/_system/runtime-profiles/ACTIVE_ARCHETYPE.txt"
  refreshed=()
  if [[ -x "${repo}/bootstrap/generate-system-registry.sh" ]]; then
    bash "${repo}/bootstrap/generate-system-registry.sh" "${repo}" --write >/dev/null
    refreshed+=("_system/SYSTEM_REGISTRY.json")
  fi
  if [[ -x "${repo}/bootstrap/verify-integrity.sh" ]]; then
    bash "${repo}/bootstrap/verify-integrity.sh" --generate --target "${repo}" >/dev/null
    refreshed+=("_system/INTEGRITY_MANIFEST.sha256")
  fi
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "$(python3 - "$archetype" "$(IFS=,; echo "${refreshed[*]}")" <<'PY'
import json, sys
refreshed = [item for item in sys.argv[2].split(",") if item]
print(json.dumps({
    "mode": "write",
    "archetype": sys.argv[1],
    "output": "_system/runtime-profiles/ACTIVE_ARCHETYPE.txt",
    "refreshed": refreshed,
}))
PY
)" "emit-archetype-pack.sh" "emit"
  else
    echo "emitted archetype pack: $archetype"
  fi
fi
