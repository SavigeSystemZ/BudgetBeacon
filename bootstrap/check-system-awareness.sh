#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-system-awareness.sh [target-repo]

Verify that AIAST knows its managed files and that core docs reference real local paths.
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
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}"
from __future__ import annotations

import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
registry_path = repo / "_system" / "SYSTEM_REGISTRY.json"
issues: list[str] = []

if not registry_path.exists():
    print(f"Missing system registry: {registry_path.relative_to(repo)}", file=sys.stderr)
    sys.exit(1)

registry = json.loads(registry_path.read_text())
registry_paths = {entry["path"] for entry in registry.get("entries", [])}

managed_cmd = (
    f"source {shlex.quote(str(repo / 'bootstrap/lib/aiaast-lib.sh'))} >/dev/null 2>&1 && "
    f"aiaast_print_managed_files {shlex.quote(str(repo))}"
)
actual_paths = set(
    line.strip()
    for line in subprocess.run(
        ["bash", "-lc", managed_cmd],
        cwd=repo,
        text=True,
        capture_output=True,
        check=True,
    ).stdout.splitlines()
    if line.strip()
)

missing_from_registry = sorted(actual_paths - registry_paths)
missing_from_fs = sorted(path for path in registry_paths if not (repo / path).exists())

for rel in missing_from_registry:
    issues.append(f"Managed file missing from registry: {rel}")
for rel in missing_from_fs:
    issues.append(f"Registry references missing file: {rel}")

docs_to_scan = [
    repo / "AGENTS.md",
    repo / "_system" / "CONTEXT_INDEX.md",
    repo / "_system" / "KEY.md",
    repo / "_system" / "LOAD_ORDER.md",
    repo / "_system" / "README.md",
    repo / "bootstrap" / "README.md",
    repo / ("AI_SYSTEM_README.md" if (repo / "AI_SYSTEM_README.md").exists() else "README.md"),
]

