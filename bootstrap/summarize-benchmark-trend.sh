#!/usr/bin/env bash
# summarize-benchmark-trend.sh
#
# Scans retained BENCHMARK_MATRIX_*.json reports under an evidence directory
# and emits a deterministic trend summary (JSON + Markdown). Pure read; never
# scaffolds, never re-executes a matrix cell. Suitable for the standard lane.
#
# Usage:
#   summarize-benchmark-trend.sh <repo-root>
#       [--evidence-dir <dir>]
#       [--out-dir <dir>]
#       [--latest-n <int>]
#       [--json]
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <repo-root> [--evidence-dir <dir>] [--out-dir <dir>] [--latest-n <int>] [--json]"
  exit 2
fi

repo="$1"; shift || true
evidence_dir=""
out_dir=""
latest_n=0
json_mode=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --evidence-dir) evidence_dir="$2"; shift 2 ;;
    --out-dir) out_dir="$2"; shift 2 ;;
    --latest-n) latest_n="$2"; shift 2 ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "summarize-benchmark-trend.sh" "trend"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1" >&2
      exit 2
      ;;
  esac
done

[[ -n "${evidence_dir}" ]] || evidence_dir="${repo}/_META_AGENT_SYSTEM/evidence"
[[ -n "${out_dir}" ]] || out_dir="${evidence_dir}"

if [[ ! -d "${evidence_dir}" ]]; then
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "missing_evidence_dir" "no evidence directory at ${evidence_dir}" "summarize-benchmark-trend.sh" "trend"
  else
    echo "missing evidence dir: ${evidence_dir}" >&2
  fi
  exit 1
fi

mkdir -p "${out_dir}"

stamp="$(aiaast_iso_utc_now)"
trend_id="$(printf '%s' "${stamp}" | tr -d ':-')"
out_json="${out_dir}/BENCHMARK_TREND_${trend_id}.json"
out_md="${out_dir}/BENCHMARK_TREND_${trend_id}.md"

py_out_file="$(mktemp)"
trap 'rm -f "${py_out_file}"' EXIT

if ! python3 - "${evidence_dir}" "${out_json}" "${out_md}" "${latest_n}" "${stamp}" >"${py_out_file}" <<'PY'
from __future__ import annotations
import glob, hashlib, json, os, sys
from collections import defaultdict

evidence_dir, out_json, out_md, latest_n_raw, stamp = sys.argv[1:]
latest_n = int(latest_n_raw or 0)

paths = sorted(glob.glob(os.path.join(evidence_dir, "BENCHMARK_MATRIX_*.json")))
if not paths:
    print(json.dumps({"ok": False, "error": {"code": "no_reports", "message": f"no BENCHMARK_MATRIX_*.json in {evidence_dir}"}}))
    sys.exit(3)

reports = []
for p in paths:
    try:
        with open(p, "r", encoding="utf-8") as fh:
            reports.append((p, json.load(fh)))
    except Exception as e:
        print(json.dumps({"ok": False, "error": {"code": "parse_failed", "message": f"{p}: {e}"}}))
        sys.exit(4)

reports.sort(key=lambda kv: kv[1].get("timestamp", ""))
if latest_n > 0:
    reports = reports[-latest_n:]

per_cell_history = defaultdict(list)
totals = {"reports": len(reports), "cells": 0, "pass": 0, "fail": 0, "warn": 0, "skip": 0}
durations = []
report_summaries = []

for path, rep in reports:
    cells = rep.get("cells", []) or []
    rep_pass = rep.get("pass_count", 0)
    rep_fail = rep.get("fail_count", 0)
    rep_warn = sum(1 for c in cells if c.get("status") == "warn")
    rep_skip = sum(1 for c in cells if c.get("status") == "skip")
    rep_dur = sum(int(c.get("duration_sec", 0) or 0) for c in cells)
    durations.append(rep_dur)
    totals["cells"] += len(cells)
    totals["pass"] += rep_pass
    totals["fail"] += rep_fail
    totals["warn"] += rep_warn
    totals["skip"] += rep_skip
    report_summaries.append({
        "report": os.path.basename(path),
        "timestamp": rep.get("timestamp"),
        "modes": rep.get("modes", []),
        "profiles": rep.get("profiles", []),
        "archetypes": rep.get("archetypes", []),
        "total_cells": len(cells),
        "pass": rep_pass,
        "fail": rep_fail,
        "warn": rep_warn,
        "skip": rep_skip,
        "duration_sec": rep_dur,
    })
    for c in cells:
        cid = c.get("id") or f'{c.get("profile","?")}__{c.get("archetype","?")}__{c.get("mode","?")}'
        per_cell_history[cid].append({
            "timestamp": rep.get("timestamp"),
            "report": os.path.basename(path),
            "status": c.get("status"),
            "duration_sec": int(c.get("duration_sec", 0) or 0),
            "warning_gate_names": c.get("warning_gate_names", []) or [],
            "failed_gate_names": c.get("failed_gate_names", []) or [],
        })

