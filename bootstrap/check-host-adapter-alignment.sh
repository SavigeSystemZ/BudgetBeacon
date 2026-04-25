#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: check-host-adapter-alignment.sh [target-repo] [--validator-root <template-root>]

Validate that generated tool-adapter surfaces remain aligned with the canonical host-adapter manifest.
EOF
}

TARGET_REPO=""
VALIDATOR_ROOT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validator-root)
      VALIDATOR_ROOT="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ -z "${VALIDATOR_ROOT}" ]]; then
  VALIDATOR_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
else
  VALIDATOR_ROOT="$(cd -- "${VALIDATOR_ROOT}" && pwd)"
fi

if [[ ! -f "${VALIDATOR_ROOT}/bootstrap/generate-host-adapters.sh" ]]; then
  echo "Validator root is missing generate-host-adapters.sh: ${VALIDATOR_ROOT}" >&2
  exit 1
fi

required_files=(
  "_system/HOST_ADAPTER_POLICY.md"
  "_system/AGENT_SURFACE_TAXONOMY.md"
  "_system/AGENT_INIT_CONVERGENCE.md"
  "_system/host-adapter-manifest.json"
  "_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md"
  "_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md"
  "_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md"
  "bootstrap/generate-host-adapters.sh"
  "bootstrap/check-host-adapter-alignment.sh"
  "bootstrap/emit-session-environment.sh"
)

for rel in "${required_files[@]}"; do
  if [[ ! -f "${TARGET_REPO}/${rel}" ]]; then
    echo "Missing required host-adapter file: ${rel}" >&2
    exit 1
  fi
done

jq -e . "${TARGET_REPO}/_system/host-adapter-manifest.json" >/dev/null 2>&1 || {
  echo "Invalid JSON: _system/host-adapter-manifest.json" >&2
  exit 1
}

bash "${VALIDATOR_ROOT}/bootstrap/generate-host-adapters.sh" "${TARGET_REPO}" --check >/dev/null

python3 - <<'PY' "${TARGET_REPO}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
manifest = json.loads((repo / "_system" / "host-adapter-manifest.json").read_text())
issues: list[str] = []

docs_to_scan = {
    repo / "AGENTS.md": [
        "_system/HOST_ADAPTER_POLICY.md",
        "_system/AGENT_SURFACE_TAXONOMY.md",
        "_system/AGENT_INIT_CONVERGENCE.md",
        "bootstrap/generate-host-adapters.sh",
        "bootstrap/check-host-adapter-alignment.sh",
    ],
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md": [
        "_system/HOST_ADAPTER_POLICY.md",
        "_system/AGENT_SURFACE_TAXONOMY.md",
        "_system/AGENT_INIT_CONVERGENCE.md",
        "bootstrap/generate-host-adapters.sh",
        "bootstrap/check-host-adapter-alignment.sh",
    ],
    repo / "_system" / "CONTEXT_INDEX.md": [
        "HOST_ADAPTER_POLICY.md",
        "host-adapter-manifest.json",
        "generate-host-adapters.sh",
        "check-host-adapter-alignment.sh",
    ],
    repo / "_system" / "SYSTEM_EVOLUTION_POLICY.md": [
        "HOST_ADAPTER_POLICY.md",
        "generate-host-adapters.sh",
    ],
    repo / "bootstrap" / "README.md": [
        "generate-host-adapters.sh",
        "check-host-adapter-alignment.sh",
    ],
}

for path, required in docs_to_scan.items():
    if not path.is_file():
        issues.append(f"Missing doc for host-adapter scan: {path.relative_to(repo)}")
        continue
    text = path.read_text()
    for needle in required:
        if needle not in text:
            issues.append(f"{path.relative_to(repo)} is missing required mention: {needle}")

generated = manifest.get("generated_adapters", {})
tool_paths = {str(spec["path"]) for spec in generated.values()}
for rel in sorted(tool_paths):
    if not (repo / rel).is_file():
        issues.append(f"Manifest references missing generated host adapter: {rel}")

required_placeholders = manifest.get("required_placeholder_files", [])
for rel in sorted(set(str(item) for item in required_placeholders)):
    if not (repo / rel).is_file():
        issues.append(f"Missing required placeholder adapter: {rel}")


def parse_version(value: str) -> tuple[int, ...]:
    cleaned = str(value).strip().lstrip("vV")
    if not cleaned:
        return tuple()
    parts: list[int] = []
    for piece in cleaned.split("."):
        if not piece.isdigit():
            return tuple()
        parts.append(int(piece))
    return tuple(parts)


template_version = ""
version_path = repo / "_system" / ".template-version"
if version_path.is_file():
    template_version = version_path.read_text().strip()
template_version_tuple = parse_version(template_version)

deprecated_aliases = manifest.get("deprecated_aliases", {})
if not isinstance(deprecated_aliases, dict):
    issues.append("deprecated_aliases must be an object in host-adapter-manifest.json")
else:
    for alias, entry in deprecated_aliases.items():
        if not str(alias).strip():
            issues.append("deprecated_aliases contains empty key")
        if isinstance(entry, str):
            if not entry.strip():
                issues.append(f"deprecated_aliases entry {alias!r} has empty target")
            continue
        if not isinstance(entry, dict):
            issues.append(f"deprecated_aliases entry {alias!r} must be a string or object")
            continue

        target = str(entry.get("target", "")).strip()
        deprecated_since = str(entry.get("deprecated_since", "")).strip()
        remove_after = str(entry.get("remove_after", "")).strip()
        migration_doc = str(entry.get("migration_doc", "")).strip()
        if not target:
            issues.append(f"deprecated_aliases entry {alias!r} is missing target")
        if not deprecated_since:
            issues.append(f"deprecated_aliases entry {alias!r} is missing deprecated_since")
        if not remove_after:
            issues.append(f"deprecated_aliases entry {alias!r} is missing remove_after")
        if not migration_doc:
            issues.append(f"deprecated_aliases entry {alias!r} is missing migration_doc")
        elif not (repo / migration_doc).is_file():
            issues.append(
                f"deprecated_aliases entry {alias!r} migration_doc does not exist: {migration_doc}"
            )

        deprecated_tuple = parse_version(deprecated_since)
        remove_after_tuple = parse_version(remove_after)
        if deprecated_since and not deprecated_tuple:
            issues.append(
                f"deprecated_aliases entry {alias!r} has invalid deprecated_since: {deprecated_since}"
            )
        if remove_after and not remove_after_tuple:
            issues.append(
                f"deprecated_aliases entry {alias!r} has invalid remove_after: {remove_after}"
            )
        if deprecated_tuple and remove_after_tuple and remove_after_tuple <= deprecated_tuple:
            issues.append(
                f"deprecated_aliases entry {alias!r} remove_after must be greater than deprecated_since"
            )
        if template_version_tuple and remove_after_tuple and template_version_tuple >= remove_after_tuple:
            issues.append(
                f"deprecated_aliases entry {alias!r} expired at {remove_after}; remove alias or extend window"
            )

profile_json = repo / "_system" / "repo-operating-profile.json"
if profile_json.is_file():
    payload = json.loads(profile_json.read_text())
    host_ingestion = payload.get("host_ingestion", {})
    for key in ("host_adapter_generator", "host_adapter_validator", "host_adapter_manifest"):
        if not str(host_ingestion.get(key, "")).strip():
            issues.append(f"repo-operating-profile.json host_ingestion is missing {key}")

if issues:
    print("host_adapter_alignment_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("host_adapter_alignment_ok")
PY