required_mentions = {
    repo / "AGENTS.md": ["bootstrap/system-doctor.sh", "_system/SYSTEM_AWARENESS_PROTOCOL.md", "_system/HALLUCINATION_DEFENSE_PROTOCOL.md", "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md", "_system/REPO_OPERATING_PROFILE.md", "_system/KEY.md", "_system/GOLDEN_EXAMPLES_POLICY.md", "_system/HOST_ADAPTER_POLICY.md", "_system/HOST_BUNDLE_CONTRACT.md", "_system/AGENT_ROLE_CATALOG.md", "_system/READ_BUNDLES.md", "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md", "_system/SELF_HEALING_BOUNDARY.md", "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
    repo / "_system" / "CONTEXT_INDEX.md": ["KEY.md", "SYSTEM_REGISTRY.json", "SYSTEM_AWARENESS_PROTOCOL.md", "HALLUCINATION_DEFENSE_PROTOCOL.md", "INSTRUCTION_PRECEDENCE_CONTRACT.md", "REPO_OPERATING_PROFILE.md", "GOLDEN_EXAMPLES_POLICY.md", "golden-example-manifest.json", "HOST_ADAPTER_POLICY.md", "host-adapter-manifest.json", "HOST_BUNDLE_CONTRACT.md", "emit-host-bundle.sh", "check-host-bundle.sh", "AGENT_ROLE_CATALOG.md", "recommend-starter-blueprint.sh", "READ_BUNDLES.md", "TEMPLATE_CHANGE_IMPACT_POLICY.md", "SELF_HEALING_BOUNDARY.md", "VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
    repo / "_system" / "LOAD_ORDER.md": ["_system/KEY.md", "_system/SYSTEM_AWARENESS_PROTOCOL.md", "_system/HALLUCINATION_DEFENSE_PROTOCOL.md", "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md", "_system/REPO_OPERATING_PROFILE.md", "_system/GOLDEN_EXAMPLES_POLICY.md", "_system/HOST_ADAPTER_POLICY.md", "_system/HOST_BUNDLE_CONTRACT.md", "_system/AGENT_ROLE_CATALOG.md", "_system/READ_BUNDLES.md"],
    repo / "_system" / "README.md": ["READ_BUNDLES.md", "TEMPLATE_CHANGE_IMPACT_POLICY.md", "SELF_HEALING_BOUNDARY.md", "VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
    repo / "bootstrap" / "README.md": ["scaffold-system.sh", "system-doctor.sh", "check-system-awareness.sh", "check-hallucination.sh", "check-runtime-foundations.sh", "check-repo-permissions.sh", "generate-system-key.sh", "generate-system-registry.sh", "generate-host-adapters.sh", "check-host-adapter-alignment.sh", "generate-operating-profile.sh", "detect-instruction-conflicts.sh", "check-instruction-domain-alignment.sh", "validate-instruction-layer.sh", "emit-host-bundle.sh", "check-host-bundle.sh", "recommend-starter-blueprint.sh", "check-agent-orchestration.sh", "_system/READ_BUNDLES.md", "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md", "_system/SELF_HEALING_BOUNDARY.md", "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md"],
}

path_pattern = re.compile(r"`([^`\n]+)`")
candidate_suffixes = (".md", ".sh", ".json", ".toml", ".yml", ".yaml", ".service", ".timer", ".mdc")
known_root_names = {
    "AGENTS.md",
    "CLAUDE.md",
    "GEMINI.md",
    "CODEX.md",
    "WINDSURF.md",
    "README.md",
    "AI_SYSTEM_README.md",
    "AIAST_VERSION.md",
    "AIAST_CHANGELOG.md",
    "TODO.md",
    "FIXME.md",
    "WHERE_LEFT_OFF.md",
    "CHANGELOG.md",
    "PLAN.md",
    "PRODUCT_BRIEF.md",
    "ROADMAP.md",
    "DESIGN_NOTES.md",
    "ARCHITECTURE_NOTES.md",
    "RESEARCH_NOTES.md",
    "TEST_STRATEGY.md",
    "RISK_REGISTER.md",
    "RELEASE_NOTES.md",
}

def looks_like_path(token: str) -> bool:
    if " " in token:
        return False
    if token.startswith("http://") or token.startswith("https://"):
        return False
    if token.startswith("127.0.0.1") or token.startswith("::1"):
        return False
    if token in known_root_names:
        return True
    if token.endswith("/"):
        return True
    if token.endswith(candidate_suffixes):
        return True
    if "/" in token or token.startswith(".cursor") or token.startswith(".github") or token.startswith("_system") or token.startswith("bootstrap"):
        return True
    return False

def path_exists(doc: Path, token: str) -> bool:
    if token == "AI_SYSTEM_README.md":
        return (repo / "AI_SYSTEM_README.md").exists() or (repo / "README.md").exists()

    candidates = []
    if token.startswith("../"):
        candidates.append((doc.parent / token).resolve())
    else:
        candidates.append((doc.parent / token).resolve())
        candidates.append((repo / token).resolve())

    if "*" in token:
        for base in (doc.parent, repo):
            if list(base.glob(token)):
                return True
        return False

    return any(candidate.exists() for candidate in candidates)

for doc in docs_to_scan:
    if not doc.exists():
        continue
    text = doc.read_text()
    for expected in required_mentions.get(doc, []):
        if expected not in text:
            issues.append(f"{doc.relative_to(repo)} is missing required mention: {expected}")
    for token in path_pattern.findall(text):
        if not looks_like_path(token):
            continue
        if token.endswith("/"):
            relative_candidate = (doc.parent / token).resolve()
            root_candidate = (repo / token).resolve()
            candidate = relative_candidate if relative_candidate.exists() else root_candidate
            if not candidate.is_dir():
                issues.append(f"{doc.relative_to(repo)} references missing directory: {token}")
        else:
            if not path_exists(doc, token):
                issues.append(f"{doc.relative_to(repo)} references missing path: {token}")

if issues:
    print("system_awareness_issues_detected")
    for item in issues:
        print(f"- {item}")
    sys.exit(1)

print("system_awareness_ok")
PY
