#!/usr/bin/env bash
# reconcile-meta-sync.sh
#
# S19e — consume _system/agent-state/meta-sync/PENDING.json, run the
# reconcile pipeline (integrity, host-settings, awareness, instruction-
# layer, host-settings apply, project-context relevance), append a
# handoff note to WHERE_LEFT_OFF.md, archive to history.jsonl, and
# delete PENDING.
#
# If any check fails, PENDING is preserved and a "blocked" entry is
# appended to history.jsonl + WHERE_LEFT_OFF.md.
#
# Exit codes:
#   0 — reconciled ok OR no PENDING to reconcile (no-op)
#   1 — blocked (one or more checks failed; operator must fix and re-run)
#   2 — usage / unrecoverable error
#
# JSON envelope on --json:
#   { "ok": bool, "result": str, "checks": [{name, ok, summary}],
#     "context_relevance": {...}, "marker_archived": bool,
#     "where_left_off_appended": bool, "pending_preserved": bool }
#
# See _system/META_SYNC_RECONCILE_PROTOCOL.md.

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

TARGET=""
EMIT_JSON=0
FORCE=0
shift_count=0
if [[ $# -gt 0 && "${1:-}" != --* ]]; then
  TARGET="$1"; shift_count=1
fi
shift "${shift_count}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)  EMIT_JSON=1; shift ;;
    --force) FORCE=1;     shift ;;
    -h|--help)
      cat <<EOF
Usage: reconcile-meta-sync.sh [TARGET] [--json] [--force]

Consumes _system/agent-state/meta-sync/PENDING.json, runs the reconcile
pipeline, archives the marker, and appends a handoff note to
WHERE_LEFT_OFF.md. See _system/META_SYNC_RECONCILE_PROTOCOL.md.

--force  archive + delete PENDING even if some checks fail (records the
         failures in history.jsonl + WHERE_LEFT_OFF). Use sparingly.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi
TARGET="$(cd -- "${TARGET}" && pwd)"

MARKER="${TARGET}/_system/agent-state/meta-sync/PENDING.json"

# No-op when nothing to reconcile.
if [[ ! -f "${MARKER}" ]]; then
  if [[ ${EMIT_JSON} -eq 1 ]]; then
    printf '{"ok":true,"result":"meta_sync_reconcile_noop","reason":"no_pending"}\n'
  else
    echo "meta_sync_reconcile_noop"
  fi
  exit 0
fi

# Helper: run a checker (bash script) and capture rc + (best-effort) JSON.
run_check() {
  local name="$1" script="$2"; shift 2
  local out_file="${WORK}/${name}.out"
  if [[ ! -x "${script}" && ! -f "${script}" ]]; then
    printf '{"name":"%s","ok":null,"skipped":true,"reason":"missing"}\n' "${name}" >>"${CHECKS}"
    return 0
  fi
  if bash "${script}" "$@" >"${out_file}" 2>&1; then
    printf '{"name":"%s","ok":true,"output":%s}\n' "${name}" \
      "$(python3 -c 'import json,sys;print(json.dumps(open(sys.argv[1]).read()[-200:]))' "${out_file}")" >>"${CHECKS}"
    return 0
  else
    local rc=$?
    printf '{"name":"%s","ok":false,"rc":%d,"output":%s}\n' "${name}" "${rc}" \
      "$(python3 -c 'import json,sys;print(json.dumps(open(sys.argv[1]).read()[-400:]))' "${out_file}")" >>"${CHECKS}"
    return ${rc}
  fi
}

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
CHECKS="${WORK}/checks.jsonl"
: > "${CHECKS}"

failures=0
run_check integrity "${TARGET}/bootstrap/verify-integrity.sh"          --check --target "${TARGET}" || failures=$((failures+1))
run_check host_settings_baseline "${TARGET}/bootstrap/check-host-settings-baseline.sh" "${TARGET}" || failures=$((failures+1))
run_check system_awareness "${TARGET}/bootstrap/check-system-awareness.sh" "${TARGET}" || failures=$((failures+1))
run_check host_adapter_alignment "${TARGET}/bootstrap/check-host-adapter-alignment.sh" "${TARGET}" || failures=$((failures+1))
run_check instruction_layer "${TARGET}/bootstrap/validate-instruction-layer.sh" "${TARGET}" || failures=$((failures+1))
# Apply host-settings: idempotent — refreshes preserve-first siblings with any
# non-conflicting meta-managed keys. Counts as a check (errors fail reconcile).
run_check host_settings_apply "${TARGET}/bootstrap/apply-host-settings.sh" --target "${TARGET}" || failures=$((failures+1))

# Compute project-context relevance: does any changed file overlap with the
# last WHERE_LEFT_OFF.md note?
export RMS_TARGET="${TARGET}"
export RMS_MARKER="${MARKER}"
export RMS_FAILURES="${failures}"
export RMS_FORCE="${FORCE}"
export RMS_EMIT_JSON="${EMIT_JSON}"
export RMS_CHECKS="${CHECKS}"

python3 <<'PY'
import json, os, sys, datetime, hashlib
from pathlib import Path

target  = Path(os.environ["RMS_TARGET"])
marker  = Path(os.environ["RMS_MARKER"])
failures = int(os.environ["RMS_FAILURES"])
force   = os.environ["RMS_FORCE"] == "1"
emit_json = os.environ["RMS_EMIT_JSON"] == "1"

payload = json.loads(marker.read_text(encoding="utf-8"))

