#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--json]"
  exit 2
fi
repo="$1"
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-archetype-packs.sh" "validation"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

matrix="${repo}/_system/APP_ARCHETYPE_ROUTING_MATRIX.md"
dir="${repo}/_system/archetypes"
manifest="${repo}/_system/archetypes/archetype-manifest.json"

for f in "$matrix" "$manifest"; do
  if ! aiaast_require_file "$f"; then
    [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing: $f" "validate-archetype-packs.sh" "validation"
    exit 1
  fi
done
if ! aiaast_require_dir "$dir"; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_dir" "missing: $dir" "validate-archetype-packs.sh" "validation"
  exit 1
fi

py_out_file="$(mktemp)"
if ! python3 - "$manifest" "$matrix" "$dir" >"${py_out_file}" <<'PY'
import json, sys, pathlib
manifest_path, matrix_path, dir_path = sys.argv[1:]
manifest = json.load(open(manifest_path, "r", encoding="utf-8"))
matrix = open(matrix_path, "r", encoding="utf-8").read()
required_headers = [
    "## App purpose",
    "## Required docs",
    "## Required runtime surfaces",
    "## Recommended stack options",
    "## Security/privacy posture",
    "## Installer expectations",
    "## Port policy",
    "## Validation gates",
    "## UI/UX completion requirements",
    "## Fleet roles",
    "## Prompt-pack hooks",
    "## Benchmark/test-app scenario",
    "## Anti-patterns",
]
expanded_required = {
    "_system/archetypes/web-saas.md",
    "_system/archetypes/local-first-desktop.md",
    "_system/archetypes/mobile-apk.md",
    "_system/archetypes/fullstack-marketplace.md",
    "_system/archetypes/ai-agent-app.md",
    "_system/archetypes/data-dashboard.md",
    "_system/archetypes/cybersecurity-tool.md",
    "_system/archetypes/evidence-reporting-app.md",
    "_system/archetypes/background-check-or-osint-app.md",
    "_system/archetypes/finance-budgeting-app.md",
    "_system/archetypes/home-property-management-app.md",
    "_system/archetypes/metasystem-reviewer-app.md",
}
for entry in manifest.get("archetypes", []):
    doc = entry.get("doc")
    if not doc:
        raise SystemExit("manifest entry missing doc")
    path = pathlib.Path(pathlib.Path(manifest_path).parents[2], doc)
    if not path.is_file():
        raise SystemExit(f"missing archetype doc: {doc}")
    text = path.read_text(encoding="utf-8")
    if doc in expanded_required:
        for h in required_headers:
            if h not in text:
                raise SystemExit(f"{doc} missing header: {h}")
    if doc in expanded_required and doc not in matrix:
        raise SystemExit(f"matrix missing reference: {doc}")
print(json.dumps({"checked": len(manifest.get("archetypes", []))}))
PY
then
  [[ "$json_mode" -eq 1 ]] && cat "${py_out_file}" >&2
  rm -f "${py_out_file}"
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "archetype_pack_invalid" "archetype pack validation failed" "validate-archetype-packs.sh" "validation"
  [[ "$json_mode" -eq 0 ]] && echo "archetype packs validation: FAIL"
  exit 1
fi
if [[ "$json_mode" -eq 0 ]]; then
  cat "${py_out_file}"
fi
rm -f "${py_out_file}"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass"}' "validate-archetype-packs.sh" "validation"
else
  echo "archetype packs validation: PASS"
fi
