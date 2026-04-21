#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: run-sast.sh <target-repo> [--json] [--output <path>]

Run static application security testing (SAST) tools against the target repo.
Dispatches to semgrep, bandit, eslint-plugin-security, and gosec based on
detected languages. Gracefully falls back when tools are not installed.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
JSON_MODE=0
OUTPUT_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
      ;;
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

python3 - <<'PY' "${TARGET_REPO}" "${JSON_MODE}" "${OUTPUT_PATH}"
from __future__ import annotations

import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"
output_path_arg = sys.argv[3]

def has_any(*paths: str) -> bool:
    return any((target / rel).exists() for rel in paths)

def has_ext(*exts: str) -> bool:
    for ext in exts:
        if list(target.rglob(f"*{ext}"))[:1]:
            return True
    return False

def run_tool(command: list[str], applicable: bool) -> dict:
    if not applicable:
        return {"status": "not_applicable", "command": command}

    tool = command[0]
    if shutil.which(tool) is None:
        return {"status": "tool_unavailable", "command": command}

    try:
        proc = subprocess.run(
            command,
            cwd=target,
            text=True,
            capture_output=True,
            timeout=300,
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

# Detect applicable languages
python_applicable = has_any("pyproject.toml", "requirements.txt", "uv.lock") or has_ext(".py")
js_applicable = has_any("package.json", "tsconfig.json") or has_ext(".js", ".ts", ".jsx", ".tsx")
go_applicable = has_any("go.mod") or has_ext(".go")
multi_applicable = python_applicable or js_applicable or go_applicable

results: dict[str, object] = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "scanners": {},
}

# Semgrep — universal SAST, supports Python, JS/TS, Go, Java, Ruby, etc.
results["scanners"]["semgrep"] = run_tool(
    ["semgrep", "scan", "--config", "auto", "--json", "--quiet", str(target)],
    multi_applicable,
)

# Bandit — Python-specific SAST
results["scanners"]["bandit"] = run_tool(
    ["bandit", "-r", str(target), "-f", "json", "-q"],
    python_applicable,
)

# ESLint security plugin — JS/TS specific
# Check if eslint is available and has the security plugin
eslint_cmd = ["npx", "eslint", "--no-eslintrc",
              "--plugin", "security",
              "--rule", "{\"security/detect-eval-with-expression\": \"warn\", \"security/detect-non-literal-regexp\": \"warn\", \"security/detect-non-literal-fs-filename\": \"warn\", \"security/detect-object-injection\": \"warn\"}",
              "-f", "json", "."]
results["scanners"]["eslint_security"] = run_tool(
    eslint_cmd,
    js_applicable and shutil.which("npx") is not None,
)

# gosec — Go-specific SAST
results["scanners"]["gosec"] = run_tool(
    ["gosec", "-fmt=json", "-quiet", "./..."],
    go_applicable,
)

# Determine overall status
overall = "clean"
for result in results["scanners"].values():
    if isinstance(result, dict):
        s = result.get("status", "")
        if s == "error":
            overall = "error"
            break
        if s == "findings":
            overall = "findings"
results["overall_status"] = overall

# Output
report = json.dumps(results, indent=2, sort_keys=True) + "\n"

if output_path_arg:
    out = Path(output_path_arg)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(report)
    if not json_mode:
        print(f"SAST report written to {out}")

if json_mode:
    print(report, end="")
else:
    for name, result in results["scanners"].items():
        status = result.get("status", "unknown") if isinstance(result, dict) else "unknown"
        print(f"  {name}: {status}")
    print(f"Overall: {overall}")

if overall in {"findings", "error"}:
    sys.exit(1)
PY
