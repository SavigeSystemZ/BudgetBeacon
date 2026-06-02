#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: validate-scaffold-output.sh <template-or-repo-root> [--profile NAME] [--dry-run] [--json]

Validate the rendered scaffold profile file set without writing to a target.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

ROOT="$1"
shift || true
PROFILE=""
DRY_RUN=0
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --json)
      JSON_MODE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-scaffold-output.sh" "validation"
      [[ "${JSON_MODE}" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd -- "${ROOT}" && pwd)"
PROFILE="$(aiaast_resolve_scaffold_profile "${ROOT}" "${PROFILE}")"

render_json="$(bash "${SCRIPT_DIR}/render-scaffold-profile.sh" "${ROOT}" --profile "${PROFILE}" --json)"
render_json_file="$(mktemp "${TMPDIR:-/tmp}/aiaast-scaffold-render.XXXXXX.json")"
trap 'rm -f "${render_json_file:-}"' EXIT
printf '%s' "${render_json}" > "${render_json_file}"

if ! python3 - <<'PY' "${ROOT}" "${render_json_file}"
from __future__ import annotations

import fnmatch
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
payload = json.loads(Path(sys.argv[2]).read_text())
files = set(payload.get("files", []))
required = [str(x) for x in payload.get("required_files", [])]
forbidden_patterns = [str(x) for x in payload.get("forbidden_downstream_paths", [])]

def matches(pattern: str, rel: str) -> bool:
    pattern = pattern.strip()
    if pattern.startswith("./"):
        pattern = pattern[2:]
    pattern = pattern.strip("/")
    if not pattern:
        return False
    if pattern in {"*", "**", "**/*"}:
        return True
    if pattern.endswith("/**"):
        prefix = pattern[:-3].rstrip("/")
        return rel == prefix or rel.startswith(prefix + "/")
    if "/" not in pattern and fnmatch.fnmatch(Path(rel).name, pattern):
        return True
    return fnmatch.fnmatch(rel, pattern)

errors = []
for rel in required:
    if rel not in files:
        errors.append(f"required file not selected: {rel}")
    elif not (root / rel).is_file():
        errors.append(f"required file missing on disk: {rel}")

for rel in files:
    for pattern in forbidden_patterns:
        if matches(pattern, rel):
            errors.append(f"forbidden path selected: {rel} (pattern {pattern})")
            break

if not files:
    errors.append("rendered scaffold output is empty")

if errors:
    for err in errors:
        print(err, file=sys.stderr)
    raise SystemExit(1)
PY
then
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "scaffold_output_invalid" "scaffold output validation failed" "validate-scaffold-output.sh" "validation"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "scaffold output validation: FAIL" >&2
  exit 1
fi

if [[ "${JSON_MODE}" -eq 1 ]]; then
  aiaast_json_ok "$(python3 - <<'PY' "${render_json_file}" "${DRY_RUN}"
import json, sys
from pathlib import Path
payload = json.loads(Path(sys.argv[1]).read_text())
print(json.dumps({
    "profile": payload["profile"],
    "file_count": payload["file_count"],
    "dry_run": sys.argv[2] == "1"
  }))
PY
)" "validate-scaffold-output.sh" "validation"
else
  count="$(python3 - <<'PY' "${render_json_file}"
import json, sys
from pathlib import Path
print(json.loads(Path(sys.argv[1]).read_text())["file_count"])
PY
)"
  echo "scaffold output validation: PASS profile=${PROFILE} files=${count} dry_run=${DRY_RUN}"
fi
