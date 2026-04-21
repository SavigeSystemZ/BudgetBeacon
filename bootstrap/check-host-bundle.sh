#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: check-host-bundle.sh [target-repo] [--validator-root <template-root>]

Validate the exported host-bundle contract and the canonical host-bundle emitter.
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
  TARGET_REPO="${DEFAULT_REPO}"
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

if [[ ! -f "${VALIDATOR_ROOT}/bootstrap/check-host-ingestion.sh" ]]; then
  echo "Validator root is missing check-host-ingestion.sh: ${VALIDATOR_ROOT}" >&2
  exit 1
fi

exec python3 - <<'PY' "${TARGET_REPO}" "${VALIDATOR_ROOT}"
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
validator_root = Path(sys.argv[2]).resolve()
issues: list[str] = []

required_files = [
    "_system/HOST_BUNDLE_CONTRACT.md",
    "_system/PROMPT_EMISSION_CONTRACT.md",
    "_system/repo-operating-profile.json",
    "_system/aiaast-capabilities.json",
    "_system/PROMPTS_INDEX.md",
    "_system/CONTEXT_INDEX.md",
    "_system/README.md",
    "bootstrap/README.md",
    "bootstrap/emit-host-prompt.sh",
    "bootstrap/check-host-ingestion.sh",
    "bootstrap/emit-host-bundle.sh",
    "bootstrap/check-host-bundle.sh",
]
for rel in required_files:
    if not (repo / rel).is_file():
        issues.append(f"Missing required host-bundle surface: {rel}")

