#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-agent-orchestration.sh [target-repo]

Verify that the shared role catalog, multi-agent docs, prompt packs, and Cursor role overlays stay aligned.
EOF
}

TARGET_REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
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
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}"
from pathlib import Path
import sys

repo = Path(sys.argv[1]).resolve()
issues: list[str] = []

required_files = [
    repo / "_system" / "AGENT_ROLE_CATALOG.md",
    repo / "_system" / "MULTI_AGENT_COORDINATION.md",
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md",
    repo / "_system" / "prompt-packs" / "M1_FEATURE_DELIVERY.md",
    repo / "_system" / "prompt-packs" / "M9_MULTI_AGENT_CONTINUITY.md",
    repo / "_system" / "prompt-packs" / "M10_GREENFIELD_BOOTSTRAP.md",
    repo / ".cursor" / "agents" / "README.md",
    repo / ".cursor" / "agents" / "orchestrator.md",
    repo / ".cursor" / "agents" / "implementation-worker.md",
    repo / ".cursor" / "agents" / "validator.md",
    repo / ".cursor" / "agents" / "context-curator.md",
]

for path in required_files:
    if not path.exists():
        issues.append(f"Missing orchestration surface: {path.relative_to(repo)}")

checks = {
    repo / "AGENTS.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / "_system" / "MULTI_AGENT_COORDINATION.md": ["_system/AGENT_ROLE_CATALOG.md", "## Delegation rules"],
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / "_system" / "prompt-packs" / "M1_FEATURE_DELIVERY.md": ["role", "write ownership"],
    repo / "_system" / "prompt-packs" / "M9_MULTI_AGENT_CONTINUITY.md": [
        "_system/AGENT_ROLE_CATALOG.md",
        "_system/sub_agent_host_delegation.md",
    ],
    repo / "_system" / "prompt-packs" / "M10_GREENFIELD_BOOTSTRAP.md": ["persisted blueprint recommendation", "explicitly apply"],
    repo / ".cursor" / "agents" / "README.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / ".cursor" / "agents" / "orchestrator.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / ".cursor" / "agents" / "implementation-worker.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / ".cursor" / "agents" / "validator.md": ["_system/AGENT_ROLE_CATALOG.md"],
    repo / ".cursor" / "agents" / "context-curator.md": ["_system/AGENT_ROLE_CATALOG.md"],
}

for path, markers in checks.items():
    if not path.exists():
        continue
    text = path.read_text().lower()
    for marker in markers:
        if marker.lower() not in text:
            issues.append(f"{path.relative_to(repo)} is missing orchestration marker: {marker}")

if issues:
    print("agent_orchestration_issues_detected")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

print("agent_orchestration_ok")
PY
