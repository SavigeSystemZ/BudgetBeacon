#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: report-health-trends.sh <target-repo> [--json]

Read health-history.json and report validation trends.
EOF
}

TARGET=""
JSON_OUTPUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUTPUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [[ -z "${TARGET}" ]]; then
        TARGET="$1"; shift
      else
        echo "Unexpected argument: $1" >&2; exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  usage; exit 1
fi

python3 - <<'PY' "${TARGET}" "${JSON_OUTPUT}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
json_output = sys.argv[2] == "1"

history_path = repo / "_system" / "health-history.json"
if not history_path.is_file():
    if json_output:
        print('{"entries":0,"trend":"no_data"}')
    else:
        print("No health history found.")
    raise SystemExit(0)

entries = json.loads(history_path.read_text())
if not isinstance(entries, list) or len(entries) == 0:
    if json_output:
        print('{"entries":0,"trend":"no_data"}')
    else:
        print("Health history is empty.")
    raise SystemExit(0)

total = len(entries)
passes = sum(1 for e in entries if e.get("result") == "ok")
warns = sum(1 for e in entries if e.get("result") == "warn")
fails = sum(1 for e in entries if e.get("result") == "fail")

# Determine trend from last 5 entries
recent = entries[-5:]
recent_passes = sum(1 for e in recent if e.get("result") == "ok")

if recent_passes == len(recent):
    trend = "stable_healthy"
elif recent_passes >= len(recent) * 0.6:
    trend = "mostly_healthy"
elif recent_passes >= len(recent) * 0.3:
    trend = "degrading"
else:
    trend = "unhealthy"

last_entry = entries[-1]
last_time = last_entry.get("timestamp", "unknown")
last_result = last_entry.get("result", "unknown")

if json_output:
    print(json.dumps({
        "entries": total,
        "passes": passes,
        "warnings": warns,
        "failures": fails,
        "trend": trend,
        "last_check": last_time,
        "last_result": last_result,
    }))
else:
    print(f"Health History: {total} entries")
    print(f"  Passes: {passes}  Warnings: {warns}  Failures: {fails}")
    print(f"  Trend:  {trend}")
    print(f"  Last:   {last_result} at {last_time}")
    print(f"\nhealth_trend: {trend}")
PY
