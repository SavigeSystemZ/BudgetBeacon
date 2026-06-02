#!/usr/bin/env bash
# check-local-self-improvement.sh
#
# Audits the project-local self-improvement subsystem: shipped structure,
# ledger integrity, and that every applied change stayed inside the repo
# boundary. Role-aware and advisory.
# See _system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md.
#
# Usage: check-local-self-improvement.sh [target-repo] [--json]
# Exit: 0 = ok, 1 = issues detected, 2 = bad invocation.
set -euo pipefail

TARGET="."
JSON=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    -h|--help) echo "Usage: check-local-self-improvement.sh [target-repo] [--json]"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${JSON}" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
as_json = sys.argv[2] == "1"
issues = []

role = "downstream-app"
role_file = repo / "_system/.aiast-role.json"
if role_file.is_file():
    try:
        role = (json.loads(role_file.read_text()).get("role") or "").strip() or "downstream-app"
    except Exception:
        role = "downstream-app"

si = repo / "_system/self-improvement"

# Structure shipped by the template -- required in every role.
if not (si / "README.md").is_file():
    issues.append("missing _system/self-improvement/README.md")
for sub in ("proposals", "applied", "rejected"):
    if not (si / sub).is_dir():
        issues.append(f"missing _system/self-improvement/{sub}/")
for doc in ("PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md",
            "SELF_WRITING_BOUNDARY_AND_ROLLBACK.md"):
    if not (repo / "_system" / doc).is_file():
        issues.append(f"missing _system/{doc}")

# Ledger integrity + boundary audit (downstream runtime record).
ledger = si / "ledger.jsonl"
entries = 0
if ledger.is_file():
    for n, line in enumerate(ledger.read_text().splitlines(), 1):
        line = line.strip()
        if not line:
            continue
        try:
            rec = json.loads(line)
        except Exception:
            issues.append(f"ledger.jsonl line {n}: malformed JSON")
            continue
        entries += 1
        for field in ("ts", "id", "status"):
            if field not in rec:
                issues.append(f"ledger.jsonl line {n}: missing '{field}'")
        for cf in rec.get("changed_files", []) or []:
            parts = str(cf).split("/")
            if str(cf).startswith("/") or ".." in parts or "_AI_AGENT_SYSTEM_TEMPLATE" in parts:
                issues.append(
                    f"ledger.jsonl line {n}: changed file escapes the repo boundary: {cf}"
                )

applied = []
if (si / "applied").is_dir():
    applied = sorted((si / "applied").glob("*-applied.md"))

if as_json:
    print(json.dumps({
        "ok": not issues,
        "role": role,
        "ledger_entries": entries,
        "applied_records": len(applied),
        "issues": issues,
    }))
else:
    if issues:
        print("self_improvement_issues_detected")
        for it in issues:
            print(f"- {it}")
    else:
        print(f"self_improvement_ok role={role} ledger_entries={entries} applied={len(applied)}")

sys.exit(1 if issues else 0)
PY
