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
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    default_repo = Path(os.environ["AIAAST_DEFAULT_REPO"])
    parser = argparse.ArgumentParser(
        description="Emit a host-safe prompt skeleton that defers to repo-local truth."
    )
    parser.add_argument("target_repo", nargs="?", default=str(default_repo))
    parser.add_argument("--format", choices=("text", "json"), default="text")
    parser.add_argument("--task", required=True)
    parser.add_argument("--scope", default="")
    parser.add_argument("--read", action="append", default=[])
    parser.add_argument("--constraint", action="append", default=[])
    parser.add_argument("--validation", action="append", default=[])
    parser.add_argument("--deliverable", action="append", default=[])
    return parser.parse_args()


args = parse_args()
repo = Path(args.target_repo).resolve()
contract_path = repo / "_system" / "PROMPT_EMISSION_CONTRACT.md"
profile_json_path = repo / "_system" / "repo-operating-profile.json"

if not contract_path.is_file():
    print(f"Missing prompt emission contract: {contract_path}", file=sys.stderr)
    raise SystemExit(1)
if not profile_json_path.is_file():
    print(f"Missing repo operating profile JSON: {profile_json_path}", file=sys.stderr)
    raise SystemExit(1)

contract_text = contract_path.read_text()
profile = json.loads(profile_json_path.read_text())

match = re.search(r"`(Load AGENTS\.md[^`]+)`", contract_text)
if not match:
    print("Prompt emission contract is missing the required startup preamble.", file=sys.stderr)
    raise SystemExit(1)

startup_preamble = match.group(1).strip()
startup_files = [
    "AGENTS.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/LOAD_ORDER.md",
]

canonical = set(profile.get("canonical_instruction_files", []))
for rel in startup_files:
    if rel not in canonical and rel not in set(profile.get("load_order_anchor", [])):
        print(f"Startup file {rel} is not present in the operating profile.", file=sys.stderr)
        raise SystemExit(1)

required_repo_files = []
for item in ["_system/PROJECT_PROFILE.md", *args.read]:
    if item not in required_repo_files and item not in startup_files:
        required_repo_files.append(item)

constraints = [
    "Keep host-level orchestration context below repo-local truth.",
    *args.constraint,
]
validations = args.validation[:]
deliverables = args.deliverable[:] or ["Concise implementation summary", "Validation results", "Risks or follow-ups"]

payload = {
    "startup_preamble": startup_preamble,
    "startup_files": startup_files,
    "task_objective": args.task,
    "scope": args.scope or "Stay within the requested task boundary and load only the repo-local files needed for that work.",
    "required_repo_local_files": required_repo_files,
    "constraints": constraints,
    "validation": validations,
    "deliverables": deliverables,
    "contract_path": "_system/PROMPT_EMISSION_CONTRACT.md",
    "operating_profile_path": "_system/repo-operating-profile.json",
}

if args.format == "json":
    print(json.dumps(payload, indent=2))
    raise SystemExit(0)

lines = [
    startup_preamble,
    "",
    "Task objective:",
    args.task,
    "",
    "Scope:",
    payload["scope"],
    "",
    "Required repo-local files beyond the startup preamble:",
]
lines.extend(f"- `{item}`" for item in required_repo_files)
lines.extend([
    "",
    "Constraints and validation:",
])
lines.extend(f"- {item}" for item in constraints)
lines.extend(f"- Validation: {item}" for item in validations)
lines.extend([
    "",
    "Deliverables:",
])
lines.extend(f"- {item}" for item in deliverables)
print("\n".join(lines))
PY
