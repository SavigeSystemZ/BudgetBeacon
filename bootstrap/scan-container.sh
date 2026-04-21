#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scan-container.sh <target-repo> [--json]

Scan container images and Dockerfiles for security issues.
Uses trivy or grype if available, otherwise falls back to static Dockerfile linting
(no :latest, no root user, multi-stage check).
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
import re
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"

# Find Dockerfiles
dockerfiles = sorted(
    set(list(target.glob("Dockerfile")) + list(target.glob("**/Dockerfile"))
        + list(target.glob("Dockerfile.*")) + list(target.glob("**/Dockerfile.*")))
)

compose_files = [
    p for p in [target / "docker-compose.yml", target / "docker-compose.yaml",
                target / "compose.yml", target / "compose.yaml"]
    if p.exists()
]

container_applicable = bool(dockerfiles or compose_files)

results: dict[str, object] = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "dockerfiles_found": [str(d.relative_to(target)) for d in dockerfiles],
    "compose_files_found": [str(c.relative_to(target)) for c in compose_files],
    "scanners": {},
    "dockerfile_lint": [],
}

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

# Trivy filesystem scan
results["scanners"]["trivy_fs"] = run_tool(
    ["trivy", "fs", "--format", "json", "--scanners", "vuln,misconfig", str(target)],
    container_applicable,
)

# Grype directory scan
results["scanners"]["grype_dir"] = run_tool(
    ["grype", f"dir:{target}", "-o", "json"],
    container_applicable,
)

# Hadolint — Dockerfile linter
for df in dockerfiles:
    rel = str(df.relative_to(target))
    results["scanners"][f"hadolint_{rel}"] = run_tool(
        ["hadolint", "--format", "json", str(df)],
        True,
    )

# Static Dockerfile lint (always runs, no external deps)
lint_findings: list[dict] = []
for df in dockerfiles:
    rel = str(df.relative_to(target))
    content = df.read_text(errors="replace")
    lines = content.splitlines()

    has_user = False
    has_multistage = False
    from_count = 0

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Check for FROM with :latest or no tag
        if re.match(r"^FROM\s+", stripped, re.IGNORECASE):
            from_count += 1
            image = re.sub(r"^FROM\s+", "", stripped, flags=re.IGNORECASE).split()[0] if stripped.split()[1:] else ""
            if image and (":" not in image or image.endswith(":latest")):
                if not image.lower().startswith("scratch") and " as " not in stripped.lower():
                    lint_findings.append({
                        "file": rel, "line": i, "severity": "warning",
                        "rule": "no_latest_tag",
                        "message": f"FROM uses :latest or no explicit tag: {image}",
                    })

        # Check for USER directive
        if re.match(r"^USER\s+", stripped, re.IGNORECASE):
            has_user = True

        # Check for AS (multi-stage)
        if re.match(r"^FROM\s+.*\s+[Aa][Ss]\s+", stripped):
            has_multistage = True

    if from_count > 0 and not has_user:
        lint_findings.append({
            "file": rel, "line": 0, "severity": "warning",
            "rule": "no_user_directive",
            "message": "No USER directive found — container may run as root",
        })

    if from_count > 1 and not has_multistage:
        lint_findings.append({
            "file": rel, "line": 0, "severity": "info",
            "rule": "no_multistage",
            "message": "Multiple FROM statements but no named stages (AS). Consider multi-stage builds.",
        })

results["dockerfile_lint"] = lint_findings

# Overall status
overall = "clean"
for result in results["scanners"].values():
    s = result.get("status", "")
    if s == "error":
        overall = "error"
        break
    if s == "findings":
        overall = "findings"
if lint_findings and overall == "clean":
    overall = "warnings"
if not container_applicable:
    overall = "not_applicable"
results["overall_status"] = overall

report = json.dumps(results, indent=2, sort_keys=True) + "\n"

if json_mode:
    print(report, end="")
else:
    if not container_applicable:
        print("No Dockerfiles or compose files found — skipping container scan.")
    else:
        print(f"Container scan ({len(dockerfiles)} Dockerfiles, {len(compose_files)} compose files):")
        for name, result in results["scanners"].items():
            print(f"  {name}: {result.get('status', 'unknown')}")
        if lint_findings:
            print(f"  Static lint: {len(lint_findings)} finding(s)")
            for f in lint_findings:
                print(f"    [{f['severity']}] {f['file']}:{f['line']} — {f['message']}")
        print(f"Overall: {overall}")

if overall in {"findings", "error"}:
    sys.exit(1)
PY
