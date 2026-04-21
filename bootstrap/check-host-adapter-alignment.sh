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
  "_system/host-adapter-manifest.json"
  "bootstrap/generate-host-adapters.sh"
  "bootstrap/check-host-adapter-alignment.sh"
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
        "bootstrap/generate-host-adapters.sh",
        "bootstrap/check-host-adapter-alignment.sh",
    ],
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md": [
        "_system/HOST_ADAPTER_POLICY.md",
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
