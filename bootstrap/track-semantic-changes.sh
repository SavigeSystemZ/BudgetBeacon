#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: track-semantic-changes.sh <target-repo> [--json] [--since <commit>]

Classify git diff changes as structural, contractual, cosmetic, or behavioral
using SYSTEM_REGISTRY.json path categories. Helps assess upgrade impact.

Options:
  --since <commit>  Compare against this commit (default: HEAD~1)
  --json            Output as JSON
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
JSON_MODE=0
SINCE="HEAD~1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
      ;;
    --since)
      SINCE="${2:-HEAD~1}"
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

TARGET_REPO="$(cd -- "${TARGET_REPO}" && pwd)"

python3 - <<'PY' "${TARGET_REPO}" "${JSON_MODE}" "${SINCE}"
from __future__ import annotations

import json
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1])
json_mode = sys.argv[2] == "1"
since = sys.argv[3]

# Classification rules based on path patterns
def classify_path(rel: str) -> str:
    """Classify a file change as structural, contractual, cosmetic, or behavioral."""
    # Contractual: files that define rules, contracts, policies
    contractual_markers = [
        "AGENTS.md", "PROJECT_RULES.md", "MASTER_SYSTEM_PROMPT.md",
        "INSTRUCTION_PRECEDENCE", "EXECUTION_PROTOCOL", "VALIDATION_GATES",
        "SECURITY_REDACTION", "SECURITY_HARDENING", "PLUGIN_CONTRACT",
        "HOST_ADAPTER_POLICY", "HOST_BUNDLE_CONTRACT", "MULTI_AGENT_COORDINATION",
        "CHECKPOINT_PROTOCOL", "AGENT_ROLE_CATALOG", "MEMORY_RULES",
        "ENVIRONMENT_VALIDATION_CONTRACT", "DEPENDENCY_GOVERNANCE",
        "CODING_STANDARDS", "PERFORMANCE_BUDGET", "ACCESSIBILITY_STANDARDS",
        "API_DESIGN_STANDARDS", "CONTEXT_BUDGET_STRATEGY",
    ]
    for marker in contractual_markers:
        if marker in rel:
            return "contractual"

    # Structural: files that define the system shape
    structural_markers = [
        "SYSTEM_REGISTRY", "INTEGRITY_MANIFEST", ".template-version",
        ".template-install", "LOAD_ORDER", "CONTEXT_INDEX",
        "host-adapter-manifest.json", "aiaast-capabilities.json",
        "context-budget-profiles.json", "agent-performance-profiles.json",
        "golden-example-manifest.json", "instruction-precedence.json",
        "validate-system.sh", "init-project.sh", "generate-host-adapters.sh",
        "system-doctor.sh", "generate-system-registry.sh",
    ]
    for marker in structural_markers:
        if marker in rel:
            return "structural"

    # Behavioral: scripts, tools, automation
    if rel.startswith("bootstrap/") and rel.endswith(".sh"):
        return "behavioral"
    if rel.endswith(".py") or rel.endswith(".js") or rel.endswith(".ts"):
        return "behavioral"
    if "plugin" in rel.lower() and rel.endswith("run.sh"):
        return "behavioral"

    # Cosmetic: documentation, examples, templates, readmes
    cosmetic_markers = [
        "README.md", "CHANGELOG", "VERSION", "QUICKSTART",
        "ARCHITECTURE_DIAGRAM", "TROUBLESHOOTING", "MIGRATION_GUIDE",
        "PATTERN_INDEX", "KEY.md", "golden-examples/patterns/",
        "golden-examples/working-files/", "prompt-packs/", "prompt-templates/",
        "review-playbooks/", "starter-blueprints/", ".example",
        "AGENT_PERFORMANCE_GUIDE", "PROMPT_EFFECTIVENESS_TRACKING",
        "DESIGN_EXCELLENCE", "MODERN_UI_PATTERNS", "OBSERVABILITY_STANDARDS",
    ]
    for marker in cosmetic_markers:
        if marker in rel:
            return "cosmetic"

    # Working state files are cosmetic (they change per-session)
    working_files = [
        "TODO.md", "FIXME.md", "WHERE_LEFT_OFF.md", "PLAN.md",
        "PRODUCT_BRIEF.md", "ROADMAP.md", "DESIGN_NOTES.md",
        "context/CURRENT_STATUS.md", "context/DECISIONS.md",
    ]
    for wf in working_files:
        if rel.endswith(wf):
            return "cosmetic"

    return "cosmetic"

# Get git diff
try:
    proc = subprocess.run(
        ["git", "diff", "--name-status", since],
        cwd=target, text=True, capture_output=True, timeout=30,
    )
    if proc.returncode != 0:
        print(f"git diff failed: {proc.stderr.strip()}", file=sys.stderr)
        sys.exit(1)
except subprocess.TimeoutExpired:
    print("git diff timed out", file=sys.stderr)
    sys.exit(1)

changes: list[dict] = []
categories: dict[str, int] = {"structural": 0, "contractual": 0, "behavioral": 0, "cosmetic": 0}

for line in proc.stdout.strip().splitlines():
    if not line.strip():
        continue
    parts = line.split("\t", 2)
    if len(parts) < 2:
        continue
    status = parts[0][0]  # A, M, D, R, etc.
    filepath = parts[-1]
    category = classify_path(filepath)
    categories[category] += 1
    changes.append({
        "file": filepath,
        "status": {"A": "added", "M": "modified", "D": "deleted", "R": "renamed"}.get(status, status),
        "category": category,
    })

# Impact assessment
total = len(changes)
impact = "none"
if total > 0:
    if categories["contractual"] > 0 or categories["structural"] > 0:
        impact = "high"
    elif categories["behavioral"] > 0:
        impact = "medium"
    else:
        impact = "low"

results = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "compared_to": since,
    "total_changes": total,
    "categories": categories,
    "impact": impact,
    "changes": changes,
}

if json_mode:
    print(json.dumps(results, indent=2, sort_keys=True))
else:
    if total == 0:
        print("No changes detected.")
    else:
        print(f"Changes since {since}: {total} files")
        print(f"  Structural:   {categories['structural']}")
        print(f"  Contractual:  {categories['contractual']}")
        print(f"  Behavioral:   {categories['behavioral']}")
        print(f"  Cosmetic:     {categories['cosmetic']}")
        print(f"  Impact:       {impact}")
        print()
        for c in changes:
            print(f"  [{c['category'][:4]}] {c['status']:8s} {c['file']}")
PY
