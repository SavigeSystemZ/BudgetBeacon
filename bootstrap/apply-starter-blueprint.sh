#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BLUEPRINT_DIR="${SCRIPT_DIR}/../_system/starter-blueprints"

usage() {
  cat <<'EOF'
Usage: apply-starter-blueprint.sh <target-repo> --blueprint <BLUEPRINT_ID> [--app-name NAME]
       apply-starter-blueprint.sh --list

Apply a starter blueprint into the repo's product brief and first operating surfaces.
EOF
}

TARGET_REPO=""
BLUEPRINT_ID=""
APP_NAME=""
LIST_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --blueprint)
      BLUEPRINT_ID="${2:-}"
      shift 2
      ;;
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --list)
      LIST_ONLY=1
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

if [[ ${LIST_ONLY} -eq 1 ]]; then
  python3 - <<'PY' "${BLUEPRINT_DIR}"
from pathlib import Path
import sys

blueprint_dir = Path(sys.argv[1])
for path in sorted(blueprint_dir.glob("*.md")):
    if path.name == "README.md":
        continue
    title = path.read_text().splitlines()[0].removeprefix("# ").strip()
    print(f"{path.stem}\t{title}")
PY
  exit 0
fi

if [[ -z "${TARGET_REPO}" || -z "${BLUEPRINT_ID}" ]]; then
  usage
  exit 1
fi

PROFILE="${TARGET_REPO}/_system/PROJECT_PROFILE.md"
PRODUCT_BRIEF="${TARGET_REPO}/PRODUCT_BRIEF.md"
PLAN="${TARGET_REPO}/PLAN.md"
ROADMAP="${TARGET_REPO}/ROADMAP.md"
DESIGN_NOTES="${TARGET_REPO}/DESIGN_NOTES.md"
ARCHITECTURE_NOTES="${TARGET_REPO}/ARCHITECTURE_NOTES.md"
TEST_STRATEGY="${TARGET_REPO}/TEST_STRATEGY.md"
RISK_REGISTER="${TARGET_REPO}/RISK_REGISTER.md"
TODO_FILE="${TARGET_REPO}/TODO.md"
WHERE_LEFT_OFF="${TARGET_REPO}/WHERE_LEFT_OFF.md"
RELEASE_NOTES="${TARGET_REPO}/RELEASE_NOTES.md"

for path in "${PROFILE}" "${PRODUCT_BRIEF}" "${PLAN}" "${ROADMAP}"; do
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    exit 1
  fi
done

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(python3 - <<'PY' "${PROFILE}" "${PRODUCT_BRIEF}"
from pathlib import Path
import re
import sys

profile = Path(sys.argv[1]).read_text()
brief = Path(sys.argv[2]).read_text()

for text, label in ((profile, "App name"), (brief, "Product name")):
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.+)$", text, re.MULTILINE)
    if match and match.group(1).strip():
        print(match.group(1).strip())
        raise SystemExit(0)
PY
)"
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(basename -- "${TARGET_REPO}")"
fi

python3 - <<'PY' "${BLUEPRINT_DIR}" "${BLUEPRINT_ID}" "${PROFILE}" "${PRODUCT_BRIEF}" "${PLAN}" "${ROADMAP}" "${DESIGN_NOTES}" "${ARCHITECTURE_NOTES}" "${TEST_STRATEGY}" "${RISK_REGISTER}" "${TODO_FILE}" "${WHERE_LEFT_OFF}" "${RELEASE_NOTES}" "${APP_NAME}"
from __future__ import annotations

from datetime import datetime, timezone
from pathlib import Path
import re
import sys

blueprint_dir = Path(sys.argv[1])
blueprint_id = sys.argv[2].strip()
profile_path = Path(sys.argv[3])
product_brief_path = Path(sys.argv[4])
plan_path = Path(sys.argv[5])
roadmap_path = Path(sys.argv[6])
design_notes_path = Path(sys.argv[7])
architecture_notes_path = Path(sys.argv[8])
test_strategy_path = Path(sys.argv[9])
risk_register_path = Path(sys.argv[10])
todo_path = Path(sys.argv[11])
where_left_off_path = Path(sys.argv[12])
release_notes_path = Path(sys.argv[13])
app_name = sys.argv[14]
timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

blueprint_path = blueprint_dir / f"{blueprint_id}.md"
if not blueprint_path.exists():
    print(f"Unknown blueprint: {blueprint_id}", file=sys.stderr)
    raise SystemExit(1)

