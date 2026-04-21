#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: discover-plugins.sh <target-repo> [--json]

Scan _system/plugins/ for installed plugins and report their status.
Generates _system/CAPABILITY_MATRIX.json for agent discovery.
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
  usage
  exit 1
fi

PLUGINS_DIR="${TARGET}/_system/plugins"
MATRIX_FILE="${TARGET}/_system/CAPABILITY_MATRIX.json"

if [[ ! -d "${PLUGINS_DIR}" ]]; then
  if [[ ${JSON_OUTPUT} -eq 1 ]]; then
    echo '{"plugins":[],"count":0,"capabilities":{}}'
  else
    echo "No plugins directory found."
  fi
  exit 0
fi

python3 - <<'PY' "${PLUGINS_DIR}" "${JSON_OUTPUT}" "${MATRIX_FILE}"
from __future__ import annotations

import json
import sys
from pathlib import Path

plugins_dir = Path(sys.argv[1]).resolve()
json_output = sys.argv[2] == "1"
matrix_file = Path(sys.argv[3]).resolve()

plugins: list[dict] = []
capability_matrix: dict[str, list[str]] = {}

for plugin_json in sorted(plugins_dir.glob("*/plugin.json")):
    try:
        manifest = json.loads(plugin_json.read_text())
        has_runner = (plugin_json.parent / "run.sh").is_file()
        has_readme = (plugin_json.parent / "README.md").is_file()
        
        plugin_rel_path = str(plugin_json.parent.relative_to(plugins_dir.parent.parent))
        
        plugin_info = {
            "name": manifest.get("name", plugin_json.parent.name),
            "version": manifest.get("version", "unknown"),
            "description": manifest.get("description", ""),
            "hooks": manifest.get("hooks", []),
            "capabilities": manifest.get("capabilities", []),
            "enabled": manifest.get("enabled", True),
            "has_runner": has_runner,
            "has_readme": has_readme,
            "path": plugin_rel_path,
        }
        plugins.append(plugin_info)
        
        if plugin_info["enabled"] and has_runner:
            for cap in plugin_info["capabilities"]:
                if cap not in capability_matrix:
                    capability_matrix[cap] = []
                capability_matrix[cap].append(f"{plugin_rel_path}/run.sh")
                
    except Exception as exc:
        plugins.append({
            "name": plugin_json.parent.name,
            "version": "error",
            "description": f"Failed to parse: {exc}",
            "hooks": [],
            "enabled": False,
            "has_runner": False,
            "has_readme": False,
            "path": str(plugin_json.parent.relative_to(plugins_dir.parent.parent)),
        })

# Write the capability matrix
matrix_data = {
    "generated_at": str(Path("/dev/null").stat().st_mtime), # Placeholder, actual timestamp handled by shell if needed or just use current
    "capabilities": capability_matrix
}
matrix_file.write_text(json.dumps(matrix_data, indent=2) + "\n")

if json_output:
    print(json.dumps({"plugins": plugins, "count": len(plugins), "capabilities": capability_matrix}, indent=2))
else:
    if not plugins:
        print("No plugins found.")
    else:
        print(f"Discovered {len(plugins)} plugin(s):\n")
        for p in plugins:
            status = "enabled" if p["enabled"] else "disabled"
            runner = "executable" if p["has_runner"] else "metadata-only"
            print(f"  {p['name']} v{p['version']} [{status}, {runner}]")
            print(f"    {p['description']}")
            print(f"    Hooks: {', '.join(p['hooks']) if p['hooks'] else 'none'}")
            print(f"    Capabilities: {', '.join(p['capabilities']) if p['capabilities'] else 'none'}")
            print(f"    Path:  {p['path']}")
            print()
    print(f"plugins_discovered: {len(plugins)}")
    print(f"capability_matrix_updated: {matrix_file}")
PY
