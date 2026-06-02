#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_REPO="${1:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"

# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

mapfile -t _AIAST_MANAGED_FILES < <(aiaast_print_managed_files "${TARGET_REPO}")
export _AIAST_MANAGED_FILES_CSV
_AIAST_MANAGED_FILES_CSV="$(printf '%s\n' "${_AIAST_MANAGED_FILES[@]}" | paste -sd, -)"

python3 - <<'PY' "${TARGET_REPO}" "${_AIAST_MANAGED_FILES_CSV}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
managed_csv = sys.argv[2] if len(sys.argv) > 2 else ""
managed_files = {item for item in managed_csv.split(",") if item}
manifest_path = repo / "_system" / "host-adapter-manifest.json"
issues: list[str] = []

if not manifest_path.is_file():
    print("agent_surface_integrity_failed")
    print("- missing _system/host-adapter-manifest.json")
    raise SystemExit(1)

manifest = json.loads(manifest_path.read_text())

required_docs = [
    "_system/AGENT_SURFACE_TAXONOMY.md",
    "_system/AGENT_INIT_CONVERGENCE.md",
    "_system/OPERATOR_PROMPTING_PLAYBOOK.md",
]
for rel in required_docs:
    if not (repo / rel).is_file():
        issues.append(f"missing required contract doc: {rel}")

required_placeholders = [str(item) for item in manifest.get("required_placeholder_files", [])]
for rel in sorted(set(required_placeholders)):
    if not (repo / rel).is_file():
        issues.append(f"missing required placeholder adapter: {rel}")
    elif managed_files and rel not in managed_files:
        issues.append(
            f"required placeholder adapter not registered as managed file: {rel} "
            "(add to aiaast_print_managed_files in bootstrap/lib/aiaast-lib.sh)"
        )

deprecated_aliases = manifest.get("deprecated_aliases", {})
if not isinstance(deprecated_aliases, dict):
    issues.append("deprecated_aliases must be an object in host-adapter-manifest.json")
else:
    for alias, rel in deprecated_aliases.items():
        if not str(alias).strip():
            issues.append("deprecated_aliases contains empty key")
        if isinstance(rel, str):
            if not rel.strip():
                issues.append(f"deprecated_aliases entry {alias!r} has empty target")
            continue
        if not isinstance(rel, dict):
            issues.append(f"deprecated_aliases entry {alias!r} must be string or object")
            continue
        for required_key in ("target", "deprecated_since", "remove_after", "migration_doc"):
            if not str(rel.get(required_key, "")).strip():
                issues.append(
                    f"deprecated_aliases entry {alias!r} missing required key: {required_key}"
                )

if issues:
    print("agent_surface_integrity_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("agent_surface_integrity_ok")
PY
