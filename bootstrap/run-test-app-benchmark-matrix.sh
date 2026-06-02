#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--root PATH] [--mode fast|strict|both] [--profiles CSV] [--archetypes CSV] [--limit-cells N] [--execute] [--apply] [--json]"
  exit 2
fi

repo="$1"; shift || true
root="${HOME}/.MyAppZ/_AIAST_TEST_APPS"
mode="both"
apply=0
execute=0
json_mode=0
profiles_csv="minimal,standard,advanced,super"
archetypes_csv="cli-tool,web-saas,local-first-desktop,ai-agent-app"
limit_cells=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) root="${2:-}"; shift 2 ;;
    --mode) mode="${2:-}"; shift 2 ;;
    --profiles) profiles_csv="${2:-}"; shift 2 ;;
    --archetypes) archetypes_csv="${2:-}"; shift 2 ;;
    --limit-cells) limit_cells="${2:-0}"; shift 2 ;;
    --execute) execute=1; shift ;;
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "run-test-app-benchmark-matrix.sh" "benchmark"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

if [[ "$mode" != "fast" && "$mode" != "strict" && "$mode" != "both" ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "mode must be fast|strict|both" "run-test-app-benchmark-matrix.sh" "benchmark"
  [[ "$json_mode" -eq 0 ]] && echo "mode must be fast|strict|both"
  exit 2
fi

if ! [[ "${limit_cells}" =~ ^[0-9]+$ ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "--limit-cells must be a non-negative integer" "run-test-app-benchmark-matrix.sh" "benchmark"
  [[ "$json_mode" -eq 0 ]] && echo "--limit-cells must be a non-negative integer"
  exit 2
fi

if ! aiaast_require_file "${repo}/bootstrap/init-project.sh"; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "missing_file" "missing bootstrap/init-project.sh in target repo" "run-test-app-benchmark-matrix.sh" "benchmark"
  exit 1
fi

read_csv() {
  local raw="$1"
  python3 - "$raw" <<'PY'
import sys
seen = set()
for item in sys.argv[1].split(","):
    value = item.strip()
    if not value or value in seen:
        continue
    seen.add(value)
    print(value)
PY
}

mapfile -t profiles < <(read_csv "${profiles_csv}")
mapfile -t archetypes < <(read_csv "${archetypes_csv}")
if [[ "${#profiles[@]}" -eq 0 || "${#archetypes[@]}" -eq 0 ]]; then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "profiles and archetypes must be non-empty" "run-test-app-benchmark-matrix.sh" "benchmark"
  [[ "$json_mode" -eq 0 ]] && echo "profiles and archetypes must be non-empty"
  exit 2
fi

if ! python3 - "${repo}" "$(IFS=,; echo "${profiles[*]}")" "$(IFS=,; echo "${archetypes[*]}")" <<'PY'
from __future__ import annotations
import json
import sys
from pathlib import Path

repo = Path(sys.argv[1])
profiles = [x for x in sys.argv[2].split(",") if x]
archetypes = [x for x in sys.argv[3].split(",") if x]
profile_path = repo / "_system" / "runtime-profiles" / "scaffold-profiles.json"
archetype_path = repo / "_system" / "archetypes" / "archetype-manifest.json"

known_profiles = {p.get("id") for p in json.loads(profile_path.read_text(encoding="utf-8")).get("profiles", [])}
known_archetypes = {a.get("id") for a in json.loads(archetype_path.read_text(encoding="utf-8")).get("archetypes", [])}

unknown_profiles = sorted(set(profiles) - known_profiles)
unknown_archetypes = sorted(set(archetypes) - known_archetypes)
if unknown_profiles or unknown_archetypes:
    print(json.dumps({"unknown_profiles": unknown_profiles, "unknown_archetypes": unknown_archetypes}), file=sys.stderr)
    raise SystemExit(1)
PY
then
  [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_matrix_dimension" "profile or archetype is not declared by the target repo" "run-test-app-benchmark-matrix.sh" "benchmark"
  [[ "$json_mode" -eq 0 ]] && echo "invalid matrix dimension"
  exit 1
fi

modes=(fast strict)
[[ "$mode" == "fast" ]] && modes=(fast)
[[ "$mode" == "strict" ]] && modes=(strict)

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
out_dir="${repo}/_META_AGENT_SYSTEM/evidence"
if [[ ! -d "${repo}/_META_AGENT_SYSTEM" && -d "${repo}/../_META_AGENT_SYSTEM" ]]; then
  out_dir="${repo}/../_META_AGENT_SYSTEM/evidence"
fi
mkdir -p "$out_dir"
json_out="${out_dir}/BENCHMARK_MATRIX_${stamp}.json"
md_out="${out_dir}/BENCHMARK_MATRIX_${stamp}.md"

matrix_root="${root%/}/matrix-${stamp}"
cleanup_matrix_root=0
if [[ "$execute" -eq 1 || "$apply" -eq 1 ]]; then
  mkdir -p "$matrix_root"
fi
if [[ "$execute" -eq 1 && "$apply" -eq 0 ]]; then
  cleanup_matrix_root=1
  trap 'rm -rf "$matrix_root"' EXIT
fi

cells_json_file="$(mktemp)"
echo "[]" > "${cells_json_file}"
pass_count=0
fail_count=0
cell_count=0

append_cell() {
  local row_json="$1"
  python3 - "$cells_json_file" "$row_json" <<'PY'
from __future__ import annotations
import json, sys
path = sys.argv[1]
row = json.loads(sys.argv[2])
data = json.loads(open(path, "r", encoding="utf-8").read())
data.append(row)
open(path, "w", encoding="utf-8").write(json.dumps(data))
PY
}

run_gate() {
  local name="$1"
  shift
  local start end dur rc out_file err_file
  out_file="$(mktemp)"
  err_file="$(mktemp)"
  start="$(date +%s)"
  set +e
  "$@" >"${out_file}" 2>"${err_file}"
  rc=$?
  set -e
  end="$(date +%s)"
  dur="$((end - start))"
  python3 - "$name" "$dur" "$rc" "$out_file" "$err_file" "$@" <<'PY'
from __future__ import annotations
import hashlib
import json
import sys
from pathlib import Path

name = sys.argv[1]
duration = int(sys.argv[2])
exit_code = int(sys.argv[3])
out_path = Path(sys.argv[4])
err_path = Path(sys.argv[5])
command = sys.argv[6:]
stdout = out_path.read_bytes()
stderr = err_path.read_bytes()

def tail_text(data: bytes, limit: int = 1600) -> str:
    if not data:
        return ""
    return data[-limit:].decode("utf-8", errors="replace")

payload = {
    "name": name,
    "command": command,
    "status": "pass" if exit_code == 0 else "fail",
    "required": True,
    "duration_sec": duration,
    "exit_code": exit_code,
    "stdout_bytes": len(stdout),
    "stderr_bytes": len(stderr),
    "stdout_sha256": hashlib.sha256(stdout).hexdigest(),
    "stderr_sha256": hashlib.sha256(stderr).hexdigest(),
}
if stdout:
    payload["stdout_tail"] = tail_text(stdout)
if stderr:
    payload["stderr_tail"] = tail_text(stderr)
print(json.dumps(payload, separators=(",", ":")))
PY
  rm -f "${out_file}" "${err_file}"
}

advisory_warn_gate() {
  local gate_json="$1"
  local reason="$2"
  python3 - "$gate_json" "$reason" <<'PY'
import json, sys
payload = json.loads(sys.argv[1])
payload["status"] = "warn"
payload["required"] = False
payload["warning_reason"] = sys.argv[2]
print(json.dumps(payload, separators=(",", ":")))
PY
}

skip_gate() {
  local name="$1"
  local reason="$2"
  python3 - "$name" "$reason" <<'PY'
import json, sys
print(json.dumps({
    "name": sys.argv[1],
    "status": "skipped",
    "required": True,
    "duration_sec": 0,
    "reason": sys.argv[2],
}, separators=(",", ":")))
PY
}

gate_status() {
  python3 - "$1" <<'PY'
import json, sys
print(json.loads(sys.argv[1]).get("status", "unknown"))
PY
}

cell_row() {
  python3 - "$@" <<'PY'
from __future__ import annotations
import json
import sys

cell = {
    "id": sys.argv[1],
    "profile": sys.argv[2],
    "archetype": sys.argv[3],
    "mode": sys.argv[4],
    "status": sys.argv[5],
    "executed": sys.argv[6] == "1",
    "isolated": sys.argv[7] == "1",
    "repo_dir": sys.argv[8],
    "repo_retained": sys.argv[9] == "1",
}
if sys.argv[10]:
    cell["app_name"] = sys.argv[10]
if sys.argv[11]:
    gates = json.loads(sys.argv[11])
    cell["gates"] = gates
    cell["gate_count"] = len(gates)
    cell["duration_sec"] = sum(int(g.get("duration_sec", 0)) for g in gates)
    cell["failed_gate_names"] = [
        str(g.get("name"))
        for g in gates
        if g.get("status") in ("fail", "skipped")
    ]
    cell["warning_gate_names"] = [
        str(g.get("name"))
        for g in gates
        if g.get("status") == "warn"
    ]
print(json.dumps(cell, separators=(",", ":")))
PY
}

json_list() {
  python3 - "$@" <<'PY'
import json, sys
print(json.dumps([json.loads(item) for item in sys.argv[1:]], separators=(",", ":")))
PY
}

for profile in "${profiles[@]}"; do
  for archetype in "${archetypes[@]}"; do
    for gate_mode in "${modes[@]}"; do
      if [[ "${limit_cells}" -gt 0 && "${cell_count}" -ge "${limit_cells}" ]]; then
        continue
      fi
      cell_count=$((cell_count + 1))
      cell_id="${profile}__${archetype}__${gate_mode}"
      if [[ "$execute" -eq 0 ]]; then
        status="planned"
        [[ "$apply" -eq 1 ]] && status="provisioned"
        row="$(cell_row "$cell_id" "$profile" "$archetype" "$gate_mode" "$status" 0 0 "" "$apply" "" "")"
        append_cell "$row"
        continue
      fi

      cell_dir="${matrix_root}/${cell_id}"
      cell_repo="${cell_dir}/repo"
      app_name="AIASTBench$(printf '%s' "${cell_id}" | tr -c '[:alnum:]' '_')"
      mkdir -p "$cell_dir"

      init_args=(bash "${SCRIPT_DIR}/init-project.sh" "${cell_repo}" --app-name "${app_name}")
      if [[ "${gate_mode}" == "strict" ]]; then
        init_args+=(--strict)
      fi

      g1="$(run_gate "scaffold_init" "${init_args[@]}")"
      if [[ "$(gate_status "$g1")" == "pass" ]]; then
        g2="$(run_gate "validate_scaffold_profile" bash "${cell_repo}/bootstrap/validate-scaffold-profile.sh" "${cell_repo}" --profile "${profile}" --json)"
        g3="$(run_gate "emit_archetype_pack" bash "${cell_repo}/bootstrap/emit-archetype-pack.sh" "${cell_repo}" --archetype "${archetype}" --json)"
        g4="$(run_gate "validate_archetype_packs" bash "${cell_repo}/bootstrap/validate-archetype-packs.sh" "${cell_repo}" --json)"
        if [[ "${gate_mode}" == "strict" ]]; then
          g5="$(run_gate "validate_system_strict" bash "${cell_repo}/bootstrap/validate-system.sh" "${cell_repo}" --strict)"
          g6="$(run_gate "system_doctor" bash "${cell_repo}/bootstrap/system-doctor.sh" "${cell_repo}")"
          if [[ "$(gate_status "$g6")" == "fail" ]] && python3 - <<'PY' "$g6"
import json, sys
payload = json.loads(sys.argv[1])
blob = "\n".join([payload.get("stdout_tail", ""), payload.get("stderr_tail", "")])
raise SystemExit(0 if "system_doctor_warn" in blob else 1)
PY
          then
            g6="$(advisory_warn_gate "$g6" "system_doctor_warn")"
          fi
        else
          g5="$(run_gate "check_system_awareness" bash "${cell_repo}/bootstrap/check-system-awareness.sh" "${cell_repo}")"
          g6="$(run_gate "score_quality_gates" bash "${cell_repo}/bootstrap/score-quality-gates.sh" "${cell_repo}" --json)"
        fi
      else
        g2="$(skip_gate "validate_scaffold_profile" "scaffold_init_failed")"
        g3="$(skip_gate "emit_archetype_pack" "scaffold_init_failed")"
        g4="$(skip_gate "validate_archetype_packs" "scaffold_init_failed")"
        g5="$(skip_gate "$([[ "${gate_mode}" == "strict" ]] && echo validate_system_strict || echo check_system_awareness)" "scaffold_init_failed")"
        g6="$(skip_gate "$([[ "${gate_mode}" == "strict" ]] && echo system_doctor || echo score_quality_gates)" "scaffold_init_failed")"
      fi
      gates_json="$(json_list "$g1" "$g2" "$g3" "$g4" "$g5" "$g6")"
      overall="pass"
      python3 - <<'PY' "$gates_json" || overall="fail"
import json,sys
for gate in json.loads(sys.argv[1]):
    if gate.get("status") == "pass":
        continue
    if gate.get("status") == "warn" and gate.get("required") is False:
        continue
    if gate.get("status") != "pass":
        raise SystemExit(1)
PY
      if [[ "$overall" == "pass" ]]; then
        pass_count=$((pass_count + 1))
      else
        fail_count=$((fail_count + 1))
      fi
      row="$(cell_row "$cell_id" "$profile" "$archetype" "$gate_mode" "$overall" 1 1 "$cell_repo" "$apply" "$app_name" "$gates_json")"
      append_cell "$row"
    done
  done
done

python3 - <<'PY' "$json_out" "$md_out" "$ts" "$matrix_root" "$apply" "$execute" "$cleanup_matrix_root" "$limit_cells" "$(IFS=,; echo "${profiles[*]}")" "$(IFS=,; echo "${archetypes[*]}")" "$(IFS=,; echo "${modes[*]}")" "$cells_json_file" "$pass_count" "$fail_count"
from __future__ import annotations
import json
import sys
from pathlib import Path

json_out = Path(sys.argv[1]).resolve()
md_out = Path(sys.argv[2]).resolve()
ts = sys.argv[3]
matrix_root = sys.argv[4]
apply = sys.argv[5] == "1"
execute = sys.argv[6] == "1"
transient_cleanup = sys.argv[7] == "1"
limit_cells = int(sys.argv[8])
profiles = [x for x in sys.argv[9].split(",") if x]
archetypes = [x for x in sys.argv[10].split(",") if x]
modes = [x for x in sys.argv[11].split(",") if x]
cells = json.loads(Path(sys.argv[12]).read_text(encoding="utf-8"))
pass_count = int(sys.argv[13])
fail_count = int(sys.argv[14])

payload = {
    "timestamp": ts,
    "matrix_root": matrix_root,
    "apply_mode": apply,
    "execute_mode": execute,
    "isolation_strategy": "per-cell-scaffold" if execute else "none",
    "cell_repo_retention": "retained" if apply else ("transient" if execute else "not-created"),
    "transient_cleanup": transient_cleanup,
    "profiles": profiles,
    "archetypes": archetypes,
    "modes": modes,
    "limit_cells": limit_cells,
    "total_cells": len(cells),
    "pass_count": pass_count,
    "fail_count": fail_count,
    "cells": cells,
}
json_out.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

lines = [
    "# Benchmark Matrix Report",
    "",
    f"- timestamp: `{ts}`",
    f"- apply_mode: `{apply}`",
    f"- execute_mode: `{execute}`",
    f"- isolation_strategy: `{payload['isolation_strategy']}`",
    f"- cell_repo_retention: `{payload['cell_repo_retention']}`",
    f"- matrix_root: `{matrix_root}`",
    f"- total_cells: `{len(cells)}`",
    f"- pass_count: `{pass_count}`",
    f"- fail_count: `{fail_count}`",
    "",
    "## Matrix dimensions",
    "",
    f"- profiles: `{', '.join(profiles)}`",
    f"- archetypes: `{', '.join(archetypes)}`",
    f"- modes: `{', '.join(modes)}`",
    "",
    "## Cell summary",
    "",
]
for c in cells:
    gate_count = c.get("gate_count", 0)
    duration = c.get("duration_sec", 0)
    failed = ", ".join(c.get("failed_gate_names", [])) or "none"
    warnings = ", ".join(c.get("warning_gate_names", [])) or "none"
    lines.append(f"- `{c['id']}` -> status `{c['status']}`; gates `{gate_count}`; duration `{duration}s`; failed `{failed}`; warnings `{warnings}`")
md_out.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
rm -f "${cells_json_file}"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"json\":\"${json_out}\",\"markdown\":\"${md_out}\"}" "run-test-app-benchmark-matrix.sh" "benchmark"
else
  echo "benchmark_matrix_ok json=${json_out} markdown=${md_out}"
fi
