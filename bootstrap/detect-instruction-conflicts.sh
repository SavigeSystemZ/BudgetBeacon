#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: detect-instruction-conflicts.sh [target-repo] [--strict]

Scan repo instruction surfaces for likely overlap, duplication, and contradiction.
EOF
}

TARGET_REPO=""
STRICT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)
      STRICT=1
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

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}" "${STRICT}"
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
strict = sys.argv[2] == "1"

manifest_path = repo / "_system" / "instruction-precedence.json"
if not manifest_path.exists():
    print("Missing precedence manifest: _system/instruction-precedence.json", file=sys.stderr)
    raise SystemExit(1)

manifest = json.loads(manifest_path.read_text())
required_refs = manifest.get("required_adapter_references", [])
required_consistency_surfaces = manifest.get("required_consistency_surfaces", [])
consistency_surfaces = manifest.get("consistency_surfaces", [])
canonical_terms = list((manifest.get("canonical_terms") or {}).keys())

surface_patterns = [
    "AGENTS.md",
    "CODEX.md",
    "CLAUDE.md",
    "GEMINI.md",
    "WINDSURF.md",
    ".cursorrules",
    ".windsurfrules",
    ".github/copilot-instructions.md",
    ".github/instructions/**/*.instructions.md",
    ".cursor/rules/**/*",
    ".cursor/agents/**/*",
    "_system/prompt-templates/**/*.md",
    "_system/prompt-packs/**/*.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/PROMPT_EMISSION_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/LOAD_ORDER.md",
    "_system/AGENT_DISCOVERY_MATRIX.md",
    "_system/READ_BUNDLES.md",
    "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md",
    "_system/SELF_HEALING_BOUNDARY.md",
    "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md",
]

files: list[Path] = []
for pattern in surface_patterns:
    files.extend(path for path in repo.glob(pattern) if path.is_file())
files = sorted({path.resolve() for path in files})

adapter_paths = [
    repo / "AGENTS.md",
    repo / "CODEX.md",
    repo / "CLAUDE.md",
    repo / "GEMINI.md",
    repo / "WINDSURF.md",
    repo / ".cursorrules",
    repo / ".windsurfrules",
    repo / ".github" / "copilot-instructions.md",
]
adapter_paths = [path for path in adapter_paths if path.exists()]

issues: list[str] = []
authority_claims: dict[str, list[str]] = {}
required_term_paths = [
    repo / "AGENTS.md",
    repo / "_system" / "INSTRUCTION_PRECEDENCE_CONTRACT.md",
    repo / "_system" / "REPO_OPERATING_PROFILE.md",
    repo / "_system" / "PROMPT_EMISSION_CONTRACT.md",
]
consistency_anchor_paths = [
    repo / "AGENTS.md",
    repo / "_system" / "CONTEXT_INDEX.md",
    repo / "_system" / "LOAD_ORDER.md",
    repo / "_system" / "REPO_OPERATING_PROFILE.md",
]

path_token = re.compile(r"`([^`\n]+)`")
authority_re = re.compile(r"\b(source of truth|primary .*contract|authoritative|shared .*canonical)\b", re.IGNORECASE)

def term_variants(term: str) -> set[str]:
    pieces = term.split("_")
    joined_space = " ".join(pieces)
    joined_hyphen = "-".join(pieces)
    variants = {joined_space, joined_hyphen}
    if term == "repo_local_truth":
        variants.add("repo-local truth")
    if term == "host_level_orchestration_context":
        variants.add("host-level orchestration context")
    if term == "tool_overlay":
        variants.add("tool overlay")
        variants.add("tool overlays")
    if term == "runtime_system_boundary":
        variants.add("runtime system boundary")
        variants.add("runtime-system boundary")
        variants.add("runtime/system boundary")
    return variants

def rel(path: Path) -> str:
    return str(path.relative_to(repo))

for path in files:
    if "_system/prompt-templates/" in rel(path) or "_system/prompt-packs/" in rel(path):
        continue
    text = path.read_text()
    for line in text.splitlines():
        if authority_re.search(line):
            authority_claims.setdefault(line.strip(), []).append(rel(path))

for line, owners in sorted(authority_claims.items()):
    if len(owners) > 1 and "AGENTS.md" not in line and "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md" not in line:
        issues.append(f"Duplicated authority statement across instruction surfaces: {line} [{', '.join(owners)}]")

for path in adapter_paths:
    text = path.read_text()
    refs = path_token.findall(text)
    effective_required_refs = [item for item in required_refs if not (path.name == "AGENTS.md" and item == "AGENTS.md")]
    missing = [item for item in effective_required_refs if item not in refs and item not in text]
    if missing:
        issues.append(f"{rel(path)} is missing required repo-local references: {', '.join(missing)}")

    if path.name != "AGENTS.md":
        for line in text.splitlines():
            if authority_re.search(line) and "AGENTS.md" not in line and "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md" not in line:
                issues.append(f"{rel(path)} claims independent authority instead of deferring to repo-local core: {line.strip()}")

    if "_system/VALIDATION_GATES.md" not in text:
        issues.append(f"{rel(path)} is missing the canonical validation surface: _system/VALIDATION_GATES.md")

    if "bootstrap/system-doctor.sh" not in text:
        issues.append(f"{rel(path)} is missing the canonical recovery command: bootstrap/system-doctor.sh")

    if "_system/" not in text and "AGENTS.md" not in text:
        issues.append(f"{rel(path)} does not visibly anchor to repo-local system files")

boundary_positive_hits = 0
for path in adapter_paths:
    text = path.read_text()
    if "Runtime code must not depend on `_system/`." in text or "runtime code independent from `_system/`" in text:
        boundary_positive_hits += 1
    if re.search(r"runtime code .*depend on `_system/`", text, re.IGNORECASE):
        if "must not" not in text.lower() and "independent from" not in text.lower():
            issues.append(f"{rel(path)} may blur the repo/runtime boundary")

if boundary_positive_hits == 0:
    issues.append("No adapter explicitly states the runtime/system boundary")

for path in required_term_paths:
    if not path.exists():
        continue
    text = path.read_text().lower()
    missing_terms = [term for term in canonical_terms if not any(variant in text for variant in term_variants(term))]
    if missing_terms:
        issues.append(f"{rel(path)} is missing canonical terminology markers: {', '.join(missing_terms)}")

for surface in consistency_surfaces:
    if not (repo / surface).exists():
        issues.append(f"Missing consistency surface declared in precedence manifest: {surface}")

for surface in required_consistency_surfaces:
    for path in consistency_anchor_paths:
        if not path.exists():
            continue
        text = path.read_text()
        if surface not in text:
            issues.append(f"{rel(path)} is missing required consistency-surface reference: {surface}")

report_header = "Instruction Conflict Report"
print(report_header)
print("=" * len(report_header))
print()
print(f"Scanned surfaces: {len(files)}")
print(f"Strict mode: {'on' if strict else 'off'}")
print()

if issues:
    print("Findings")
    print("--------")
    for item in issues:
        print(f"- {item}")
else:
    print("No likely instruction conflicts detected.")

if strict and issues:
    raise SystemExit(1)
PY
