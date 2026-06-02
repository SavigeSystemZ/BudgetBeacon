#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: render-scaffold-profile.sh <template-or-repo-root> [--profile NAME] [--json]

Render the relative file list selected by _system/scaffold-profiles.json.
Default output is one relative path per line.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

ROOT="$1"
shift || true
PROFILE=""
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      PROFILE="${2:-}"
      shift 2
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
      [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "render-scaffold-profile.sh" "scaffold"
      [[ "${JSON_MODE}" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

ROOT="$(cd -- "${ROOT}" && pwd)"
PROFILE="$(aiaast_resolve_scaffold_profile "${ROOT}" "${PROFILE}")"
MANIFEST="$(aiaast_scaffold_profile_manifest_path "${ROOT}")" || {
  [[ "${JSON_MODE}" -eq 1 ]] && aiaast_json_error "missing_manifest" "missing scaffold profile manifest" "render-scaffold-profile.sh" "scaffold"
  [[ "${JSON_MODE}" -eq 0 ]] && echo "missing scaffold profile manifest" >&2
  exit 1
}

python3 - <<'PY' "${ROOT}" "${MANIFEST}" "${PROFILE}" "${JSON_MODE}"
from __future__ import annotations

import fnmatch
import json
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
manifest_path = Path(sys.argv[2]).resolve()
profile_id = sys.argv[3]
json_mode = sys.argv[4] == "1"

data = json.loads(manifest_path.read_text(encoding="utf-8"))
base = data.get("base", {})
profiles = {item.get("id"): item for item in data.get("profiles", []) if isinstance(item, dict)}
profile = profiles.get(profile_id)
if profile is None:
    print(f"unknown scaffold profile: {profile_id}", file=sys.stderr)
    raise SystemExit(1)

def merged_list(key: str) -> list[str]:
    values: list[str] = []
    for item in base.get(key, []):
        if isinstance(item, str) and item not in values:
            values.append(item)
    for item in profile.get(key, []):
        if isinstance(item, str) and item not in values:
            values.append(item)
    return values

include = merged_list("include") or ["*", "**/*"]
exclude = merged_list("exclude")

def normalize(pattern: str) -> str:
    pattern = pattern.strip()
    if pattern.startswith("./"):
        pattern = pattern[2:]
    return pattern.strip("/")

def matches(pattern: str, rel: str) -> bool:
    pattern = normalize(pattern)
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

selected: list[str] = []
for path in sorted(p for p in root.rglob("*") if p.is_file()):
    rel = path.relative_to(root).as_posix()
    if rel.startswith(".git/") or "/.git/" in rel:
        continue
    if not any(matches(pattern, rel) for pattern in include):
        continue
    blocked = False
    for pattern in exclude:
        if pattern.startswith("!"):
            if matches(pattern[1:], rel):
                blocked = False
        elif matches(pattern, rel):
            blocked = True
    if not blocked:
        selected.append(rel)

if json_mode:
    payload = {
        "profile": profile_id,
        "manifest": str(manifest_path),
        "file_count": len(selected),
        "files": selected,
        "required_files": merged_list("required_files"),
        "forbidden_downstream_paths": merged_list("forbidden_downstream_paths"),
        "generated_files": merged_list("generated_files"),
        "required_validators": merged_list("required_validators"),
    }
    print(json.dumps(payload, indent=2, sort_keys=True))
else:
    for rel in selected:
        print(rel)
PY
