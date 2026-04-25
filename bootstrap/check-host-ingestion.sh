#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export AIAAST_DEFAULT_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    default_repo = Path(os.environ["AIAAST_DEFAULT_REPO"])
    parser = argparse.ArgumentParser(
        description="Validate host-safe prompt emission surfaces and the canonical prompt emitter."
    )
    parser.add_argument("target_repo", nargs="?", default=str(default_repo))
    return parser.parse_args()


args = parse_args()
repo = Path(args.target_repo).resolve()
issues: list[str] = []

required_files = [
    "_system/PROMPT_EMISSION_CONTRACT.md",
    "_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md",
    "_system/repo-operating-profile.json",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/PROMPTS_INDEX.md",
    "bootstrap/emit-host-prompt.sh",
    "bootstrap/check-host-ingestion.sh",
]
for rel in required_files:
    if not (repo / rel).is_file():
        issues.append(f"Missing required host-ingestion surface: {rel}")

contract_path = repo / "_system" / "PROMPT_EMISSION_CONTRACT.md"
profile_path = repo / "_system" / "repo-operating-profile.json"
if issues:
    print("host_ingestion_validation_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

contract_text = contract_path.read_text()
profile = json.loads(profile_path.read_text())
match = re.search(r"`(Load AGENTS\.md[^`]+)`", contract_text)
if not match:
    issues.append("Prompt emission contract is missing the canonical startup preamble.")
    startup_preamble = ""
else:
    startup_preamble = match.group(1).strip()

expected_startup_files = [
    "AGENTS.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/LOAD_ORDER.md",
]
canonical = set(profile.get("canonical_instruction_files", []))
for rel in expected_startup_files:
    if rel not in canonical and rel not in set(profile.get("load_order_anchor", [])):
        issues.append(f"Operating profile does not surface startup file: {rel}")

prompts_index_text = (repo / "_system" / "PROMPTS_INDEX.md").read_text()
for needle in ("_system/PROMPT_EMISSION_CONTRACT.md", "bootstrap/emit-host-prompt.sh"):
    if needle not in prompts_index_text:
        issues.append(f"_system/PROMPTS_INDEX.md is missing required host-emission mention: {needle}")

prompt_files = list((repo / "_system" / "prompt-templates").glob("*.md"))
prompt_files += list((repo / "_system" / "prompt-packs").glob("*.md"))
for path in prompt_files:
    text = path.read_text()
    for rel in expected_startup_files:
        if rel not in text:
            issues.append(f"{path.relative_to(repo)} is missing startup reference: {rel}")
    if "orchestration context only" not in text:
        issues.append(f"{path.relative_to(repo)} is missing orchestration-context wording")
    if "repo-local" not in text:
        issues.append(f"{path.relative_to(repo)} is missing repo-local authority wording")
    if "only source of truth" in text:
        issues.append(f"{path.relative_to(repo)} contains forbidden host-authority wording")

text_output = subprocess.run(
    [
        "bash",
        str(repo / "bootstrap" / "emit-host-prompt.sh"),
        str(repo),
        "--task",
        "Validate host prompt assembly",
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
if text_output.returncode != 0:
    issues.append(f"emit-host-prompt.sh text mode failed: {(text_output.stderr or text_output.stdout).strip()}")
else:
    body = text_output.stdout
    if not body.startswith(startup_preamble):
        issues.append("emit-host-prompt.sh text output does not start with the contract startup preamble")
    for needle in (
        "Task objective:",
        "Scope:",
        "Required repo-local files beyond the startup preamble:",
        "Constraints and validation:",
        "Deliverables:",
        "`_system/PROJECT_PROFILE.md`",
        "`WHERE_LEFT_OFF.md`",
        "Validation: bootstrap/validate-system.sh <repo> --strict",
    ):
        if needle not in body:
            issues.append(f"emit-host-prompt.sh text output is missing: {needle}")

json_output = subprocess.run(
    [
        "bash",
        str(repo / "bootstrap" / "emit-host-prompt.sh"),
        str(repo),
        "--format",
        "json",
        "--task",
        "Validate host prompt assembly",
        "--scope",
        "Instruction-layer proof",
        "--read",
        "_system/PROJECT_PROFILE.md",
        "--validation",
        "bootstrap/validate-system.sh <repo> --strict",
    ],
    cwd=repo,
    text=True,
    capture_output=True,
)
if json_output.returncode != 0:
    issues.append(f"emit-host-prompt.sh json mode failed: {(json_output.stderr or json_output.stdout).strip()}")
else:
    try:
        payload = json.loads(json_output.stdout)
    except Exception as exc:  # noqa: BLE001
        issues.append(f"emit-host-prompt.sh json output is invalid JSON: {exc}")
    else:
        if payload.get("startup_preamble") != startup_preamble:
            issues.append("emit-host-prompt.sh json startup_preamble does not match the contract")
        if payload.get("startup_files") != expected_startup_files:
            issues.append("emit-host-prompt.sh json startup_files do not match the required startup files")
        if "_system/PROJECT_PROFILE.md" not in payload.get("required_repo_local_files", []):
            issues.append("emit-host-prompt.sh json required_repo_local_files is missing _system/PROJECT_PROFILE.md")
        if payload.get("contract_path") != "_system/PROMPT_EMISSION_CONTRACT.md":
            issues.append("emit-host-prompt.sh json contract_path is incorrect")

if issues:
    print("host_ingestion_validation_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("host_ingestion_ok")
PY
