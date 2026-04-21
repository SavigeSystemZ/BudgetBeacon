#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scan-security.sh <target-repo> [--output <path>]

Run applicable dependency and container scanners and write a machine-readable report.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="${2:-}"
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

if [[ -z "${TARGET_REPO}" || ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ -z "${OUTPUT_PATH}" ]]; then
  OUTPUT_PATH="${TARGET_REPO}/_system/security_scan.json"
fi

python3 - <<'PY' "${TARGET_REPO}" "${OUTPUT_PATH}"
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
output_path = Path(sys.argv[2]).resolve()

def has_any(*paths: str) -> bool:
    return any((target / rel).exists() for rel in paths)

def run(name: str, command: list[str], applicable: bool) -> dict:
    if not applicable:
        return {"status": "not_applicable", "command": command}

    tool = command[0]
    if shutil.which(tool) is None:
        return {"status": "tool_unavailable", "command": command}

    proc = subprocess.run(
        command,
        cwd=target,
        text=True,
        capture_output=True,
        timeout=600,
    )
    combined = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    status = "clean" if proc.returncode == 0 else "findings"
    if proc.returncode not in (0, 1):
        status = "error"
    return {
        "status": status,
        "command": command,
        "exit_code": proc.returncode,
        "output": combined[:40000],
    }

results = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "scanners": {},
}

node_applicable = has_any("package.json")
python_applicable = has_any("pyproject.toml", "requirements.txt", "uv.lock")
rust_applicable = has_any("Cargo.toml")
container_applicable = has_any("Dockerfile", "docker-compose.yml", "compose.yml")

results["scanners"]["npm_audit"] = run(
    "npm_audit",
    ["npm", "audit", "--json"],
    node_applicable,
)

if python_applicable and shutil.which("pip-audit"):
    results["scanners"]["python_audit"] = run(
        "python_audit",
        ["pip-audit", "-f", "json"],
        True,
    )
elif python_applicable and shutil.which("safety"):
    results["scanners"]["python_audit"] = run(
        "python_audit",
        ["safety", "check", "--json"],
        True,
    )
else:
    results["scanners"]["python_audit"] = {
        "status": "tool_unavailable" if python_applicable else "not_applicable",
        "command": ["pip-audit", "-f", "json"],
    }

results["scanners"]["cargo_audit"] = run(
    "cargo_audit",
    ["cargo", "audit", "--json"],
    rust_applicable and shutil.which("cargo-audit") is not None,
)
if rust_applicable and shutil.which("cargo-audit") is None:
    results["scanners"]["cargo_audit"] = {
        "status": "tool_unavailable",
        "command": ["cargo", "audit", "--json"],
    }

results["scanners"]["trivy_fs"] = run(
    "trivy_fs",
    ["trivy", "fs", "--format", "json", str(target)],
    container_applicable,
)

results["scanners"]["grype_dir"] = run(
    "grype_dir",
    ["grype", f"dir:{target}", "-o", "json"],
    container_applicable,
)

overall = "clean"
for result in results["scanners"].values():
    if result["status"] in {"findings", "error"}:
        overall = result["status"]
        if result["status"] == "error":
            break
results["overall_status"] = overall

output_path.parent.mkdir(parents=True, exist_ok=True)
output_path.write_text(json.dumps(results, indent=2, sort_keys=True) + "\n")

print(f"Security scan report written to {output_path}")
for name, result in results["scanners"].items():
    print(f"- {name}: {result['status']}")

if overall in {"findings", "error"}:
    sys.exit(1)
PY