blueprint_text = blueprint_path.read_text()
profile_text = profile_path.read_text()
brief_text = product_brief_path.read_text()
plan_text = plan_path.read_text()
roadmap_text = roadmap_path.read_text()


def field(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def replace_label(text: str, label: str, value: str) -> str:
    return re.sub(
        rf"^- {re.escape(label)}:.*$",
        f"- {label}: {value}",
        text,
        count=1,
        flags=re.MULTILINE,
    )


def replace_exact_line(text: str, old_line: str, new_line: str) -> str:
    old_with_newline = f"{old_line}\n"
    new_with_newline = f"{new_line}\n"
    if old_with_newline in text:
        return text.replace(old_with_newline, new_with_newline, 1)
    if text.endswith(old_line):
        return text[: -len(old_line)] + new_line
    return text


def replace_one_of(text: str, candidates: list[str], new_line: str) -> str:
    original = text
    for candidate in candidates:
        text = replace_exact_line(text, candidate, new_line)
        if text != original:
            return text
    return text


def ensure_build_shape_fields(text: str) -> str:
    labels = [
        "Recommended starter blueprint",
        "Recommendation confidence",
        "Recommendation rationale",
        "Selected starter blueprint",
        "Why this blueprint fits",
        "Planned repo shape",
        "First milestone",
        "Initial validation focus",
        "Next decision gates",
    ]
    missing = [label for label in labels if not re.search(rf"^- {re.escape(label)}:", text, re.MULTILINE)]
    if not missing:
        return text
    anchor = "## Build shape\n\n"
    if anchor not in text:
        return text
    insertion = "".join(f"- {label}:\n" for label in missing)
    return text.replace(anchor, anchor + insertion, 1)


def compact(text: str) -> str:
    return " ".join(text.strip().split())


def join_unique(items: list[str], delimiter: str = " | ", limit: int | None = None) -> str:
    seen: list[str] = []
    for item in items:
        value = compact(item)
        if value and value not in seen:
            seen.append(value)
    if limit is not None:
        seen = seen[:limit]
    return delimiter.join(seen)


def keep_or_replace(current: str, replacement: str, fallback_markers: tuple[str, ...]) -> str:
    if not current:
        return replacement
    normalized = compact(current).lower()
    if any(marker and marker in normalized for marker in fallback_markers):
        return replacement
    return current


def replace_if_placeholder(text: str, label: str, replacement: str, fallback_markers: tuple[str, ...]) -> str:
    current = field(text, label)
    value = keep_or_replace(current, replacement, fallback_markers)
    if value == current or not value:
        return text
    return replace_label(text, label, value)


def section_map(markdown: str) -> dict[str, str]:
    matches = list(re.finditer(r"^##\s+(.+?)\n", markdown, re.MULTILINE))
    sections: dict[str, str] = {}
    for idx, match in enumerate(matches):
        start = match.end()
        end = matches[idx + 1].start() if idx + 1 < len(matches) else len(markdown)
        sections[match.group(1).strip()] = markdown[start:end].strip()
    return sections


def extract_code_block(section: str) -> str:
    match = re.search(r"```(?:[^\n]*)\n(.*?)```", section, re.DOTALL)
    return match.group(1).strip() if match else ""


def extract_list(section: str) -> list[str]:
    items: list[str] = []
    for line in section.splitlines():
        stripped = line.strip()
        if re.match(r"^[-*]\s+", stripped):
            items.append(re.sub(r"^[-*]\s+", "", stripped))
        elif re.match(r"^\d+\.\s+", stripped):
            items.append(re.sub(r"^\d+\.\s+", "", stripped))
    return items


def shape_summary(section: str) -> str:
    block = extract_code_block(section)
    if block:
        roots: list[str] = []
        for raw in block.splitlines():
            if not raw.strip():
                continue
            if raw.startswith(" ") or raw.startswith("\t"):
                continue
            root = raw.strip()
            if root not in roots:
                roots.append(root)
        if roots:
            return ", ".join(roots[:8])
    items = extract_list(section)
    if items:
        return ", ".join(items[:6])
    return compact(section)


def categorize_validation_items(items: list[str]) -> dict[str, list[str]]:
    lanes = {
        "format or lint": [],
        "typecheck": [],
        "unit tests": [],
        "integration tests": [],
        "end-to-end or smoke": [],
        "build or packaging checks": [],
        "security or policy checks": [],
    }

    for item in items:
        lowered = item.lower()
        matched = False

        if any(token in lowered for token in ("lint", "format", "eslint")):
            lanes["format or lint"].append(item)
            matched = True
        if any(token in lowered for token in ("typecheck", "tsc", "mypy", "pyright")):
            lanes["typecheck"].append(item)
            matched = True
        if "unit" in lowered or "pytest" in lowered or "vitest" in lowered or "jest" in lowered:
            lanes["unit tests"].append(item)
            matched = True
        if "integration" in lowered:
            lanes["integration tests"].append(item)
            matched = True
        if any(
            token in lowered
            for token in (
                "smoke",
                "playwright",
                "dev server",
                "page renders",
                "route test",
                "debug build",
                "execution",
            )
        ):
            lanes["end-to-end or smoke"].append(item)
            matched = True
        if any(
            token in lowered
            for token in (
                "build",
                "packaging",
                "manifest",
                "install.sh",
                "repair.sh",
                "check-runtime-foundations",
                "apk",
                "aab",
            )
        ):
            lanes["build or packaging checks"].append(item)
            matched = True
        if any(token in lowered for token in ("security", "policy", "audit")):
            lanes["security or policy checks"].append(item)
            matched = True

        if not matched:
            lanes["end-to-end or smoke"].append(item)

    return lanes


sections = section_map(blueprint_text)
title = blueprint_text.splitlines()[0].removeprefix("# ").strip()
intro = blueprint_text.split("\n##", 1)[0]
intro_lines = [line.strip() for line in intro.splitlines()[1:] if line.strip()]
fit_blurb = compact(" ".join(intro_lines)) or "Selected directly for the current product shape."

repo_shape = shape_summary(sections.get("Expected repo shape", "") or sections.get("Expectations", ""))
architecture_section = (
    sections.get("Architecture rules")
    or sections.get("Baseline stack")
    or sections.get("Stack signals")
    or sections.get("Expectations")
    or sections.get("Baseline expectations")
    or sections.get("Supported patterns")
    or ""
)
quality_section = (
    sections.get("Product quality bar")
    or sections.get("Quality expectations")
    or sections.get("Baseline expectations")
    or sections.get("Expectations")
    or ""
)
validation_section = sections.get("Validation minimum") or sections.get("Validation commands") or ""
milestone_section = sections.get("First milestone suggestion") or ""

architecture_items = extract_list(architecture_section)
quality_items = extract_list(quality_section)
validation_items = extract_list(validation_section)
milestone_items = extract_list(milestone_section)
validation_lanes = categorize_validation_items(validation_items)

milestone_summary = "; ".join(milestone_items) if milestone_items else "prove the first real vertical slice using the selected blueprint"
validation_summary = join_unique(validation_items) or "run the blueprint-aligned validation minimum before broadening scope"
quality_summary = join_unique(quality_items, limit=4) or "keep the first slice deliberate, usable, and honest"
architecture_summary = join_unique(architecture_items, limit=4) or "keep runtime code out of _system_ and preserve the chosen blueprint boundaries"
design_summary = join_unique(quality_items, limit=2) or fit_blurb

design_tone = design_summary
interaction_style = quality_summary
visual_character = "deliberate, product-specific, and shaped around the selected blueprint's primary workflow"
first_impression_goal = milestone_summary
trust_signal = validation_summary
speed_signal = "fast feedback, stable layout, and obvious progress through the first proven workflow"

decision_gates = {
    "UNIVERSAL_APP_PLATFORM": "shared contracts, persistence model, auth seams, worker boundaries, mobile/API scope, and packaging depth",
    "NEXT_JS_FULLSTACK": "server/client boundaries, auth model, persistence, caching strategy, and deployment target",
    "REACT_VITE_TYPESCRIPT": "routing shape, state model, API contract, design system depth, and deployment target",
    "STATIC_FRONTEND": "content model, hosting target, progressive enhancement needs, and design system scope",
    "FASTAPI_API": "auth model, persistence boundary, migration discipline, background work, and deployment shape",
    "GRAPHQL_API": "schema ownership, resolver boundaries, persistence model, auth rules, and N+1 protection",
    "GRPC_SERVICE": "protobuf contract ownership, transport boundaries, backward compatibility, and rollout sequencing",
    "PYTHON_CLI_TOOL": "command surface, config model, output contracts, packaging route, and plugin scope",
    "RUST_CLI_TOOL": "command surface, config model, output contracts, release packaging, and extension points",
    "GO_SERVICE": "service boundary, config model, persistence, background jobs, and deployment topology",
    "BACKGROUND_WORKER": "job contract, retry policy, idempotency, persistence, and observability",
    "DATABASE_MIGRATIONS": "schema ownership, backward compatibility, rollout order, and rollback plan",
    "TAURI_DESKTOP": "desktop shell boundary, web/native bridge, packaging targets, and update strategy",
    "FLUTTER_ANDROID_CLIENT": "API contract, offline state, flavor strategy, permissions, and release artifact flow",
}
next_decision_gates = decision_gates.get(
    blueprint_id,
    "runtime boundaries, persistence, deployment targets, integration seams, and validation depth",
)

repo_purpose = field(profile_text, "Repo purpose")
product_frame = repo_purpose or f"build {app_name} as a repo shaped intentionally around the selected starter blueprint"
current_summary = field(brief_text, "One-line summary")
summary_value = keep_or_replace(
    current_summary,
    product_frame,
    ("define the app promise in one clear sentence before major implementation begins",),
)

brief_text = ensure_build_shape_fields(brief_text)
brief_text = replace_label(brief_text, "Product name", app_name)
brief_text = replace_label(brief_text, "One-line summary", summary_value)
brief_text = replace_label(brief_text, "Recommended starter blueprint", f"{blueprint_id} - {title}")
brief_text = replace_label(brief_text, "Recommendation confidence", "confirmed")
brief_text = replace_label(brief_text, "Recommendation rationale", "Explicit blueprint selection confirmed this build shape for the current product.")
brief_text = replace_label(brief_text, "Selected starter blueprint", f"{blueprint_id} - {title}")
brief_text = replace_label(brief_text, "Why this blueprint fits", fit_blurb)
brief_text = replace_label(brief_text, "Planned repo shape", repo_shape or "see the selected starter blueprint for the expected repo shape")
brief_text = replace_label(brief_text, "First milestone", milestone_summary)
brief_text = replace_label(brief_text, "Initial validation focus", validation_summary)
brief_text = replace_label(brief_text, "Next decision gates", next_decision_gates)

plan_text = replace_label(plan_text, "Current target outcome", f"Deliver the first blueprint-aligned vertical slice for {app_name}")
plan_text = replace_label(plan_text, "Why it matters now", "The selected starter blueprint gives the repo a concrete build shape; the next step is to prove it with one real slice instead of broad speculative setup.")
plan_text = replace_label(plan_text, "Deadline or forcing function", "Prove the first blueprint-aligned slice before broadening scope or making release claims.")
plan_text = replace_label(plan_text, "User or operator outcome", milestone_summary)
plan_text = replace_label(plan_text, "Technical outcome", f"The repo shape and first runtime slice align with {blueprint_id} and are backed by real validation evidence.")
plan_text = replace_label(plan_text, "Design or product-quality outcome", quality_summary)
plan_text = replace_label(plan_text, "In scope", "selected starter blueprint, first vertical slice, repo-shape confirmation, and first real validation evidence")
plan_text = replace_label(plan_text, "Out of scope", "secondary surfaces, broad polish, and expansion beyond the first proven slice")
plan_text = replace_label(plan_text, "Dependencies", "PRODUCT_BRIEF.md, _system/PROJECT_PROFILE.md, the selected starter blueprint, and the repo toolchain")
plan_text = replace_label(plan_text, "Known unknowns", next_decision_gates)
plan_text = replace_label(plan_text, "Commands to run", validation_summary)
plan_text = replace_label(plan_text, "Evidence to capture", "exact commands run, pass or fail outcomes, and proof that the first slice matches the chosen blueprint")
plan_text = replace_label(plan_text, "Stop conditions", "stop if the selected blueprint conflicts with real product needs or if the first validation path cannot be proven")
plan_text = replace_label(plan_text, "Release-blocking checks", "the blueprint-aligned validation minimum must be proven before release posture changes")
plan_text = replace_label(plan_text, "Risks that could invalidate the plan", "shape drift, overbuilding before proof, unvalidated contracts, or hidden runtime constraints")
plan_text = replace_label(plan_text, "Fallback path if the plan fails", "reduce scope to the smallest demonstrable slice, update PRODUCT_BRIEF.md, and re-select the blueprint if needed")
plan_text = replace_label(plan_text, "Define what \"done\" means for this repo milestone", "the selected blueprint is reflected in repo planning, one real vertical slice exists, and the first validation path is proven")
plan_text = re.sub(r"^1\..*$", f"1. Shape the repo around `{blueprint_id}` and confirm the first-slice boundaries.", plan_text, count=1, flags=re.MULTILINE)
plan_text = re.sub(r"^2\..*$", "2. Build the first milestone captured in `PRODUCT_BRIEF.md` with real runtime behavior.", plan_text, count=1, flags=re.MULTILINE)
plan_text = re.sub(r"^3\..*$", "3. Run blueprint-aligned validation, capture evidence, and set the next slice.", plan_text, count=1, flags=re.MULTILINE)

roadmap_section = f"""## Milestones

- Milestone 1: Prove the selected starter blueprint
  Outcome: {milestone_summary}
  Dependencies: selected blueprint alignment, product-brief truth, and one real validation path
  Risks: overbuilding before the first slice is proven
- Milestone 2: Expand the core workflow set
  Outcome: add the next highest-value workflow on top of the proven blueprint without breaking the first slice
  Dependencies: stable contracts from milestone 1, clearer product truth, and validated runtime boundaries
  Risks: architecture drift, premature breadth, and inconsistent UX or operator flow
- Milestone 3: Hardening, packaging, and release readiness
  Outcome: raise validation depth, operational maturity, packaging quality, and release confidence for the chosen product shape
  Dependencies: milestone 1 and 2 proof, clearer deployment targets, and stronger security and observability posture
  Risks: release claims outrunning evidence, ops complexity, and performance regressions

## Notes"""
roadmap_text = re.sub(r"## Milestones\n\n.*?\n## Notes", roadmap_section, roadmap_text, count=1, flags=re.DOTALL)

if design_notes_path.exists() and quality_items:
    design_text = design_notes_path.read_text()
    design_text = replace_exact_line(design_text, "- tone:", f"- tone: {design_tone}")
    design_text = replace_exact_line(design_text, "- density:", "- density: focused on the first milestone, with enough context for the primary workflow and no clutter")
    design_text = replace_exact_line(design_text, "- interaction style:", f"- interaction style: {interaction_style}")
    design_text = replace_exact_line(design_text, "- visual character:", f"- visual character: {visual_character}")
    design_text = replace_exact_line(design_text, "- first-impression goal:", f"- first-impression goal: {first_impression_goal}")
    design_text = replace_exact_line(design_text, "- trust signal:", f"- trust signal: {trust_signal}")
    design_text = replace_exact_line(design_text, "- speed signal:", f"- speed signal: {speed_signal}")
    design_text = replace_exact_line(design_text, "- delight or memorability signal:", "- delight or memorability signal: cohesive product language across the blueprint's primary surfaces")
    design_text = replace_exact_line(design_text, "- guidance signal:", "- guidance signal: clear next actions, honest states, and no confusing dead ends in the first milestone")
    design_text = replace_exact_line(design_text, "- layout rhythm:", f"- layout rhythm: organize surfaces around the first proven workflow for `{blueprint_id}`")
    design_text = replace_exact_line(design_text, "- surface hierarchy:", "- surface hierarchy: primary milestone flow first, supporting actions second, advanced or operational controls last")
    design_text = replace_exact_line(design_text, "- navigation pattern:", "- navigation pattern: keep the first blueprint-aligned slice obvious and avoid burying the core path")
    design_text = replace_exact_line(design_text, "- component reuse pattern:", "- component reuse pattern: reuse primitives across the first milestone and only split variants when the surface genuinely diverges")
    design_text = replace_exact_line(design_text, "- empty states:", "- empty states: explain the next useful action and show the intended value of the first milestone")
    design_text = replace_exact_line(design_text, "- loading states:", "- loading states: keep progress visible and preserve layout stability for the primary flow")
    design_text = replace_exact_line(design_text, "- error states:", "- error states: be explicit, actionable, and honest about recovery paths")
    design_notes_path.write_text(design_text)

if architecture_notes_path.exists():
    architecture_text = architecture_notes_path.read_text()
    architecture_text = replace_exact_line(architecture_text, "- system boundaries:", f"- system boundaries: {repo_shape or blueprint_id}")
    architecture_text = replace_exact_line(architecture_text, "- major modules:", f"- major modules: {repo_shape or title}")
    architecture_text = replace_exact_line(architecture_text, "- highest-value seams:", f"- highest-value seams: {next_decision_gates}")
    architecture_text = replace_exact_line(architecture_text, "- primary data flows:", f"- primary data flows: {milestone_summary}")
    architecture_text = replace_exact_line(architecture_text, "- protected boundaries:", f"- protected boundaries: {architecture_summary}")
    architecture_text = replace_exact_line(architecture_text, "- modules that may change together:", "- modules that may change together: the modules participating in the first proven vertical slice")
    architecture_text = replace_exact_line(architecture_text, "- modules that should stay independent:", "- modules that should stay independent: runtime modules, ops or packaging scaffolds, and `_system/` governance surfaces")
    architecture_text = replace_exact_line(architecture_text, "- internal contracts that must remain stable:", f"- internal contracts that must remain stable: {next_decision_gates}")
    architecture_text = replace_exact_line(architecture_text, "- external contracts that need migration discipline:", f"- external contracts that need migration discipline: {validation_summary}")
    architecture_text = replace_exact_line(architecture_text, "- likely refactor zones:", "- likely refactor zones: the seams touched by the first blueprint-aligned slice until patterns stabilize")
    architecture_text = replace_exact_line(architecture_text, "- fragile coupling to watch:", "- fragile coupling to watch: shape drift that collapses runtime, domain, delivery, or packaging boundaries together")
    architecture_text = replace_exact_line(architecture_text, "- scaling or reliability pressure points:", f"- scaling or reliability pressure points: {quality_summary}")
    architecture_text = replace_exact_line(architecture_text, "- migrations likely to be needed later:", f"- migrations likely to be needed later: {next_decision_gates}")
    architecture_text = replace_exact_line(architecture_text, "- compatibility concerns:", "- compatibility concerns: expand the selected blueprint without breaking the first proven slice or stable contracts")
    architecture_text = replace_exact_line(architecture_text, "- rollback concerns:", "- rollback concerns: fall back to the smallest demonstrable slice and preserve stable interfaces while reshaping")
    architecture_notes_path.write_text(architecture_text)

if test_strategy_path.exists():
    test_text = test_strategy_path.read_text()
    for label, lane_items, markers in (
        ("format or lint", validation_lanes["format or lint"], ("no format or lint command inferred yet",)),
        ("typecheck", validation_lanes["typecheck"], ("no typecheck command inferred yet",)),
        ("unit tests", validation_lanes["unit tests"], ("no unit-test command inferred yet",)),
        ("integration tests", validation_lanes["integration tests"], ("no integration-test command inferred yet",)),
        ("end-to-end or smoke", validation_lanes["end-to-end or smoke"], ("no smoke command inferred yet",)),
        ("build or packaging checks", validation_lanes["build or packaging checks"], ("no build or packaging command inferred yet",)),
        ("security or policy checks", validation_lanes["security or policy checks"], ("no security or policy command inferred yet",)),
    ):
        lane_summary = join_unique(lane_items)
        if lane_summary:
            test_text = replace_if_placeholder(test_text, label, lane_summary, markers)

    test_text = replace_if_placeholder(
        test_text,
        "critical flows that must be proven",
        milestone_summary,
        ("primary user flow, startup or install path, and any high-risk surface touched by the change",),
    )
    test_text = replace_if_placeholder(
        test_text,
        "expected evidence for high-risk changes",
        f"{validation_summary} | exact commands run and pass or fail outcomes for the first proven slice",
        (
            "exact commands run, pass or fail outcomes, notable warnings, and any skipped lanes with reasons",
            "where_left_off.md",
            "handoff_protocol",
        ),
    )
    test_text = replace_one_of(
        test_text,
        [
            "- None recorded yet.",
            "- Confirm the seeded validation lanes against the first real repo-local run and record any missing coverage explicitly.",
        ],
        "- Confirm the blueprint-aligned validation lanes against the first real repo-local run and record any missing coverage explicitly.",
    )
    test_strategy_path.write_text(test_text)

if risk_register_path.exists():
    risk_text = risk_register_path.read_text()
    seeded_markers = (
        "Validation baseline is still partially inferred or unproven",
        "Generated delivery surfaces may not match the repo's real packaging and install needs yet",
        "Security and compliance posture is not yet repo-specific",
        "- None recorded yet.",
    )
    blueprint_risk_title = "Selected starter blueprint is not yet proven end to end"
    blueprint_risk = f"""- Risk: {blueprint_risk_title}
  Severity: High
  Area: architecture / scope
  Why it matters: `{blueprint_id}` assumes {next_decision_gates}, but the repo has not yet proven the first slice across {repo_shape or title}.
  Mitigation: Keep the first milestone narrow, align `PRODUCT_BRIEF.md`, `PLAN.md`, `TEST_STRATEGY.md`, and runtime code around the selected blueprint, and prove {validation_summary}.
  Trigger to revisit: After the first blueprint-aligned vertical slice passes, if one surface forces a contract change, or if product scope starts fighting the chosen blueprint.
  Owner: current maintainer or active agent"""
    if blueprint_risk_title not in risk_text and any(marker in risk_text for marker in seeded_markers):
        if "## Watch list" in risk_text:
            risk_text = risk_text.replace("## Watch list", f"{blueprint_risk}\n\n## Watch list", 1)
        elif "## Active risks\n" in risk_text:
            risk_text = risk_text.replace("## Active risks\n", f"## Active risks\n\n{blueprint_risk}\n\n", 1)
        risk_register_path.write_text(risk_text)

if todo_path.exists():
    todo_text = todo_path.read_text()
    todo_text = replace_one_of(
        todo_text,
        [
            "- [ ] HIGH: Define the repo's next concrete outcome",
            f"- [ ] HIGH: Establish the first validated baseline for {app_name}",
            "- [ ] Define the repo's next concrete outcome",
            f"- [ ] Establish the first validated baseline for {app_name}",
        ],
        f"- [ ] HIGH: Build the first blueprint-aligned vertical slice for {app_name}",
    )
    todo_text = replace_one_of(
        todo_text,
        [
            "- [ ] HIGH: Review the recommended starter blueprint and explicitly apply it if the repo is still greenfield",
            "- [ ] Review the recommended starter blueprint and explicitly apply it if the repo is still greenfield",
        ],
        f"- [x] HIGH: Reviewed and explicitly applied the starter blueprint: {blueprint_id}",
    )
    todo_text = replace_exact_line(
        todo_text,
        "- [ ] MEDIUM: Establish the first real milestone in `PLAN.md`",
        "- [x] MEDIUM: Established the first real milestone in `PLAN.md`",
    )
    todo_text = replace_one_of(
        todo_text,
        [
            "- [ ] MEDIUM: Replace remaining neutral prompts with repo-specific truth after install",
            f"- [ ] MEDIUM: Finish onboarding and confirm the first working validation path for {app_name}",
            "- [ ] Replace remaining neutral prompts with repo-specific truth after install",
            f"- [ ] Finish onboarding and confirm the first working validation path for {app_name}",
        ],
        "- [ ] HIGH: Prove the initial validation focus recorded in `PRODUCT_BRIEF.md` and `TEST_STRATEGY.md`",
    )
    todo_text = replace_one_of(
        todo_text,
        [
            "- [ ] LOW: Keep working files current as the repo evolves",
            "- [ ] MEDIUM: Begin the first product or platform milestone once onboarding is complete",
            "- [ ] Keep working files current as the repo evolves",
            "- [ ] Begin the first product or platform milestone once onboarding is complete",
        ],
        "- [ ] MEDIUM: Keep `PRODUCT_BRIEF.md`, `PLAN.md`, `TEST_STRATEGY.md`, and `WHERE_LEFT_OFF.md` aligned as the first slice lands",
    )
    todo_path.write_text(todo_text)

if where_left_off_path.exists():
    where_text = where_left_off_path.read_text()
    where_text = replace_one_of(
        where_text,
        [
            "- Current phase: not set yet",
            "- Current phase: Onboarding",
        ],
        "- Current phase: Starter blueprint applied",
    )
    where_text = replace_one_of(
        where_text,
        [
            "- Completion status: not started — fill after first meaningful work session",
            "- Completion status: System installed, repo-specific truth still being established",
            "- Completion status: summarize the current state and anything intentionally untouched",
        ],
        "- Completion status: Selected starter blueprint applied across the first operating surfaces; the first vertical slice is the next proof step",
    )
    where_text = replace_one_of(
        where_text,
        [
            "- Resume confidence: low — no prior session recorded",
            "- Resume confidence: medium",
            "- Resume confidence: Medium",
            "- Resume confidence: record the handoff quality level",
        ],
        "- Resume confidence: high",
    )
    # Replace the "Last Completed Work" section content, including multi-line examples
    lw_section = re.search(
        r"(## Last Completed Work\s*\n)(.*?)(?=\n## |\Z)",
        where_text,
        re.DOTALL,
    )
    if lw_section:
        old_body = lw_section.group(2).strip()
        # Only replace if it still has template placeholder content
        if "Be concrete:" in old_body or "not set yet" in old_body.lower() or f"Installed the local AI operating system for {app_name}" in old_body or "Record the most recent" in old_body:
            where_text = where_text[:lw_section.start(2)] + f"\n- Applied starter blueprint `{blueprint_id}` and projected it into the repo's first operating surfaces.\n" + where_text[lw_section.end(2):]
    where_text = replace_one_of(
        where_text,
        [
            "- Command: (exact command run, e.g., `pytest tests/ -v`)",
            "- Command:",
        ],
        f"- Command: bootstrap/apply-starter-blueprint.sh <target-repo> --blueprint {blueprint_id}",
    )
    where_text = replace_one_of(
        where_text,
        [
            '- Result: (pass/fail with count, e.g., "12 passed, 0 failed")',
            "- Result:",
        ],
        f"- Result: starter blueprint `{blueprint_id}` applied successfully",
    )
    where_text = replace_one_of(
        where_text,
        [
            "- Scope: (what was covered and what remains unproven)",
            "- Scope:",
        ],
        "- Scope: PRODUCT_BRIEF.md, PLAN.md, ROADMAP.md, DESIGN_NOTES.md, TEST_STRATEGY.md, RISK_REGISTER.md, TODO.md, WHERE_LEFT_OFF.md, ARCHITECTURE_NOTES.md, and RELEASE_NOTES.md when present",
    )
    # Replace the multi-line "Decisions Made" placeholder with the blueprint decision
    for old in [
        "Record durable decisions made during the last pass. Move decisions with\nlong-term significance to `_system/context/DECISIONS.md`.",
        "Record durable decisions made during the last pass. Move decisions with\nlong-term significance to `_system/context/DECISIONS.md`.\n",
        "- Record durable decisions made during the last pass.",
    ]:
        if old in where_text:
            where_text = where_text.replace(old, f"- Selected starter blueprint: {blueprint_id} - {title}", 1)
            break
    # Replace the "Next Best Step" section content, including multi-line examples
    nbs_section = re.search(
        r"(## Next Best Step\s*\n)(.*?)(?=\n## |\Z)",
        where_text,
        re.DOTALL,
    )
    if nbs_section:
        old_nbs = nbs_section.group(2).strip()
        if "concrete instruction" in old_nbs or "Record the smallest" in old_nbs or "Refine `PRODUCT_BRIEF.md`" in old_nbs:
            where_text = where_text[:nbs_section.start(2)] + "\n- Build the first milestone captured in `PRODUCT_BRIEF.md` and prove the blueprint-aligned validation minimum.\n" + where_text[nbs_section.end(2):]
    _ph = ("which agent", "date of handoff", "what the session", "list of", "key commands", "1-3 sentence", "what could stop", "matches the section")
    where_text = replace_if_placeholder(
        where_text,
        "Agent",
        "bootstrap/apply-starter-blueprint.sh",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Timestamp",
        timestamp,
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Objective",
        f"Apply starter blueprint `{blueprint_id}` to the repo's first operating surfaces",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Files changed",
        "PRODUCT_BRIEF.md, PLAN.md, ROADMAP.md, DESIGN_NOTES.md, TEST_STRATEGY.md, RISK_REGISTER.md, TODO.md, WHERE_LEFT_OFF.md, ARCHITECTURE_NOTES.md, and RELEASE_NOTES.md when present",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Commands run",
        f"bootstrap/apply-starter-blueprint.sh <target-repo> --blueprint {blueprint_id}",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Result summary",
        f"Selected blueprint `{blueprint_id}` is now reflected in the first operating surfaces for {app_name}.",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Known blockers",
        "none recorded by blueprint application; prove the first slice next",
        _ph,
    )
    where_text = replace_if_placeholder(
        where_text,
        "Next best step",
        "Build the first milestone captured in `PRODUCT_BRIEF.md` and prove the blueprint-aligned validation minimum.",
        _ph,
    )
    where_left_off_path.write_text(where_text)

if release_notes_path.exists():
    release_text = release_notes_path.read_text()
    release_text = replace_label(release_text, "Target label", "starter-blueprint-alignment")
    release_text = replace_label(release_text, "Release goal", f"prove the first blueprint-aligned vertical slice for {app_name}")
    release_text = replace_label(release_text, "Release confidence", "not ready until the blueprint-aligned validation minimum is proven")
    release_text = replace_exact_line(release_text, "- None recorded yet.", "- Selected starter blueprint is in place, but the first real slice and validation evidence are still pending.")
    release_notes_path.write_text(release_text)

product_brief_path.write_text(brief_text)
plan_path.write_text(plan_text)
roadmap_path.write_text(roadmap_text)
PY

bash "${TARGET_REPO}/bootstrap/suggest-project-profile.sh" "${TARGET_REPO}" --write >/dev/null

echo "Applied starter blueprint ${BLUEPRINT_ID} to ${TARGET_REPO}"
