#!/usr/bin/env bash
# check-host-settings-baseline.sh
#
# S19a — host-settings baseline linter.
#
# Walks the host_settings block in _system/host-adapter-manifest.json and
# asserts that for every adapter with status == "active":
#   - preserve_first file exists and is parseable
#   - meta_managed (.aiaast.*) file exists, is parseable, and carries the
#     "$aiaast" marker block with managed_by="_AI_AGENT_SYSTEM_TEMPLATE"
#
# Adapters with status == "planned_*" or "out_of_scope" are reported but
# do not fail the lint.
#
# JSON envelope on --json:
#   { "ok": bool,
#     "result": "host_settings_baseline_ok" | "host_settings_baseline_failed",
#     "summary": { "active": int, "passing": int, "failing": int,
#                  "planned": int, "out_of_scope": int },
#     "adapters": [
#       { "name": str, "status": str, "preserve_first": {...},
#         "meta_managed": {...}, "ok": bool, "failures": [str,...] }
#     ]
#   }
#
# Failure codes: file_missing, parse_error, marker_missing.

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

TARGET="${1:-}"
EMIT_JSON=0
shift_count=0
if [[ -n "${TARGET}" && "${TARGET}" != --* ]]; then
  shift_count=1
fi
shift "${shift_count}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) EMIT_JSON=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: check-host-settings-baseline.sh [TARGET] [--json]

Validates the host-settings baseline declared in
_system/host-adapter-manifest.json (host_settings block).
See _system/HOST_SETTINGS_BASELINE.md.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

export HSB_TARGET="${TARGET}"
export HSB_EMIT_JSON="${EMIT_JSON}"

python3 <<'PY'
import json, os, sys
from pathlib import Path

target = Path(os.environ["HSB_TARGET"])
emit_json = os.environ["HSB_EMIT_JSON"] == "1"

manifest_path = target / "_system/host-adapter-manifest.json"
if not manifest_path.exists():
    msg = f"host_settings_baseline_failed manifest_missing={manifest_path}"
    if emit_json:
        print(json.dumps({"ok": False, "result": "host_settings_baseline_failed",
                          "error": "manifest_missing"}))
    else:
        print(msg, file=sys.stderr)
    sys.exit(1)

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
hs = manifest.get("host_settings", {})
adapters = hs.get("adapters", {})

REQUIRED_MARKER_FIELDS = {"managed_by", "policy_doc", "preserve_first_sibling"}
EXPECTED_MANAGED_BY = "_AI_AGENT_SYSTEM_TEMPLATE"

def parse_file(p: Path, fmt: str):
    """Best-effort parse for json/toml. Returns (ok, payload_or_err)."""
    try:
        text = p.read_text(encoding="utf-8")
    except Exception as e:
        return False, f"read_error:{e}"
    if fmt == "json":
        try:
            return True, json.loads(text)
        except Exception as e:
            return False, f"json:{e}"
    if fmt == "toml":
        try:
            try:
                import tomllib  # py311+
            except ImportError:
                import tomli as tomllib  # type: ignore
            return True, tomllib.loads(text)
        except Exception as e:
            return False, f"toml:{e}"
    # unknown format — just check non-empty
    return True, {"_raw_len": len(text)}

results = []
active = passing = failing = planned = oos = 0

for name, cfg in sorted(adapters.items()):
    status = cfg.get("status", "")
    fmt = cfg.get("format", "json")
    pf_rel = cfg.get("preserve_first")
    mm_rel = cfg.get("meta_managed")
    entry = {
        "name": name, "status": status,
        "preserve_first": {"path": pf_rel, "exists": None, "parses": None},
        "meta_managed":   {"path": mm_rel, "exists": None, "parses": None,
                            "has_marker": None, "managed_by_ok": None},
        "ok": True, "failures": [],
    }

    if status == "out_of_scope":
        oos += 1
        results.append(entry); continue
    if status.startswith("planned_"):
        planned += 1
        # Don't fail-on-missing for planned adapters, but report current state.
        if pf_rel:
            entry["preserve_first"]["exists"] = (target / pf_rel).exists()
        if mm_rel:
            entry["meta_managed"]["exists"]   = (target / mm_rel).exists()
        results.append(entry); continue
    if status != "active":
        # unknown status — treat as failure
        entry["ok"] = False
        entry["failures"].append(f"unknown_status:{status}")
        failing += 1
        results.append(entry); continue

    active += 1
    failures = []

    # preserve-first
    if pf_rel:
        pf_path = target / pf_rel
        pf_exists = pf_path.exists()
        entry["preserve_first"]["exists"] = pf_exists
        if not pf_exists:
            failures.append(f"file_missing:{pf_rel}")
        else:
            ok, payload = parse_file(pf_path, fmt)
            entry["preserve_first"]["parses"] = ok
            if not ok:
                failures.append(f"parse_error:{pf_rel}:{payload}")

    # meta-managed
    if mm_rel:
        mm_path = target / mm_rel
        mm_exists = mm_path.exists()
        entry["meta_managed"]["exists"] = mm_exists
        if not mm_exists:
            failures.append(f"file_missing:{mm_rel}")
        else:
            ok, payload = parse_file(mm_path, fmt)
            entry["meta_managed"]["parses"] = ok
            if not ok:
                failures.append(f"parse_error:{mm_rel}:{payload}")
            elif isinstance(payload, dict):
                marker = payload.get("$aiaast")
                entry["meta_managed"]["has_marker"] = bool(marker)
                if not marker:
                    failures.append(f"marker_missing:{mm_rel}")
                else:
                    mb = marker.get("managed_by")
                    entry["meta_managed"]["managed_by_ok"] = (mb == EXPECTED_MANAGED_BY)
                    if mb != EXPECTED_MANAGED_BY:
                        failures.append(f"marker_managed_by_wrong:{mm_rel}:{mb}")
                    missing_fields = REQUIRED_MARKER_FIELDS - set(marker.keys())
                    if missing_fields:
                        failures.append(f"marker_fields_missing:{mm_rel}:{','.join(sorted(missing_fields))}")

    entry["ok"] = (len(failures) == 0)
    entry["failures"] = failures
    if entry["ok"]:
        passing += 1
    else:
        failing += 1
    results.append(entry)

ok_all = (failing == 0)
env = {
    "ok": ok_all,
    "result": "host_settings_baseline_ok" if ok_all else "host_settings_baseline_failed",
    "summary": {
        "active": active, "passing": passing, "failing": failing,
        "planned": planned, "out_of_scope": oos,
    },
    "adapters": results,
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    if ok_all:
        print(f"host_settings_baseline_ok active={active} passing={passing} planned={planned}")
    else:
        print(f"host_settings_baseline_failed failing={failing}", file=sys.stderr)
        for r in results:
            if not r["ok"] and r["status"] == "active":
                print(f"  {r['name']}: " + "; ".join(r["failures"]), file=sys.stderr)

sys.exit(0 if ok_all else 1)
PY
