#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: generate-host-adapters.sh [target-repo] [--write|--check]

Generate or verify tool-specific host adapter files from the canonical adapter manifest.
EOF
}

TARGET_REPO=""
WRITE=0
CHECK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)
      WRITE=1
      shift
      ;;
    --check)
      CHECK=1
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

if [[ ${WRITE} -eq 1 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

if [[ ${WRITE} -eq 1 && ${CHECK} -eq 1 ]]; then
  echo "Use either --write or --check, not both." >&2
  exit 1
fi

if [[ ${WRITE} -eq 0 && ${CHECK} -eq 0 ]]; then
  WRITE=1
fi

python3 - <<'PY' "${TARGET_REPO}" "${WRITE}" "${CHECK}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
write = sys.argv[2] == "1"
check = sys.argv[3] == "1"
manifest_path = repo / "_system" / "host-adapter-manifest.json"

if not manifest_path.is_file():
    print(f"Missing host adapter manifest: {manifest_path}", file=sys.stderr)
    raise SystemExit(1)

manifest = json.loads(manifest_path.read_text())
startup_files = manifest["canonical_startup_files"]
domain_files = manifest["domain_optional_files"]
golden_files = manifest["golden_example_files"]
adapter_specs = manifest["generated_adapters"]


def numbered(items: list[str]) -> list[str]:
    return [f"{idx}. `{item}`" for idx, item in enumerate(items, start=1)]


def bulleted(items: list[str]) -> list[str]:
    return [f"- `{item}`" for item in items]


def render_generic(spec: dict[str, object]) -> str:
    lines: list[str] = []
    title = str(spec.get("title", "")).strip()
    if title:
        lines.extend([f"# {title}", ""])

    lines.extend(str(item) for item in spec.get("intro_lines", []))
    lines.append("")

    load_heading = str(spec.get("load_heading", "")).strip()
    if load_heading:
        lines.append(load_heading)
    load_style = str(spec.get("load_style", "numbered"))
    load_lines = numbered(startup_files) if load_style == "numbered" else bulleted(startup_files)
    lines.extend(load_lines)
    lines.extend([
        "",
        "## Load More When Needed",
        "Load these when the task touches their domain:",
    ])
    lines.extend(bulleted(domain_files))
    lines.extend([
        "",
        "For system-evolution, prompt-authoring, adapter work, or working-file drafting, also load:",
    ])
    lines.extend(bulleted(golden_files))

    notes_heading = str(spec.get("notes_heading", "")).strip()
    notes = [str(item) for item in spec.get("notes", [])]
    if notes_heading and notes:
        lines.extend(["", notes_heading])
        lines.extend(f"- {item}" for item in notes)

    return "\n".join(lines).rstrip() + "\n"


def render_cursor_command(spec: dict[str, object]) -> str:
    lines = [*map(str, spec.get("intro_lines", []))]
    lines.append("")
    lines.extend(numbered(startup_files))
    lines.extend([
        "",
        "If capacity is tight, use the fast path in `_system/LOAD_ORDER.md`, confirm readiness, then continue with the working files.",
        "",
        "When the task touches design, architecture, research, testing, risk, or release, also load:",
    ])
    lines.extend(bulleted(domain_files))
    lines.extend([
        "",
        "If the task is greenfield, system-evolution, prompt-authoring, adapter work, or working-file authoring, also load:",
    ])
    lines.extend(bulleted(golden_files))
    return "\n".join(lines).rstrip() + "\n"


def render_cursor_skill(spec: dict[str, object]) -> str:
    name = str(spec["frontmatter_name"])
    description = str(spec["frontmatter_description"])
    lines = [
        "---",
        f"name: {name}",
        f"description: {description}",
        "---",
        "",
        "# Load Context",
        "",
        "## Steps",
    ]
    pre_steps = [str(item) for item in spec.get("pre_steps_lines", [])]
    if pre_steps:
        for line in pre_steps:
            lines.append(line)
        lines.append("")
    lines.extend(f"{idx}. Read `{item}`." for idx, item in enumerate(startup_files, start=1))
    next_idx = len(startup_files) + 1
    lines.extend([
        f"{next_idx}. If the task touches design, architecture, research, testing, risk, or release, also read `{domain_files[0]}`, `{domain_files[1]}`, `{domain_files[2]}`, `{domain_files[3]}`, `{domain_files[4]}`, `{domain_files[5]}`, `{domain_files[6]}`, and `{domain_files[7]}` as needed.",
        f"{next_idx + 1}. If the task is greenfield, system-evolution, prompt-authoring, adapter work, or working-file authoring, also read `{golden_files[0]}`, `{golden_files[1]}`, `{golden_files[2]}`, and `{golden_files[3]}`.",
        "",
        "## Output",
    ])
    lines.extend(f"- {item}" for item in spec["output_bullets"])
    return "\n".join(lines).rstrip() + "\n"


def render_cursor_session_command(spec: dict[str, object]) -> str:
    summary_items = [str(item) for item in spec.get("summary_items", [])]
    summary_clause = ", ".join(summary_items) if summary_items else "current operating picture"
    lines = [
        "Start the session by:",
        "",
        "1. running `/load-context` or manually loading the canonical context from `AGENTS.md` and `_system/LOAD_ORDER.md`",
        "2. reading `WHERE_LEFT_OFF.md`",
        "3. reading `TODO.md`, `FIXME.md`, and `PLAN.md`",
        "4. reading `TEST_STRATEGY.md` if implementation is likely",
        f"5. summarizing {summary_clause}",
    ]
    return "\n".join(lines).rstrip() + "\n"


def render_cursor_environment_command(spec: dict[str, object]) -> str:
    intro = [str(item) for item in spec.get("intro_lines", [])]
    lines = [*intro, "", "Recommended pre-write flow:", ""]
    lines.extend([
        "1. `bash bootstrap/check-working-directory-alignment.sh .`",
        "2. `bash bootstrap/check-project-target-consistency.sh .`",
        "3. `bash bootstrap/emit-session-environment.sh .`",
        "4. if mismatches are reported, halt writes and confirm target scope",
    ])
    lines.extend([
        "",
        "Optional JSON output for tooling:",
        "- `bash bootstrap/emit-session-environment.sh . --json`",
    ])
    return "\n".join(lines).rstrip() + "\n"


def render_aider(spec: dict[str, object]) -> str:
    lines: list[str] = [
        "# AIAST repo contract for Aider",
        "# See AGENTS.md for the full operating rules.",
        "#",
        "# These files are loaded into context at session start.",
        "",
        "read:",
    ]
    for item in startup_files:
        lines.append(f"  - {item}")
    lines.extend([
        "",
        "# Also load these when the task touches their domain:",
    ])
    for item in domain_files:
        lines.append(f"#  - {item}")
    lines.extend(["", "# Aider-specific conventions"])
    for item in spec.get("notes", []):
        lines.append(f"#  - {item}")
    return "\n".join(lines).rstrip() + "\n"


def render_cursor_rule(spec: dict[str, object]) -> str:
    description = str(spec.get("description", "")).strip()
    always_apply = "true" if bool(spec.get("always_apply", False)) else "false"
    lines = [
        "---",
        f'description: "{description}"',
        f"alwaysApply: {always_apply}",
        "---",
        "",
        "# Context Load",
        "",
        "Read the load order from `AGENTS.md` and `_system/LOAD_ORDER.md`.",
    ]
    for extra in spec.get("extra_lines", []):
        lines.append("")
        lines.append(str(extra))
    lines.extend([
        "",
        "If context appears reset, incomplete, or stale:",
        "",
        "1. reload the canonical docs",
        "2. confirm readiness",
        "3. only then continue with implementation",
    ])
    return "\n".join(lines).rstrip() + "\n"


renderers = {
    "generic_doc": render_generic,
    "aider_yaml": render_aider,
    "cursor_command": render_cursor_command,
    "cursor_skill": render_cursor_skill,
    "cursor_session_command": render_cursor_session_command,
    "cursor_environment_command": render_cursor_environment_command,
    "cursor_rule": render_cursor_rule,
}

rendered: dict[str, str] = {}
for name, spec in adapter_specs.items():
    kind = str(spec.get("kind", "")).strip()
    renderer = renderers.get(kind)
    if renderer is None:
        print(
            f"Host adapter {name!r}: unknown kind {kind!r}. "
            "Sync bootstrap/generate-host-adapters.sh from the template source "
            "or fix _system/host-adapter-manifest.json.",
            file=sys.stderr,
        )
        raise SystemExit(1)
    rendered[str(spec["path"])] = renderer(spec)

if check:
    issues: list[str] = []
    for rel_path, expected in rendered.items():
        path = repo / rel_path
        if not path.is_file():
            issues.append(f"Missing generated host adapter: {rel_path}")
            continue
        if path.read_text() != expected:
            issues.append(f"Stale generated host adapter: {rel_path}")
    if issues:
        print("host_adapters_out_of_date")
        for issue in issues:
            print(f"- {issue}")
        raise SystemExit(1)
    print("host_adapters_up_to_date")
    raise SystemExit(0)

for rel_path, content in rendered.items():
    path = repo / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)
    print(f"Wrote {rel_path}")

print("host_adapters_generated")
PY
