#!/usr/bin/env bash
set -euo pipefail

TARGET_REPO="${1:-}"
MODE="${2:---write}"

if [[ -z "${TARGET_REPO}" || ! -d "${TARGET_REPO}" ]]; then
  echo "Usage: patch-agent-surface-contracts.sh <target-repo> [--write|--check]" >&2
  exit 1
fi

if [[ "${MODE}" != "--write" && "${MODE}" != "--check" ]]; then
  echo "Mode must be --write or --check" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}" "${MODE}"
from __future__ import annotations

import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
mode = sys.argv[2]

issues: list[str] = []
applied: list[str] = []


def ensure_after(path: Path, anchor: str, line: str) -> None:
    if not path.is_file():
        issues.append(f"missing file: {path.relative_to(repo)}")
        return
    text = path.read_text()
    if line in text:
        return
    idx = text.find(anchor)
    if idx == -1:
        issues.append(
            f"anchor not found in {path.relative_to(repo)}: {anchor}"
        )
        return
    insert_at = text.find("\n", idx)
    if insert_at == -1:
        insert_at = len(text)
    else:
        insert_at += 1
    updated = text[:insert_at] + line + "\n" + text[insert_at:]
    if mode == "--write":
        path.write_text(updated)
        applied.append(f"{path.relative_to(repo)}: inserted `{line}`")
    else:
        issues.append(f"missing required line in {path.relative_to(repo)}: {line}")


ensure_after(
    repo / "AGENTS.md",
    "- Use `_system/HOST_ADAPTER_POLICY.md`, `bootstrap/generate-host-adapters.sh`, and `bootstrap/check-host-adapter-alignment.sh` when tool-entry or adapter-load surfaces change.",
    "- Use `_system/AGENT_SURFACE_TAXONOMY.md` for canonical adapter file classes, naming, and placeholder rules.",
)
ensure_after(
    repo / "AGENTS.md",
    "- Use `_system/AGENT_SURFACE_TAXONOMY.md` for canonical adapter file classes, naming, and placeholder rules.",
    "- Use `_system/AGENT_INIT_CONVERGENCE.md` when merging external init patterns into installable repo contracts.",
)
ensure_after(
    repo / "_system" / "AGENT_DISCOVERY_MATRIX.md",
    "Tool-entry files and shared load-context overlays are governed by `_system/HOST_ADAPTER_POLICY.md` and may be regenerated via `bootstrap/generate-host-adapters.sh`. Validate them with `bootstrap/check-host-adapter-alignment.sh`.",
    "Canonical adapter classes, naming rules, and placeholder boundaries are defined in `_system/AGENT_SURFACE_TAXONOMY.md`. External initialization pattern ingestion is defined in `_system/AGENT_INIT_CONVERGENCE.md`.",
)

if issues:
    print("agent_surface_contract_patch_failed")
    for issue in issues:
        print(f"- {issue}")
    raise SystemExit(1)

if applied:
    print("agent_surface_contract_patch_applied")
    for item in applied:
        print(f"- {item}")
else:
    print("agent_surface_contract_patch_already_current")
PY