cs = payload.get("changeset", {}) or {}
changed = set(
    (cs.get("missing_installed") or [])
    + (cs.get("drifted_refreshed") or [])
    + (cs.get("always_refresh_applied") or [])
)

# Relevance check: does WHERE_LEFT_OFF.md mention any changed path?
wlo = target / "WHERE_LEFT_OFF.md"
relevance = {"checked": False, "hit": False, "overlapping_paths": []}
if wlo.exists() and changed:
    text = wlo.read_text(encoding="utf-8", errors="replace")
    overlaps = [p for p in changed if p and p in text]
    relevance = {
        "checked": True,
        "hit": bool(overlaps),
        "overlapping_paths": overlaps[:20],
    }

ts_reconcile = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
ts_pending   = payload.get("emitted_at", "unknown")

# Compose the WHERE_LEFT_OFF note.
checks_lines = []
with open(os.environ["RMS_CHECKS"]) as f:
    checks = [json.loads(line) for line in f if line.strip()]
checks_summary = ", ".join(
    f"{c['name']}=" + ("ok" if c.get("ok") is True else ("skipped" if c.get("skipped") else "FAIL"))
    for c in checks
)

n_missing  = len(cs.get("missing_installed") or [])
n_drifted  = len(cs.get("drifted_refreshed") or [])
n_refresh  = len(cs.get("always_refresh_applied") or [])
v_before   = (payload.get("template") or {}).get("version_before")
v_after    = (payload.get("template") or {}).get("version_after")
event      = (payload.get("emitter") or {}).get("event", "?")

if failures == 0:
    head = f"## Meta-sync reconciled {ts_reconcile}"
    status_line = "- **Status:** ok — proceed with previously-noted project work."
elif force:
    head = f"## Meta-sync reconciled (forced through failures) {ts_reconcile}"
    status_line = f"- **Status:** ⚠ FORCED through {failures} check failure(s); operator must review checks above."
else:
    head = f"## Meta-sync BLOCKED {ts_reconcile}"
    status_line = f"- **Status:** ⚠ BLOCKED — {failures} check(s) failed; PENDING.json preserved for re-run."

note_lines = [
    "",
    head,
    "",
    f"- **Sync window:** PENDING emitted {ts_pending} by `update-template.sh` (event={event}).",
    f"- **Template version:** {v_before} → {v_after}.",
    f"- **Changeset:** missing_installed={n_missing}, drifted_refreshed={n_drifted}, always_refresh_applied={n_refresh}.",
    f"- **Checks:** {checks_summary}.",
]
if relevance["checked"]:
    if relevance["hit"]:
        ov = ", ".join(f"`{p}`" for p in relevance["overlapping_paths"])
        note_lines.append(f"- **Project-context relevance:** ⚠ overlap with last WHERE_LEFT_OFF note: {ov}. Re-read prior note + targeted re-test before resuming.")
    else:
        note_lines.append("- **Project-context relevance:** none of the refreshed files overlap with the last WHERE_LEFT_OFF note. Safe to resume.")
else:
    note_lines.append("- **Project-context relevance:** n/a (WHERE_LEFT_OFF.md absent or empty changeset).")
note_lines.append(status_line)
note_lines.append("")

wlo_appended = False
if wlo.exists():
    with open(wlo, "a", encoding="utf-8") as f:
        f.write("\n".join(note_lines))
    wlo_appended = True

# Append to history.jsonl and write LATEST_RECONCILE.json.
hist_dir  = target / "_system/agent-state/meta-sync"
hist_dir.mkdir(parents=True, exist_ok=True)
hist_path = hist_dir / "history.jsonl"
latest    = hist_dir / "LATEST_RECONCILE.json"

record = {
    "schema_version": "1.0.0",
    "kind": "meta_sync_reconcile",
    "reconciled_at": ts_reconcile,
    "pending_emitted_at": ts_pending,
    "pending_payload_hash": hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest(),
    "checks": checks,
    "context_relevance": relevance,
    "failures": failures,
    "forced_through_failures": (failures > 0 and force),
    "blocked": (failures > 0 and not force),
    "where_left_off_appended": wlo_appended,
}
with open(hist_path, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, separators=(",", ":")) + "\n")
latest.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")

# Decide whether to delete PENDING.
pending_preserved = (failures > 0 and not force)
if not pending_preserved:
    try:
        marker.unlink()
        marker_archived = True
    except FileNotFoundError:
        marker_archived = False
else:
    marker_archived = False

env = {
    "ok": (failures == 0) or force,
    "result": ("meta_sync_reconcile_ok" if failures == 0
               else ("meta_sync_reconcile_forced" if force
                     else "meta_sync_reconcile_blocked")),
    "reconciled_at": ts_reconcile,
    "checks": [{"name": c["name"], "ok": c.get("ok"), "skipped": c.get("skipped", False)} for c in checks],
    "failures": failures,
    "context_relevance": relevance,
    "marker_archived": marker_archived,
    "pending_preserved": pending_preserved,
    "where_left_off_appended": wlo_appended,
    "history_path": str(hist_path),
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    print(env["result"])
    print(f"  checks: {checks_summary}")
    print(f"  context_relevance_hit: {relevance['hit']}")
    print(f"  where_left_off_appended: {wlo_appended}")
    print(f"  history: {hist_path}")
    print(f"  pending_preserved: {pending_preserved}")

sys.exit(0 if env["ok"] else 1)
PY