regressions = []
recoveries = []
flaky = []
for cid, runs in per_cell_history.items():
    if len(runs) < 2:
        continue
    statuses = [r["status"] for r in runs]
    last, prev = statuses[-1], statuses[-2]
    if last == "fail" and prev in ("pass", "warn"):
        regressions.append({"cell": cid, "previous": prev, "current": last, "runs": runs[-3:]})
    if last in ("pass",) and prev == "fail":
        recoveries.append({"cell": cid, "previous": prev, "current": last, "runs": runs[-3:]})
    distinct = set(statuses)
    if len(distinct) >= 2 and "fail" in distinct and "pass" in distinct:
        flaky.append({"cell": cid, "history": statuses})

summary = {
    "schema": "aiaast-benchmark-trend-v1",
    "generated_at": stamp,
    "evidence_dir": evidence_dir,
    "report_count": totals["reports"],
    "cell_id_count": len(per_cell_history),
    "totals": totals,
    "duration_sec_total": sum(durations),
    "duration_sec_avg_per_report": (sum(durations) // max(1, len(durations))),
    "reports": report_summaries,
    "regressions": sorted(regressions, key=lambda r: r["cell"]),
    "recoveries": sorted(recoveries, key=lambda r: r["cell"]),
    "flaky_cells": sorted(flaky, key=lambda r: r["cell"]),
    "per_cell_latest": {
        cid: runs[-1] for cid, runs in sorted(per_cell_history.items())
    },
}

payload = json.dumps(summary, indent=2, sort_keys=True) + "\n"
with open(out_json, "w", encoding="utf-8") as fh:
    fh.write(payload)
sha = hashlib.sha256(payload.encode("utf-8")).hexdigest()

md = []
md.append(f"# Benchmark Trend Summary {stamp}")
md.append("")
md.append(f"- Evidence dir: `{evidence_dir}`")
md.append(f"- Reports analyzed: {totals['reports']}")
md.append(f"- Distinct cells observed: {len(per_cell_history)}")
md.append(f"- Total cells: {totals['cells']} (pass={totals['pass']}, fail={totals['fail']}, warn={totals['warn']}, skip={totals['skip']})")
md.append(f"- Total duration: {sum(durations)}s")
md.append(f"- Payload sha256: `{sha}`")
md.append("")
md.append("## Per-report")
md.append("")
md.append("| timestamp | report | cells | pass | fail | warn | skip | duration_s |")
md.append("|---|---|---|---|---|---|---|---|")
for r in report_summaries:
    md.append(f"| {r['timestamp']} | {r['report']} | {r['total_cells']} | {r['pass']} | {r['fail']} | {r['warn']} | {r['skip']} | {r['duration_sec']} |")
md.append("")
md.append(f"## Regressions ({len(regressions)})")
for r in summary["regressions"]:
    md.append(f"- `{r['cell']}` {r['previous']} → {r['current']}")
md.append("")
md.append(f"## Recoveries ({len(recoveries)})")
for r in summary["recoveries"]:
    md.append(f"- `{r['cell']}` {r['previous']} → {r['current']}")
md.append("")
md.append(f"## Flaky cells ({len(flaky)})")
for r in summary["flaky_cells"]:
    md.append(f"- `{r['cell']}`: {' → '.join(r['history'])}")
md.append("")
with open(out_md, "w", encoding="utf-8") as fh:
    fh.write("\n".join(md))

print(json.dumps({
    "ok": True,
    "out_json": out_json,
    "out_md": out_md,
    "report_count": totals["reports"],
    "cell_id_count": len(per_cell_history),
    "regression_count": len(regressions),
    "recovery_count": len(recoveries),
    "flaky_cell_count": len(flaky),
    "payload_sha256": sha,
}))
PY
then
  rc=$?
  if [[ "$json_mode" -eq 1 ]]; then
    aiaast_json_error "summarizer_failed" "trend summarizer exited rc=${rc}" "summarize-benchmark-trend.sh" "trend"
  else
    cat "${py_out_file}" >&2
    echo "trend summarizer failed (rc=${rc})" >&2
  fi
  exit "${rc}"
fi

result_json="$(cat "${py_out_file}")"
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "${result_json}" "summarize-benchmark-trend.sh" "trend"
else
  echo "benchmark_trend_ok"
  echo "${result_json}"
fi