if issues:
    print("host_bundle_validation_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

docs_to_scan = {
    repo / "_system" / "HOST_BUNDLE_CONTRACT.md": [
        "bootstrap/emit-host-bundle.sh",
        "bootstrap/check-host-bundle.sh",
        "_system/PROMPT_EMISSION_CONTRACT.md",
    ],
    repo / "_system" / "PROMPTS_INDEX.md": [
        "_system/HOST_BUNDLE_CONTRACT.md",
        "bootstrap/emit-host-bundle.sh",
        "bootstrap/check-host-bundle.sh",
    ],
    repo / "_system" / "CONTEXT_INDEX.md": [
        "HOST_BUNDLE_CONTRACT.md",
        "emit-host-bundle.sh",
        "check-host-bundle.sh",
    ],
    repo / "_system" / "README.md": [
        "HOST_BUNDLE_CONTRACT.md",
    ],
    repo / "bootstrap" / "README.md": [
        "emit-host-bundle.sh",
        "check-host-bundle.sh",
    ],
}
for path, required in docs_to_scan.items():
    text = path.read_text()
    for needle in required:
        if needle not in text:
            issues.append(f"{path.relative_to(repo)} is missing required mention: {needle}")

check_ingestion = subprocess.run(
    ["bash", str(validator_root / "bootstrap" / "check-host-ingestion.sh"), str(repo)],
    cwd=repo,
    text=True,
    capture_output=True,
)
if check_ingestion.returncode != 0:
    issues.append(
        "check-host-ingestion.sh failed before host-bundle validation: "
        + (check_ingestion.stderr or check_ingestion.stdout).strip()
    )

expected_startup_files = [
    "AGENTS.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/LOAD_ORDER.md",
]

stdout_result = subprocess.run(
    [
        "bash",
        str(repo / "bootstrap" / "emit-host-bundle.sh"),
        str(repo),
        "--task",
        "Validate host bundle assembly",
        "--scope",
        "Instruction-layer proof",
        "--read",
        "_system/PROJECT_PROFILE.md",
        "--read",
        "WHERE_LEFT_OFF.md",
        "--constraint",
        "Keep repo-local truth authoritative.",
        "--validation",
        "bootstrap/validate-system.sh <repo> --strict",
        "--deliverable",
        "Short summary of files loaded and validation plan",
    ],
    cwd=repo,
    text=True,
    capture_output=True,
)
if stdout_result.returncode != 0:
    issues.append(f"emit-host-bundle.sh stdout mode failed: {(stdout_result.stderr or stdout_result.stdout).strip()}")
    bundle = {}
else:
    try:
        bundle = json.loads(stdout_result.stdout)
    except Exception as exc:  # noqa: BLE001
        issues.append(f"emit-host-bundle.sh stdout output is invalid JSON: {exc}")
        bundle = {}

with tempfile.TemporaryDirectory(prefix="aiaast-host-bundle-check.") as temp_dir:
    bundle_path = Path(temp_dir) / "bundle.json"
    file_result = subprocess.run(
        [
            "bash",
            str(repo / "bootstrap" / "emit-host-bundle.sh"),
            str(repo),
            "--task",
            "Validate host bundle assembly",
            "--scope",
            "Instruction-layer proof",
            "--read",
            "_system/PROJECT_PROFILE.md",
            "--output",
            str(bundle_path),
        ],
        cwd=repo,
        text=True,
        capture_output=True,
    )
    if file_result.returncode != 0:
        issues.append(f"emit-host-bundle.sh file mode failed: {(file_result.stderr or file_result.stdout).strip()}")
    elif not bundle_path.is_file():
        issues.append("emit-host-bundle.sh file mode did not write the requested output path")
    else:
        try:
            json.loads(bundle_path.read_text())
        except Exception as exc:  # noqa: BLE001
            issues.append(f"emit-host-bundle.sh file mode wrote invalid JSON: {exc}")

if bundle:
    if bundle.get("kind") != "aiaast-host-bundle":
        issues.append("emit-host-bundle.sh kind is incorrect")
    if bundle.get("schema_version") != "1.0.0":
        issues.append("emit-host-bundle.sh schema_version is incorrect")
    if bundle.get("bundle_contract_path") != "_system/HOST_BUNDLE_CONTRACT.md":
        issues.append("emit-host-bundle.sh bundle_contract_path is incorrect")
    if bundle.get("prompt_emission_contract_path") != "_system/PROMPT_EMISSION_CONTRACT.md":
        issues.append("emit-host-bundle.sh prompt_emission_contract_path is incorrect")
    authority = bundle.get("authority", {})
    if authority.get("host_context_policy") != "orchestration-context-only":
        issues.append("emit-host-bundle.sh authority.host_context_policy is incorrect")
    prompt_payload = bundle.get("prompt_payload", {})
    if prompt_payload.get("startup_files") != expected_startup_files:
        issues.append("emit-host-bundle.sh prompt_payload.startup_files do not match the required startup files")
    load_sequence = bundle.get("load_sequence", [])
    if load_sequence[: len(expected_startup_files)] != expected_startup_files:
        issues.append("emit-host-bundle.sh load_sequence does not start with the required startup files")
    included_files = bundle.get("included_files", [])
    included_paths = [item.get("path") for item in included_files if isinstance(item, dict)]
    if included_paths != load_sequence:
        issues.append("emit-host-bundle.sh included_files order does not match load_sequence")
    if "_system/PROJECT_PROFILE.md" not in load_sequence:
        issues.append("emit-host-bundle.sh load_sequence is missing _system/PROJECT_PROFILE.md")
    if "WHERE_LEFT_OFF.md" not in load_sequence:
        issues.append("emit-host-bundle.sh load_sequence is missing WHERE_LEFT_OFF.md")
    prompt_text = bundle.get("prompt_text", "")
    startup_preamble = prompt_payload.get("startup_preamble", "")
    if not isinstance(prompt_text, str) or not prompt_text.startswith(startup_preamble):
        issues.append("emit-host-bundle.sh prompt_text does not begin with the startup preamble")
    for entry in included_files:
        if not isinstance(entry, dict):
            issues.append("emit-host-bundle.sh included_files contains a non-object entry")
            continue
        rel = str(entry.get("path", ""))
        if not rel or Path(rel).is_absolute():
            issues.append(f"emit-host-bundle.sh included_files contains an invalid path: {rel}")
            continue
        content = entry.get("content")
        if not isinstance(content, str):
            issues.append(f"emit-host-bundle.sh included_files is missing content for: {rel}")
            continue
        sha = hashlib.sha256(content.encode("utf-8")).hexdigest()
        if entry.get("sha256") != sha:
            issues.append(f"emit-host-bundle.sh sha256 mismatch for: {rel}")
        if entry.get("line_count") != len(content.splitlines()):
            issues.append(f"emit-host-bundle.sh line_count mismatch for: {rel}")
        if entry.get("byte_count") != len(content.encode('utf-8')):
            issues.append(f"emit-host-bundle.sh byte_count mismatch for: {rel}")

capabilities = json.loads((repo / "_system" / "aiaast-capabilities.json").read_text())
markers = capabilities.get("markers", {})
for key in ("host_bundle_contract", "host_bundle_emitter", "host_bundle_validator"):
    if not str(markers.get(key, "")).strip():
        issues.append(f"_system/aiaast-capabilities.json is missing marker: {key}")

if issues:
    print("host_bundle_validation_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("host_bundle_ok")
PY
