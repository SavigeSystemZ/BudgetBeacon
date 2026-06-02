#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <template-or-repo-root> [--profile NAME] [--json]"
  exit 2
fi

ROOT="$1"
shift || true
PROFILE=""
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="${2:-}"; shift 2 ;;
    --json) JSON_MODE=1; shift ;;
    *)
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "check-scaffold-required-files.sh" "validation"
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

import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
payload = json.loads(Path(sys.argv[2]).read_text())
files = set(payload.get("files", []))
errors: list[str] = []

for rel in payload.get("required_files", []):
    rel = str(rel)
    if rel not in files:
        errors.append(f"required file not rendered: {rel}")
    if not (root / rel).is_file():
        errors.append(f"required file missing: {rel}")

if any(rel.startswith("_system/runtime/") for rel in files):
    errors.append("runtime code must not be scaffolded under _system/runtime/")

if any(rel.endswith("/.env") or rel == ".env" for rel in files):
    errors.append(".env must not be scaffolded")

if errors:
    for err in errors:
        print(err, file=sys.stderr)
    raise SystemExit(1)
PY
then
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "required_files_invalid" "scaffold required files check failed" "check-scaffold-required-files.sh" "validation"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "scaffold required files: FAIL" >&2
  exit 1
fi

if [[ "${JSON_MODE}" -eq 1 ]]; then
  aiaast_json_ok "{\"profile\":\"${PROFILE}\"}" "check-scaffold-required-files.sh" "validation"
else
  echo "scaffold required files: PASS (${PROFILE})"
fi
