#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-placeholders.sh [target-repo] [--all] [--summary] [--mode auto|template|installed]
EOF
}

TARGET="."
SCAN_ALL=0
SUMMARY_ONLY=0
MODE="auto"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      SCAN_ALL=1
      shift
      ;;
    --summary)
      SUMMARY_ONLY=1
      shift
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      TARGET="$1"
      shift
      ;;
  esac
done

MODE="$(aiaast_resolve_repo_mode "${TARGET}" "${MODE}")"

placeholder_pattern='^- [A-Za-z0-9 /_-]+:\s*$'
absolute_path_pattern='/ABSOLUTE/PATH/TO/PROJECT'
hits=0
placeholder_count=0
absolute_path_count=0

placeholder_matches() {
  local path="$1"
  python3 - "$path" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
pattern = re.compile(r"^- [A-Za-z0-9 /_-]+:\s*$")
heading = re.compile(r"^##\s+(.+?)\s*$")

# Ignore schema-only sections so installed-repo scans focus on actionable blanks
# rather than the template examples that teach operators how to add entries.
ignore_section = False

for lineno, line in enumerate(path.read_text().splitlines(), start=1):
    match = heading.match(line)
    if match:
        title = match.group(1).strip().lower()
        ignore_section = title in {"entry format", "entry template"}
        continue
    if ignore_section:
        continue
    if pattern.match(line):
        print(f"{path}:{lineno}:{line}")
PY
}

critical_files=(
  "_system/PROJECT_PROFILE.md"
  "TODO.md"
  "FIXME.md"
  "WHERE_LEFT_OFF.md"
  "PLAN.md"
  "PRODUCT_BRIEF.md"
  "ROADMAP.md"
  "TEST_STRATEGY.md"
  "RISK_REGISTER.md"
  "RELEASE_NOTES.md"
  "_system/context/CURRENT_STATUS.md"
  "_system/context/DECISIONS.md"
  "_system/context/ASSUMPTIONS.md"
  "_system/context/OPEN_QUESTIONS.md"
  "_system/mcp/MCP_SERVER_CATALOG.md"
)

optional_files=(
  "DESIGN_NOTES.md"
  "ARCHITECTURE_NOTES.md"
  "RESEARCH_NOTES.md"
  "_system/context/INTEGRATION_SURFACES.md"
  "_system/context/QUALITY_DEBT.md"
)

scan_list=("${critical_files[@]}")
if [[ ${SCAN_ALL} -eq 1 ]]; then
  scan_list+=("${optional_files[@]}")
fi

for rel in "${scan_list[@]}"; do
  path="${TARGET}/${rel}"
  if [[ -f "${path}" ]]; then
    if matches="$(placeholder_matches "${path}")" && [[ -n "${matches}" ]]; then
      count="$(printf '%s\n' "${matches}" | wc -l | tr -d ' ')"
      placeholder_count=$((placeholder_count + count))
      hits=1
      if [[ ${SUMMARY_ONLY} -eq 0 ]]; then
        printf '%s\n' "${matches}"
      fi
    fi
    if matches="$(rg -n --with-filename "${absolute_path_pattern}" "${path}" || true)" && [[ -n "${matches}" ]]; then
      count="$(printf '%s\n' "${matches}" | wc -l | tr -d ' ')"
      absolute_path_count=$((absolute_path_count + count))
      hits=1
      if [[ ${SUMMARY_ONLY} -eq 0 ]]; then
        printf '%s\n' "${matches}"
      fi
    fi
  fi
done

if [[ ${absolute_path_count} -gt 0 ]]; then
  if [[ ${SUMMARY_ONLY} -eq 1 ]]; then
    echo "placeholder_hits_detected placeholders=${placeholder_count} absolute_paths=${absolute_path_count}" >&2
  else
    echo "placeholder_hits_detected" >&2
  fi
  exit 1
fi

if [[ ${hits} -eq 1 && "${MODE}" == "template" ]]; then
  echo "template_source_placeholders_expected placeholders=${placeholder_count} absolute_paths=${absolute_path_count}"
  exit 0
fi

if [[ ${hits} -eq 1 ]]; then
  if [[ ${SUMMARY_ONLY} -eq 1 ]]; then
    echo "placeholder_hits_detected placeholders=${placeholder_count} absolute_paths=${absolute_path_count}" >&2
  else
    echo "placeholder_hits_detected" >&2
  fi
  exit 1
fi

echo "no_placeholder_hits"
