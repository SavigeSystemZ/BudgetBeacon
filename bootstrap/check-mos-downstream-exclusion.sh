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
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "check-mos-downstream-exclusion.sh" "validation"
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

if ! python3 - <<'PY' "${render_json_file}"
from __future__ import annotations

import json
import sys
from pathlib import Path

payload = json.loads(Path(sys.argv[1]).read_text())
blocked_prefixes = (
    "MOS_TEMPLATE/",
    "MOS_SOURCE_LIBRARY/",
    "_META_AGENT_SYSTEM/",
    "_TEMPLATE_FACTORY/",
    "_MOS_TEMPLATE_FACTORY/",
)
leaks = [rel for rel in payload.get("files", []) if str(rel).startswith(blocked_prefixes)]
if leaks:
    for rel in leaks:
        print(f"MOS/meta source leak: {rel}", file=sys.stderr)
    raise SystemExit(1)
PY
then
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "mos_downstream_leak" "MOS or meta source layer selected for scaffold" "check-mos-downstream-exclusion.sh" "validation"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "MOS downstream exclusion: FAIL" >&2
  exit 1
fi

if [[ "${JSON_MODE}" -eq 1 ]]; then
  aiaast_json_ok "{\"profile\":\"${PROFILE}\"}" "check-mos-downstream-exclusion.sh" "validation"
else
  echo "MOS downstream exclusion: PASS (${PROFILE})"
fi
