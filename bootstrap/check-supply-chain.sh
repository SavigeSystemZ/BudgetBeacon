#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-supply-chain.sh <target-repo> [--json]

Check dependency supply chain security by running language-specific audit tools.
Detects lock files and dispatches to npm audit, pip-audit, cargo audit, and
go mod verify. Graceful fallback when tools are not installed.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
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

python3 - <<'PY' "${TARGET_REPO}" "${JSON_MODE}"
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"

def has(*paths: str) -> bool:
    return any((target / rel).exists() for rel in paths)

def run_tool(command: list[str], applicable: bool) -> dict:
    if not applicable:
        return {"status": "not_applicable", "command": command}
    tool = command[0]
    if shutil.which(tool) is None:
        return {"status": "tool_unavailable", "command": command}
    try:
        proc = subprocess.run(
            command, cwd=target, text=True, capture_output=True, timeout=300,
        )
    except subprocess.TimeoutExpired:
        return {"status": "timeout", "command": command}
    combined = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    if proc.returncode == 0:
        status = "clean"
    elif proc.returncode == 1:
        status = "findings"
    else:
        status = "error"
    return {
        "status": status,
        "command": command,
        "exit_code": proc.returncode,
        "output": combined[:40000],
    }

node_applicable = has("package-lock.json", "yarn.lock", "pnpm-lock.yaml", "package.json")
python_applicable = has("requirements.txt", "pyproject.toml", "Pipfile.lock", "uv.lock", "poetry.lock")
rust_applicable = has("Cargo.lock", "Cargo.toml")
go_applicable = has("go.sum", "go.mod")

results: dict[str, object] = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "audits": {},
}

# npm/yarn/pnpm audit
results["audits"]["npm_audit"] = run_tool(
    ["npm", "audit", "--json"],
    node_applicable,
)

# Python: pip-audit or safety
if python_applicable:
    if shutil.which("pip-audit"):
        results["audits"]["python_audit"] = run_tool(["pip-audit", "-f", "json"], True)
    elif shutil.which("safety"):
        results["audits"]["python_audit"] = run_tool(["safety", "check", "--json"], True)
    else:
        results["audits"]["python_audit"] = {"status": "tool_unavailable", "command": ["pip-audit", "-f", "json"]}
else:
    results["audits"]["python_audit"] = {"status": "not_applicable", "command": ["pip-audit"]}

# Cargo audit
results["audits"]["cargo_audit"] = run_tool(
    ["cargo", "audit", "--json"],
    rust_applicable and shutil.which("cargo-audit") is not None,
)
if rust_applicable and shutil.which("cargo-audit") is None:
    results["audits"]["cargo_audit"] = {"status": "tool_unavailable", "command": ["cargo", "audit"]}

# Go mod verify
results["audits"]["go_verify"] = run_tool(
    ["go", "mod", "verify"],
    go_applicable,
)

# License check — if license_finder or licensee available
results["audits"]["license_check"] = run_tool(
    ["license_finder", "--format", "json"],
    (node_applicable or python_applicable or rust_applicable or go_applicable)
    and shutil.which("license_finder") is not None,
)
if (node_applicable or python_applicable or rust_applicable or go_applicable) and shutil.which("license_finder") is None:
    results["audits"]["license_check"] = {"status": "tool_unavailable", "command": ["license_finder"]}

# Determine overall
overall = "clean"
for result in results["audits"].values():
    s = result.get("status", "")
    if s == "error":
        overall = "error"
        break
    if s == "findings":
        overall = "findings"
results["overall_status"] = overall

report = json.dumps(results, indent=2, sort_keys=True) + "\n"

if json_mode:
    print(report, end="")
else:
    print("Supply chain audit:")
    for name, result in results["audits"].items():
        print(f"  {name}: {result.get('status', 'unknown')}")
    print(f"Overall: {overall}")

if overall in {"findings", "error"}:
    sys.exit(1)
PY
