#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--json]"
  exit 2
fi

repo="$1"
json_mode=0
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-scaffold-profiles.sh" "validation"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

matrix="${repo}/_system/SCAFFOLD_PROFILE_MATRIX.md"
manifest="${repo}/_system/runtime-profiles/scaffold-profiles.json"

if ! aiaast_require_file "$matrix"; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing: $matrix" "validate-scaffold-profiles.sh" "validation"
  exit 1
fi
if ! aiaast_require_file "$manifest"; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing: $manifest" "validate-scaffold-profiles.sh" "validation"
  exit 1
fi

py_out_file="$(mktemp)"
if ! python3 - "$matrix" "$manifest" >"${py_out_file}" <<'PY'
import json, re, sys
matrix_path, manifest_path = sys.argv[1:]
matrix = open(matrix_path, "r", encoding="utf-8").read()
data = json.load(open(manifest_path, "r", encoding="utf-8"))
profiles = [p.get("id") for p in data.get("profiles", [])]
required = [
    ("included surfaces",),
    ("excluded surfaces",),
    ("required docs",),
    ("required validators",),
    ("default guardrails",),
    ("installer expectations",),
    ("port/network expectations",),
    ("runtime foundation expectations", "runtime expectations"),
    ("security/privacy baseline",),
    ("fleet compatibility",),
    ("downstream mutability",),
    ("quality score target",),
]
for pid in profiles:
    if not pid:
        raise SystemExit(1)
    if f"### `{pid}`" not in matrix:
        print(f"missing profile section in matrix: {pid}")
        raise SystemExit(1)
    start = matrix.index(f"### `{pid}`")
    end = matrix.find("\n### `", start + 1)
    chunk = matrix[start:] if end == -1 else matrix[start:end]
    for field_opts in required:
        if not any(f in chunk for f in field_opts):
            print(f"profile {pid} missing field marker: {field_opts[0]}")
            raise SystemExit(1)
print(json.dumps({"profiles_checked": len(profiles)}))
PY
then
  [[ "$json_mode" -eq 1 ]] && cat "${py_out_file}" >&2
  rm -f "${py_out_file}"
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "profile_contract_invalid" "scaffold profile contract validation failed" "validate-scaffold-profiles.sh" "validation"
  [[ "$json_mode" -eq 0 ]] && echo "scaffold profiles validation: FAIL"
  exit 1
fi
if [[ "$json_mode" -eq 0 ]]; then
  cat "${py_out_file}"
fi
rm -f "${py_out_file}"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok '{"status":"pass"}' "validate-scaffold-profiles.sh" "validation"
else
  echo "scaffold profiles validation: PASS"
fi
