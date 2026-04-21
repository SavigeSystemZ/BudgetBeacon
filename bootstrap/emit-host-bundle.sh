#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export AIAAST_DEFAULT_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

exec python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import subprocess
import sys
from pathlib import Path


def parse_args() -> argparse.Namespace:
    default_repo = Path(os.environ["AIAAST_DEFAULT_REPO"])
    parser = argparse.ArgumentParser(
        description="Emit a self-contained host bundle for external consumers that cannot read repo-local paths directly."
    )
    parser.add_argument("target_repo", nargs="?", default=str(default_repo))
    parser.add_argument("--task", required=True)
    parser.add_argument("--scope", default="")
    parser.add_argument("--read", action="append", default=[])
    parser.add_argument("--constraint", action="append", default=[])
    parser.add_argument("--validation", action="append", default=[])
    parser.add_argument("--deliverable", action="append", default=[])
    parser.add_argument("--output", default="-")
    parser.add_argument("--max-bytes-per-file", type=int, default=200_000)
    return parser.parse_args()


args = parse_args()
repo = Path(args.target_repo).resolve()
bundle_contract_path = repo / "_system" / "HOST_BUNDLE_CONTRACT.md"
prompt_contract_path = repo / "_system" / "PROMPT_EMISSION_CONTRACT.md"
capabilities_path = repo / "_system" / "aiaast-capabilities.json"
emit_prompt_path = repo / "bootstrap" / "emit-host-prompt.sh"

for path in (bundle_contract_path, prompt_contract_path, capabilities_path, emit_prompt_path):
    if not path.is_file():
        print(f"Missing required bundle surface: {path}", file=sys.stderr)
        raise SystemExit(1)

if args.max_bytes_per_file <= 0:
    print("--max-bytes-per-file must be positive.", file=sys.stderr)
    raise SystemExit(1)

cmd_base = [
    "bash",
    str(emit_prompt_path),
    str(repo),
    "--task",
    args.task,
]

if args.scope:
    cmd_base.extend(["--scope", args.scope])
for item in args.read:
    cmd_base.extend(["--read", item])
for item in args.constraint:
    cmd_base.extend(["--constraint", item])
for item in args.validation:
    cmd_base.extend(["--validation", item])
for item in args.deliverable:
    cmd_base.extend(["--deliverable", item])

json_result = subprocess.run(
    [*cmd_base, "--format", "json"],
    cwd=repo,
    text=True,
    capture_output=True,
)
if json_result.returncode != 0:
    print(json_result.stderr or json_result.stdout, file=sys.stderr)
    raise SystemExit(1)

text_result = subprocess.run(
    cmd_base,
    cwd=repo,
    text=True,
    capture_output=True,
)
if text_result.returncode != 0:
    print(text_result.stderr or text_result.stdout, file=sys.stderr)
    raise SystemExit(1)

prompt_payload = json.loads(json_result.stdout)
capabilities = json.loads(capabilities_path.read_text())

startup_files = prompt_payload.get("startup_files", [])
required_files = prompt_payload.get("required_repo_local_files", [])
if not isinstance(startup_files, list) or not startup_files:
    print("Prompt payload is missing startup_files.", file=sys.stderr)
    raise SystemExit(1)
if not isinstance(required_files, list):
    print("Prompt payload is missing required_repo_local_files.", file=sys.stderr)
    raise SystemExit(1)

load_sequence: list[str] = []
for rel in [*startup_files, *required_files]:
    rel_path = Path(rel)
    if rel_path.is_absolute():
        print(f"Absolute path not allowed in host bundle: {rel}", file=sys.stderr)
        raise SystemExit(1)
    normalized = rel_path.as_posix()
    if normalized not in load_sequence:
        load_sequence.append(normalized)

included_files: list[dict[str, object]] = []
for rel in load_sequence:
    path = repo / rel
    if not path.is_file():
        print(f"Missing file requested for host bundle: {rel}", file=sys.stderr)
        raise SystemExit(1)
    text = path.read_text()
    byte_count = len(text.encode("utf-8"))
    if byte_count > args.max_bytes_per_file:
        print(
            f"Host bundle file exceeds max size ({args.max_bytes_per_file} bytes): {rel}",
            file=sys.stderr,
        )
        raise SystemExit(1)
    included_files.append(
        {
            "path": rel,
            "load_phase": "startup" if rel in startup_files else "required",
            "sha256": hashlib.sha256(text.encode("utf-8")).hexdigest(),
            "line_count": len(text.splitlines()),
            "byte_count": byte_count,
            "content": text,
        }
    )

bundle = {
    "schema_version": "1.0.0",
    "kind": "aiaast-host-bundle",
    "template_name": capabilities.get("template_name", "AIAST"),
    "template_version": capabilities.get("template_version", "unknown"),
    "bundle_contract_path": "_system/HOST_BUNDLE_CONTRACT.md",
    "prompt_emission_contract_path": prompt_payload.get("contract_path", "_system/PROMPT_EMISSION_CONTRACT.md"),
    "operating_profile_path": prompt_payload.get("operating_profile_path", "_system/repo-operating-profile.json"),
    "authority": {
        "host_context_policy": "orchestration-context-only",
        "repo_local_truth_rule": "If this bundle conflicts with the live repo-local files, follow the live repo-local files and report the conflict.",
        "precedence_contract_path": "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
        "runtime_system_boundary": "Runtime code must remain independent from _system/.",
    },
    "prompt_payload": prompt_payload,
    "prompt_text": text_result.stdout,
    "load_sequence": load_sequence,
    "included_files": included_files,
}

payload = json.dumps(bundle, indent=2) + "\n"
if args.output == "-" or not args.output:
    print(payload, end="")
else:
    output_path = Path(args.output).expanduser()
    if not output_path.is_absolute():
        output_path = Path.cwd() / output_path
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(payload)
    print(output_path)
PY
