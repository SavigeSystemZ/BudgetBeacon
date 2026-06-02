#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  check-scaffold-isolation-gate.sh <repo-root>
        [--strict | --best-effort | --report-only]
        [--skip GATE_ID ...] [--manifest PATH]
        [--json]

Aggregate runner for the scaffold-isolation gates declared in
_system/scaffold-isolation-gates.json. Executes each gate in order;
collects per-step rc + duration + bleed-event delta; emits a single
JSON envelope.

Modes:
  --strict        first non-zero exit aborts; runner returns rc=1
  --best-effort   every gate runs; runner returns rc=0 even on failures
                  (default; matches scaffold-isolation-gates.json#/default_mode)
  --report-only   like --best-effort but rewrites every gate's args to
                  remove --emit-bleed-events so no events are appended

--skip GATE_ID may be passed repeatedly to exclude named gates.
Skipped gates show ok=true, skipped=true, reason="--skip".

The runner refuses to operate inside the AIAST parent template; the
underlying validators have their own role-sentinel gates as defence
in depth.

Envelope contract: see _system/SCAFFOLD_ISOLATION_COMPLETION_GATE.md
§"Envelope".
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

TARGET="$1"; shift
MODE=""
MANIFEST=""
JSON_MODE=0
SKIPS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict)       MODE="strict"; shift ;;
    --best-effort)  MODE="best-effort"; shift ;;
    --report-only)  MODE="report-only"; shift ;;
    --skip)         SKIPS+=("${2:-}"); shift 2 ;;
    --manifest)     MANIFEST="${2:-}"; shift 2 ;;
    --json)         JSON_MODE=1; shift ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"

SKIPS_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${SKIPS[@]:-}")"

python3 - "${TARGET}" "${MODE}" "${MANIFEST}" "${JSON_MODE}" "${SKIPS_JSON}" <<'PY'
from __future__ import annotations
import json, os, subprocess, sys, time
from datetime import datetime, timezone
from pathlib import Path

(target_s, mode_arg, manifest_arg, json_mode_s, skips_json) = sys.argv[1:6]
target = Path(target_s).resolve()
json_mode = json_mode_s == "1"
skips = set(json.loads(skips_json))

def emit(payload: dict, rc: int = 0) -> None:
    if json_mode:
        print(json.dumps(payload))
    else:
        # human summary
        print(f"scaffold-isolation-gate: mode={payload['mode']} "
              f"ok={payload['summary']['ok']}/{payload['summary']['total']} "
              f"failed={payload['summary']['failed']} "
              f"skipped={payload['summary']['skipped']} "
              f"bleed_events={payload['summary']['bleed_events_total']} "
              f"first_failure={payload['summary'].get('first_failure') or '-'}")
        for g in payload["gates"]:
            mark = "ok" if g["ok"] else ("skip" if g.get("skipped") else "FAIL")
            print(f"  [{mark:<4}] {g['id']:<32} rc={g['rc']} "
                  f"duration={g['duration_seconds']:.2f}s "
                  f"bleed={g['bleed_events_emitted']}")
    sys.exit(rc)

def fail_envelope(code: str, message: str, rc: int = 1) -> None:
    payload = {
        "ok": False,
        "script": "check-scaffold-isolation-gate.sh",
        "error": {"code": code, "message": message},
    }
    if json_mode:
        print(json.dumps(payload))
    else:
        sys.stderr.write(f"check-scaffold-isolation-gate.sh: {code}: {message}\n")
    sys.exit(rc)

# --- role gate (defence in depth; underlying validators also enforce) ---
role_file = target / "_system" / ".aiast-role.json"
role = "unknown"
if role_file.is_file():
    try:
        role = json.loads(role_file.read_text()).get("role", "unknown")
    except Exception as e:
        fail_envelope("role_unreadable", f"{e}")
if role == "parent-template":
    fail_envelope("parent_template_refusal",
                  "scaffold isolation gate is downstream-only; parent template refused")

# --- manifest load ---
manifest_path = Path(manifest_arg) if manifest_arg else (target / "_system" / "scaffold-isolation-gates.json")
if not manifest_path.is_file():
    fail_envelope("manifest_missing", f"{manifest_path} not found")
