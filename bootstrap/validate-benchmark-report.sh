#!/usr/bin/env bash
# validate-benchmark-report.sh
#
# Validates a BENCHMARK_MATRIX_*.json payload against the canonical schema.
# If no path is given, validates the most recent retained report under
# <repo>/_META_AGENT_SYSTEM/evidence/. Pure read; never executes the matrix.
#
# Usage:
#   validate-benchmark-report.sh <repo-root> [--report <path>] [--latest] [--json]
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <repo-root> [--report <path>] [--latest] [--json]"
  exit 2
fi

repo="$1"; shift || true
report=""
latest=0
json_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --report) report="$2"; shift 2 ;;
    --latest) latest=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "validate-benchmark-report.sh" "schema"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

schema="${repo}/_system/schemas/benchmark-matrix-report.schema.json"
if [[ ! -f "${schema}" ]]; then
  alt="${SCRIPT_DIR}/../_system/schemas/benchmark-matrix-report.schema.json"
  [[ -f "${alt}" ]] && schema="${alt}"
fi

if [[ -z "${report}" || "${latest}" -eq 1 ]]; then
  evidence_dir="${repo}/_META_AGENT_SYSTEM/evidence"
  if [[ ! -d "${evidence_dir}" ]]; then
    [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_evidence_dir" "${evidence_dir}" "validate-benchmark-report.sh" "schema"
    [[ "$json_mode" -eq 0 ]] && echo "missing evidence dir: ${evidence_dir}" >&2
    exit 1
  fi
  report="$(ls -1 "${evidence_dir}"/BENCHMARK_MATRIX_*.json 2>/dev/null | sort | tail -n1 || true)"
fi

if [[ -z "${report}" || ! -f "${report}" ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_report" "no benchmark report found" "validate-benchmark-report.sh" "schema"
  [[ "$json_mode" -eq 0 ]] && echo "no benchmark report found" >&2
  exit 1
fi

if [[ ! -f "${schema}" ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_schema" "${schema}" "validate-benchmark-report.sh" "schema"
  [[ "$json_mode" -eq 0 ]] && echo "missing schema: ${schema}" >&2
  exit 1
fi

py_out_file="$(mktemp)"
trap 'rm -f "${py_out_file}"' EXIT

if ! python3 - "${report}" "${schema}" >"${py_out_file}" <<'PY'
from __future__ import annotations
import json, re, sys

report_path, schema_path = sys.argv[1:]
with open(report_path, "r", encoding="utf-8") as fh:
    doc = json.load(fh)
with open(schema_path, "r", encoding="utf-8") as fh:
    schema = json.load(fh)

errors = []

def err(msg, where=""):
    errors.append({"path": where, "message": msg})

def check(node, sch, where="$"):
    t = sch.get("type")
    if t == "object":
        if not isinstance(node, dict):
            err(f"expected object, got {type(node).__name__}", where); return
        for k in sch.get("required", []):
            if k not in node:
                err(f"missing required key '{k}'", where)
        props = sch.get("properties", {})
        for k, v in node.items():
            if k in props:
                check(v, props[k], f"{where}.{k}")
    elif t == "array":
        if not isinstance(node, list):
            err(f"expected array, got {type(node).__name__}", where); return
        items = sch.get("items")
        if items:
            for i, el in enumerate(node):
                check(el, items, f"{where}[{i}]")
        if "minItems" in sch and len(node) < sch["minItems"]:
            err(f"minItems {sch['minItems']} violated (got {len(node)})", where)
    elif t == "string":
        if not isinstance(node, str):
            err(f"expected string, got {type(node).__name__}", where); return
        if "pattern" in sch and not re.search(sch["pattern"], node):
            err(f"pattern mismatch /{sch['pattern']}/", where)
        if "enum" in sch and node not in sch["enum"]:
            err(f"value '{node}' not in enum {sch['enum']}", where)
        if "minLength" in sch and len(node) < sch["minLength"]:
            err(f"minLength {sch['minLength']} violated", where)
    elif t == "integer":
        if not isinstance(node, int) or isinstance(node, bool):
            err(f"expected integer, got {type(node).__name__}", where); return
        if "minimum" in sch and node < sch["minimum"]:
            err(f"min {sch['minimum']} violated", where)
        if "maximum" in sch and node > sch["maximum"]:
            err(f"max {sch['maximum']} violated", where)
    elif t == "boolean":
        if not isinstance(node, bool):
            err(f"expected boolean, got {type(node).__name__}", where)
    if "anyOf" in sch:
        ok_any = False
        for alt in sch["anyOf"]:
            inner = []
            saved = errors[:]
            try:
                check(node, alt, where)
                if len(errors) == len(saved):
                    ok_any = True
                else:
                    inner = errors[len(saved):]
                    errors[:] = saved
            except Exception:
                errors[:] = saved
            if ok_any:
                break
        if not ok_any:
            err("none of anyOf alternatives matched", where)
    if t is None and "enum" in sch:
        if node not in sch["enum"]:
            err(f"value not in enum {sch['enum']}", where)

check(doc, schema)

# Cross-field invariants
cells = doc.get("cells", []) or []
declared_total = doc.get("total_cells", -1)
if declared_total != len(cells):
    err(f"total_cells={declared_total} but cells array length is {len(cells)}", "$")
declared_pass = doc.get("pass_count", -1)
actual_pass = sum(1 for c in cells if c.get("status") == "pass")
if declared_pass != actual_pass:
    err(f"pass_count={declared_pass} but pass cells={actual_pass}", "$")
declared_fail = doc.get("fail_count", -1)
actual_fail = sum(1 for c in cells if c.get("status") == "fail")
if declared_fail != actual_fail:
    err(f"fail_count={declared_fail} but fail cells={actual_fail}", "$")

print(json.dumps({
    "ok": len(errors) == 0,
    "report": report_path,
    "schema": schema_path,
    "error_count": len(errors),
    "errors": errors[:50],
    "cell_count": len(cells),
}))
PY
then
  rc=$?
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "validator_failed" "rc=${rc}" "validate-benchmark-report.sh" "schema"
  cat "${py_out_file}" >&2
  exit "${rc}"
fi

result="$(cat "${py_out_file}")"
ok="$(printf '%s' "${result}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ok"])')"

if [[ "${ok}" == "True" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_ok "${result}" "validate-benchmark-report.sh" "schema"
  else
    echo "benchmark_report_schema_ok"
  fi
  exit 0
else
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "schema_violations" "schema validation failed" "validate-benchmark-report.sh" "schema" "${result}"
  else
    echo "benchmark_report_schema_fail"
    echo "${result}"
  fi
  exit 1
fi
