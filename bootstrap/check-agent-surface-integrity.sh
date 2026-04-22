#!/usr/bin/env bash
set -euo pipefail

TARGET_REPO="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

python3 - <<'PY' "${TARGET_REPO}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
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
