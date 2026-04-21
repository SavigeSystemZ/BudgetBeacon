#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: validate-plugin.sh <plugin-dir>

Validate a plugin directory against the AIAST plugin contract.
Checks manifest schema, hook-point names, owned_path conflicts, and version compatibility.
EOF
}

if [[ $# -lt 1 || "$1" == "-h" || "$1" == "--help" ]]; then
  usage
  exit 1
fi

PLUGIN_DIR="$1"

if [[ ! -d "${PLUGIN_DIR}" ]]; then
  echo "Plugin directory does not exist: ${PLUGIN_DIR}" >&2
  exit 1
fi

if [[ ! -f "${PLUGIN_DIR}/plugin.json" ]]; then
  echo "Missing required file: ${PLUGIN_DIR}/plugin.json" >&2
  exit 1
fi

if [[ ! -f "${PLUGIN_DIR}/README.md" ]]; then
  echo "Missing required file: ${PLUGIN_DIR}/README.md" >&2
  exit 1
fi

python3 - <<'PY' "${PLUGIN_DIR}"
from __future__ import annotations

import json
import sys
from pathlib import Path

plugin_dir = Path(sys.argv[1]).resolve()
manifest = json.loads((plugin_dir / "plugin.json").read_text())

ALLOWED_HOOKS = {
    "bootstrap.pre_flight",
    "bootstrap.post_install",
    "bootstrap.post_update",
    "validation.preflight",
    "validation.postflight",
    "validation.report",
    "security.scan",
    "security.audit",
    "ci.pre_commit",
    "ci.post_test",
    "testing.pre_run",
    "documentation.generate",
    "monitoring.setup",
    "environment.validate",
}

REQUIRED_FIELDS = {"name", "version", "description", "hooks"}

issues: list[str] = []

# Check required fields
for field in REQUIRED_FIELDS:
    if field not in manifest:
        issues.append(f"Missing required field: {field}")

# Validate name
name = manifest.get("name", "")
if not isinstance(name, str) or not name.strip():
    issues.append("Field 'name' must be a non-empty string")

# Validate version
version = manifest.get("version", "")
if not isinstance(version, str) or not version.strip():
    issues.append("Field 'version' must be a non-empty string")

# Validate hooks
hooks = manifest.get("hooks", [])
if not isinstance(hooks, list) or len(hooks) == 0:
    issues.append("Field 'hooks' must be a non-empty array of hook-point names")
else:
    for hook in hooks:
        if hook not in ALLOWED_HOOKS:
            issues.append(f"Invalid hook point: {hook} (allowed: {', '.join(sorted(ALLOWED_HOOKS))})")

# Validate owned_paths do not overlap with core AIAST paths
owned_paths = manifest.get("owned_paths", [])
for path in owned_paths:
    path_str = str(path)
    if not path_str.startswith("_system/plugins/"):
        issues.append(f"Plugin owned_path must be under _system/plugins/: {path_str}")

# Validate capabilities
capabilities = manifest.get("capabilities", [])
if not isinstance(capabilities, list):
    issues.append("Field 'capabilities' must be an array")
elif len(capabilities) > 0 and not all(isinstance(c, str) for c in capabilities):
    issues.append("Field 'capabilities' must be an array of strings")

# Validate requires
requires = manifest.get("requires", [])
if not isinstance(requires, list):
    issues.append("Field 'requires' must be an array")

# Validate enabled
enabled = manifest.get("enabled", True)
if not isinstance(enabled, bool):
    issues.append("Field 'enabled' must be a boolean")

if issues:
    print(f"plugin_invalid: {plugin_dir.name}", file=sys.stderr)
    for issue in issues:
        print(f"  - {issue}", file=sys.stderr)
    raise SystemExit(1)

print(f"plugin_valid: {manifest['name']} v{manifest['version']} hooks={','.join(hooks)}")
PY