try:
    manifest = json.loads(manifest_path.read_text())
except Exception as e:
    fail_envelope("manifest_unreadable", f"{e}")

mode = mode_arg or manifest.get("default_mode", "best-effort")
allowed_modes = manifest.get("modes", ["strict", "best-effort", "report-only"])
if mode not in allowed_modes:
    fail_envelope("bad_mode", f"mode {mode!r} not in {allowed_modes}")

# Resolve app_id for the envelope; defensive — if namespace missing the
# first gate (app-local-namespace) will catch it.
ns_file = target / "_system" / "app-local-namespace.json"
app_id = None
if ns_file.is_file():
    try:
        app_id = json.loads(ns_file.read_text()).get("app_id")
    except Exception:
        app_id = None

audit_dir = target / "_system" / "agent-state" / "audit"

def count_audit_lines() -> int:
    if not audit_dir.is_dir(): return 0
    n = 0
    for p in audit_dir.iterdir():
        if p.name.endswith(".jsonl") and p.is_file():
            try:
                n += sum(1 for _ in p.open())
            except Exception:
                pass
    return n

ts_start = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

gates_out: list[dict] = []
first_failure = None
audit_baseline = count_audit_lines()

for gate in manifest.get("gates", []):
    gid = gate["id"]
    command = gate["command"]
    expected_rc = int(gate.get("expected_rc", 0))
    args = list(gate.get("args", []))

    # In report-only mode, strip --emit-bleed-events so no events are written.
    if mode == "report-only":
        args = [a for a in args if a != "--emit-bleed-events"]

    if gid in skips:
        gates_out.append({
            "id": gid, "command": command, "args": args,
            "ok": True, "skipped": True, "reason": "--skip",
            "rc": 0, "duration_seconds": 0.0,
            "bleed_events_emitted": 0, "stderr_tail": "",
        })
        continue

    cmd_path = (target / command).resolve()
    if not cmd_path.is_file():
        result = {
            "id": gid, "command": command, "args": args,
            "ok": False, "skipped": False,
            "rc": 127, "duration_seconds": 0.0,
            "bleed_events_emitted": 0,
            "stderr_tail": f"command not found: {command}",
        }
        gates_out.append(result)
        if first_failure is None: first_failure = gid
        if mode == "strict" and gate.get("blocks_subsequent", False):
            break
        continue

    pre = count_audit_lines()
    t0 = time.time()
    proc = subprocess.run(["bash", str(cmd_path), str(target), *args],
                          capture_output=True, text=True)
    dt = time.time() - t0
    post = count_audit_lines()

    ok = (proc.returncode == expected_rc)
    stderr_tail = (proc.stderr or "").strip().splitlines()[-5:] if proc.stderr else []
    result = {
        "id": gid, "command": command, "args": args,
        "ok": ok, "skipped": False,
        "rc": proc.returncode, "expected_rc": expected_rc,
        "duration_seconds": round(dt, 3),
        "bleed_events_emitted": max(0, post - pre),
        "stderr_tail": "\n".join(stderr_tail),
    }
    gates_out.append(result)
    if not ok:
        if first_failure is None: first_failure = gid
        if mode == "strict":
            break

audit_final = count_audit_lines()
ts_end = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

summary = {
    "total": len(manifest.get("gates", [])),
    "ok":      sum(1 for g in gates_out if g["ok"] and not g.get("skipped")),
    "failed":  sum(1 for g in gates_out if not g["ok"]),
    "skipped": sum(1 for g in gates_out if g.get("skipped")),
    "bleed_events_total": max(0, audit_final - audit_baseline),
    "first_failure": first_failure,
}

overall_ok = (first_failure is None) or (mode != "strict")

payload = {
    "ok": overall_ok,
    "script": "check-scaffold-isolation-gate.sh",
    "ts": ts_start,
    "completed_at": ts_end,
    "mode": mode,
    "target": str(target),
    "role": role,
    "app_id": app_id,
    "manifest": str(manifest_path.relative_to(target)) if manifest_path.is_relative_to(target) else str(manifest_path),
    "gates": gates_out,
    "summary": summary,
}

emit(payload, 0 if overall_ok else 1)
PY
