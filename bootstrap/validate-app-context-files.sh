#!/usr/bin/env bash
# validate-app-context-files.sh
#
# Validates the app-specific context pack. Role/state-aware:
#   parent-template            -> not applicable (sanity-checks the shipped
#                                 library only)
#   downstream, app undefined  -> advisory (exit 0)
#   downstream, app defined    -> enforced: universal + materialized archetype
#                                 context files must exist; --strict also
#                                 fails on files left as placeholders.
# See _system/APP_CONTEXT_FILE_MATRIX.md.
#
# Usage: validate-app-context-files.sh [target-repo] [--json] [--strict]
# Exit: 0 ok / not-applicable / advisory; 1 issues; 2 bad invocation.
set -euo pipefail

TARGET="."
JSON=0
STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help) echo "Usage: validate-app-context-files.sh [target-repo] [--json] [--strict]"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${JSON}" "${STRICT}" <<'PY'
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
as_json = sys.argv[2] == "1"
strict = sys.argv[3] == "1"
PLACEHOLDER = "TEMPLATE PLACEHOLDER"
ac = repo / "_system/app-context"


def role_of():
    rf = repo / "_system/.aiast-role.json"
    if rf.is_file():
        try:
            return (json.loads(rf.read_text()).get("role") or "").strip() or "downstream-app"
        except Exception:
            return "downstream-app"
    return "downstream-app"


def app_has_source():
    src = repo / "app" / "src"
    if not src.is_dir():
        return False
    for p in src.rglob("*"):
        if p.is_file() and p.name not in ("README.md", ".gitkeep"):
            return True
    return False


def emit(state, result, lines, exit_code):
    if as_json:
        print(json.dumps({"ok": exit_code == 0, "role": role, "state": state,
                          "result": result, "issues": lines}))
    else:
        print(f"app_context_validation {result} state={state}")
        for it in lines:
            print(f"- {it}")
    sys.exit(exit_code)


role = role_of()

# parent-template -> not applicable; sanity-check the shipped library only.
if role == "parent-template":
    issues = []
    if not (ac / "README.md").is_file():
        issues.append("missing _system/app-context/README.md")
    if not (ac / "templates" / "archetype").is_dir():
        issues.append("missing _system/app-context/templates/archetype/")
    uni = [p for p in ac.glob("*.md") if p.name != "README.md"]
    if len(uni) < 8:
        issues.append(f"expected >=8 universal app-context files, found {len(uni)}")
    emit("meta_template", "issues_detected" if issues else "not_applicable",
         issues, 1 if issues else 0)

# downstream-app, app not defined yet -> advisory.
if not app_has_source():
    emit("blank_app_undefined", "advisory",
         ["app not defined yet; fill app-context after defining the app and "
          "selecting an archetype (see APP_CONTEXT_FILE_MATRIX.md)"], 0)

# downstream-app, app defined -> enforce.
issues = []      # hard: missing structure
warnings = []    # soft: present but still a placeholder

universal = sorted(p for p in ac.glob("*.md") if p.name != "README.md")
if len(universal) < 8:
    issues.append(
        f"expected >=8 universal app-context files in _system/app-context/, "
        f"found {len(universal)}"
    )
for p in universal:
    if PLACEHOLDER in p.read_text():
        warnings.append(f"universal app-context file still a placeholder: "
                        f"_system/app-context/{p.name}")

arch_dir = ac / "archetype"
materialized = sorted(arch_dir.glob("*.md")) if arch_dir.is_dir() else []
if not materialized:
    issues.append("no archetype context files materialized -- run "
                   "bootstrap/generate-app-context-pack.sh")
for p in materialized:
    if PLACEHOLDER in p.read_text():
        warnings.append(f"archetype context file still a placeholder: "
                        f"_system/app-context/archetype/{p.name}")

hard = list(issues)
if strict:
    hard += warnings
display = issues + warnings
result = "ok" if not display else "issues_detected"
emit("app_defined", result, display, 1 if hard else 0)
PY
