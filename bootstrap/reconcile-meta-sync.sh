#!/usr/bin/env bash
# reconcile-meta-sync.sh
#
# S19e — consume _system/agent-state/meta-sync/PENDING.json, run the
# reconcile pipeline, append a handoff note to WHERE_LEFT_OFF.md
# (with rotation), archive to history.jsonl, and delete PENDING.
#
# S19-polish (this revision) adds:
#   - Item 3: rotate WHERE_LEFT_OFF.md inline reconcile notes (keep N=5);
#             overflow archived to _system/agent-state/meta-sync/WHERE_LEFT_OFF_HISTORY.md.
#   - Item 4: handoff note now records actor + host_running + event
#             from the PENDING.emitter block.
#   - Item 5: if WHERE_LEFT_OFF.md is absent, create it with a header
#             before appending; envelope reports wlo_created=true.
#   - Item 7: on blocked OR forced reconcile, append a schema-conformant
#             event (meta-sync-blocked / meta-sync-forced) to the
#             fleet audit log via bootstrap/emit-bleed-event.sh.
#   - Item 8: wrap the reconcile in the agent-lock subsystem so two
#             concurrent agent sessions never both reconcile the same
#             repo. If the lock is held, exit 0 with
#             meta_sync_reconcile_locked.
#   - Item 11: path-anchored relevance heuristic (backticks, list items,
#              "file:"/"path:"/"at " prefixes, markdown link targets)
#              instead of bare substring match.
#
# Exit codes:
#   0 — reconciled ok, no PENDING (no-op), OR another agent holds the lock
#   1 — blocked (one or more checks failed; operator must fix and re-run)
#   2 — usage / unrecoverable error
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

# ---- Item 8: atomic reconcile lock ----------------------------------------
# Single-instance critical section per downstream. Uses `mkdir` which is
# atomic on POSIX filesystems (unlike agent-lock.sh's check-then-create
# pattern). Lock is a directory; stale locks older than the TTL get
# reclaimed; the lock metadata sits inside as info.json.
LOCK_DIR="${TARGET}/_system/agent-state/locks"
LOCK_PATH="${LOCK_DIR}/meta-sync-reconcile.lockdir"
LOCK_TTL_SECONDS=300
LOCK_HELD=0
mkdir -p "${LOCK_DIR}"

acquire_lock() {
  if mkdir "${LOCK_PATH}" 2>/dev/null; then
    return 0
  fi
  # Existing lock: reclaim if stale.
  local age=0
  if [[ -d "${LOCK_PATH}" ]]; then
    local mtime
    mtime="$(stat -c %Y "${LOCK_PATH}" 2>/dev/null || echo 0)"
    age=$(( $(date +%s) - mtime ))
    if [[ ${age} -gt ${LOCK_TTL_SECONDS} ]]; then
      rm -rf "${LOCK_PATH}" 2>/dev/null || true
      if mkdir "${LOCK_PATH}" 2>/dev/null; then
        return 0
      fi
    fi
  fi
  return 1
}

if acquire_lock; then
  LOCK_HELD=1
  printf '{"pid":%d,"acquired_at":"%s"}\n' "${$}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    > "${LOCK_PATH}/info.json"
  trap 'rm -rf "${LOCK_PATH}" 2>/dev/null || true; rm -rf "${WORK:-/nonexistent}"' EXIT
else
  # Another reconcile is in progress. Bow out cleanly.
  if [[ ${EMIT_JSON} -eq 1 ]]; then
    printf '{"ok":true,"result":"meta_sync_reconcile_locked","reason":"lock_held_by_other_reconcile"}\n'
  else
    echo "meta_sync_reconcile_locked"
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
# (trap is set above when lock acquired; otherwise set a basic cleanup)
if [[ ${LOCK_HELD} -eq 0 ]]; then
  trap 'rm -rf "${WORK}"' EXIT
fi
CHECKS="${WORK}/checks.jsonl"
: > "${CHECKS}"

# Item 5: ensure WHERE_LEFT_OFF.md exists BEFORE the check pipeline runs
# (system_awareness + instruction_layer reference WLO; if missing they flag).
# Creating it here as part of the reconcile bootstrap satisfies both the
# fresh-repo case and the canonical contract that the file always exists.
WLO_BOOTSTRAP_CREATED=0
if [[ ! -f "${TARGET}/WHERE_LEFT_OFF.md" ]]; then
  cat > "${TARGET}/WHERE_LEFT_OFF.md" <<'WLO_HEADER'
# Where Left Off

This file is the per-session resume packet. Meta-sync reconcile notes
(auto-appended by `bootstrap/reconcile-meta-sync.sh`) follow below.
See `_system/META_SYNC_RECONCILE_PROTOCOL.md`.

WLO_HEADER
  WLO_BOOTSTRAP_CREATED=1
fi
export RMS_WLO_BOOTSTRAP_CREATED="${WLO_BOOTSTRAP_CREATED}"

failures=0
run_check integrity "${TARGET}/bootstrap/verify-integrity.sh"          --check --target "${TARGET}" || failures=$((failures+1))
run_check host_settings_baseline "${TARGET}/bootstrap/check-host-settings-baseline.sh" "${TARGET}" || failures=$((failures+1))
run_check system_awareness "${TARGET}/bootstrap/check-system-awareness.sh" "${TARGET}" || failures=$((failures+1))
run_check host_adapter_alignment "${TARGET}/bootstrap/check-host-adapter-alignment.sh" "${TARGET}" || failures=$((failures+1))
run_check instruction_layer "${TARGET}/bootstrap/validate-instruction-layer.sh" "${TARGET}" || failures=$((failures+1))
run_check host_settings_apply "${TARGET}/bootstrap/apply-host-settings.sh" --target "${TARGET}" || failures=$((failures+1))

export RMS_TARGET="${TARGET}"
export RMS_MARKER="${MARKER}"
export RMS_FAILURES="${failures}"
export RMS_FORCE="${FORCE}"
export RMS_EMIT_JSON="${EMIT_JSON}"
export RMS_CHECKS="${CHECKS}"

python3 <<'PY'
import json, os, sys, re, datetime, hashlib
from pathlib import Path

target  = Path(os.environ["RMS_TARGET"])
marker  = Path(os.environ["RMS_MARKER"])
failures = int(os.environ["RMS_FAILURES"])
force   = os.environ["RMS_FORCE"] == "1"
emit_json = os.environ["RMS_EMIT_JSON"] == "1"

payload = json.loads(marker.read_text(encoding="utf-8"))

cs = payload.get("changeset", {}) or {}
changed_paths = list(set(
    (cs.get("missing_installed") or [])
    + (cs.get("drifted_refreshed") or [])
    + (cs.get("always_refresh_applied") or [])
))
emitter = payload.get("emitter", {}) or {}
actor = emitter.get("actor", "unknown")
host_running = emitter.get("host_running", "unknown")
event_label = emitter.get("event", "?")
refresh_managed = bool(emitter.get("refresh_managed", False))

# ---- Item 11: path-anchored relevance heuristic ---------------------------
# A path counts as relevant ONLY when it appears in a path-anchored context:
#   - inside backticks  → `<path>`
#   - markdown link     → [...](<path>) or [<path>](...)
#   - list-item start   → ^(\s*[-*]\s+)<path>
#   - prefixed keyword  → (?i)(file:|path:|at )\s*<path>
# Bare prose mentions of a path no longer flag relevance.
def path_anchored(text: str, p: str) -> bool:
    # S22c fix: the prior implementation built regexes with nested unbounded
    # quantifiers around the escaped path (`[^`]*?ESC[^`]*?` etc). On a
    # changeset with many similar paths (e.g. the S22b lib modules) against
    # a WHERE_LEFT_OFF body this caused catastrophic backtracking (ReDoS) —
    # an effective hang. This rewrite is deterministic and linear: scan only
    # the lines that literally contain `p`, then classify the anchor with
    # bounded, line-scoped string/regex checks (no document-spanning
    # quantifiers). Same semantic contract: a path counts only in a
    # path-anchored context, never as a bare prose mention.
    # PURE STRING OPS — zero regex involving the path, so catastrophic
    # backtracking is impossible by construction. Linear in len(text).
    # For every line containing p, inspect EACH occurrence and classify
    # the enclosing anchor. Same semantic contract as before: a path
    # counts only in a path-anchored context, never as bare prose.
    if not p or p not in text:
        return False
    for line in text.splitlines():
        start = 0
        while True:
            idx = line.find(p, start)
            if idx == -1:
                break
            start = idx + len(p)
            before = line[:idx]
            after = line[start:]
            lstripped = line.lstrip()
            # 1. inside backticks: odd # of backticks before, one after
            if before.count("`") % 2 == 1 and "`" in after:
                return True
            # 2. markdown link target  ...](path...)
            if before.rstrip().endswith("](") or "](" + p in line:
                return True
            # 3. markdown link text    [...path...]  (bracket pair on line)
            if "[" in before and "]" in after:
                return True
            # 4. list-item line        - / * / "N." bullet
            if (lstripped.startswith("- ") or lstripped.startswith("* ")
                    or lstripped[:4].rstrip().rstrip(".").isdigit() and ". " in lstripped[:6]):
                return True
            # 5. keyword-prefixed      file:/path:/at  <path>
            tail = before[-8:].lower()
            if tail.endswith("file:") or tail.endswith("path:") or tail.endswith("at ") \
               or tail.endswith("file: ") or tail.endswith("path: "):
                return True
    return False

wlo = target / "WHERE_LEFT_OFF.md"
relevance = {"checked": False, "hit": False, "overlapping_paths": []}
if wlo.exists() and changed_paths:
    text = wlo.read_text(encoding="utf-8", errors="replace")
    overlaps = sorted({p for p in changed_paths if p and path_anchored(text, p)})
    relevance = {
        "checked": True,
        "hit": bool(overlaps),
        "overlapping_paths": overlaps[:20],
    }

ts_reconcile = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
ts_pending   = payload.get("emitted_at", "unknown")

with open(os.environ["RMS_CHECKS"]) as f:
    checks = [json.loads(line) for line in f if line.strip()]
checks_summary = ", ".join(
    f"{c['name']}=" + ("ok" if c.get("ok") is True else ("skipped" if c.get("skipped") else "FAIL"))
    for c in checks
)
failing_check_names = [c["name"] for c in checks if c.get("ok") is False]

n_missing  = len(cs.get("missing_installed") or [])
n_drifted  = len(cs.get("drifted_refreshed") or [])
n_refresh  = len(cs.get("always_refresh_applied") or [])
v_before   = (payload.get("template") or {}).get("version_before")
v_after    = (payload.get("template") or {}).get("version_after")

if failures == 0:
    head = f"## Meta-sync reconciled {ts_reconcile}"
    status_line = "- **Status:** ok — proceed with previously-noted project work."
elif force:
    head = f"## Meta-sync reconciled (forced through failures) {ts_reconcile}"
    status_line = f"- **Status:** ⚠ FORCED through {failures} check failure(s); operator must review checks above."
else:
    head = f"## Meta-sync BLOCKED {ts_reconcile}"
    status_line = f"- **Status:** ⚠ BLOCKED — {failures} check(s) failed; pending marker preserved for re-run."

# ---- Item 4: attribution lines from PENDING.emitter -----------------------
note_lines = [
    "",
    head,
    "",
    f"- **Sync window:** PENDING emitted {ts_pending} by `update-template.sh` (event={event_label}).",
    f"- **Triggered by:** actor=`{actor}` host=`{host_running}` refresh_managed={str(refresh_managed).lower()}",
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
    note_lines.append("- **Project-context relevance:** n/a (WHERE_LEFT_OFF absent or empty changeset).")
note_lines.append(status_line)
note_lines.append("")
new_note = "\n".join(note_lines)

# ---- Item 5: fresh-repo WHERE_LEFT_OFF fallback (status forwarded from bash) -
# The bash wrapper creates WLO pre-check so system_awareness + instruction_layer
# don't flag the missing file. Here we just record the fact for the envelope.
wlo_created = (os.environ.get("RMS_WLO_BOOTSTRAP_CREATED") == "1")

# ---- Item 3: rotate inline reconcile notes (keep N=5) ---------------------
RECONCILE_HEADER_RE = re.compile(
    r"^(## Meta-sync (?:reconciled(?: \(forced through failures\))?|BLOCKED) )",
    re.MULTILINE,
)
INLINE_LIMIT = 5

def split_into_blocks(text: str):
    """Split text into (preamble, [note_blocks])."""
    matches = list(RECONCILE_HEADER_RE.finditer(text))
    if not matches:
        return text, []
    preamble = text[: matches[0].start()]
    blocks = []
    for i, m in enumerate(matches):
        end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
        blocks.append(text[m.start():end])
    return preamble, blocks

wlo_text = wlo.read_text(encoding="utf-8")
preamble, blocks = split_into_blocks(wlo_text)
notes_overflow = []
# Decide rotation BEFORE appending the new note: if existing >= LIMIT,
# trim oldest so that (existing_kept + new_note = LIMIT).
if len(blocks) >= INLINE_LIMIT:
    overflow_count = len(blocks) - (INLINE_LIMIT - 1)
    notes_overflow = blocks[:overflow_count]
    kept = blocks[overflow_count:]
    new_text = preamble + "".join(kept) + new_note
else:
    new_text = wlo_text + new_note
wlo.write_text(new_text, encoding="utf-8")
wlo_appended = True

# Archive overflow to WHERE_LEFT_OFF_HISTORY.md.
history_md = target / "_system/agent-state/meta-sync/WHERE_LEFT_OFF_HISTORY.md"
wlo_history_appended = False
if notes_overflow:
    history_md.parent.mkdir(parents=True, exist_ok=True)
    if not history_md.exists():
        history_md.write_text(
            "# WHERE_LEFT_OFF reconcile note history\n"
            "\n"
            "Auto-archived oldest meta-sync reconcile notes from `WHERE_LEFT_OFF.md`\n"
            f"(inline cap = {INLINE_LIMIT}). Newest archives appear at bottom.\n"
            "See `_system/META_SYNC_RECONCILE_PROTOCOL.md`.\n"
            "\n",
            encoding="utf-8",
        )
    with open(history_md, "a", encoding="utf-8") as f:
        for block in notes_overflow:
            f.write(block)
    wlo_history_appended = True

# Append to history.jsonl and write LATEST_RECONCILE.json.
hist_dir  = target / "_system/agent-state/meta-sync"
hist_dir.mkdir(parents=True, exist_ok=True)
hist_path = hist_dir / "history.jsonl"
latest    = hist_dir / "LATEST_RECONCILE.json"

record = {
    "schema_version": "1.0.1",
    "kind": "meta_sync_reconcile",
    "reconciled_at": ts_reconcile,
    "pending_emitted_at": ts_pending,
    "pending_payload_hash": hashlib.sha256(json.dumps(payload, sort_keys=True).encode("utf-8")).hexdigest(),
    "actor": actor,
    "host_running": host_running,
    "event": event_label,
    "checks": checks,
    "failing_check_names": failing_check_names,
    "context_relevance": relevance,
    "failures": failures,
    "forced_through_failures": (failures > 0 and force),
    "blocked": (failures > 0 and not force),
    "where_left_off_appended": wlo_appended,
    "where_left_off_created": wlo_created,
    "where_left_off_history_appended": wlo_history_appended,
    "inline_note_limit": INLINE_LIMIT,
    "notes_overflow_archived": len(notes_overflow),
}
with open(hist_path, "a", encoding="utf-8") as f:
    f.write(json.dumps(record, separators=(",", ":")) + "\n")
latest.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")

# ---- Item 7: bleed-event emission on blocked / forced ---------------------
audit_emit_result = None
if failures > 0:
    severity = "high" if not force else "medium"
    btype = "meta-sync-blocked" if not force else "meta-sync-forced"
    emit_script = target / "bootstrap" / "emit-bleed-event.sh"
    if emit_script.exists():
        # Stash context as JSON for emit-bleed-event --context-json.
        ctx = {
            "pending_emitted_at": ts_pending,
            "reconciled_at": ts_reconcile,
            "failures": failures,
            "failing_checks": failing_check_names,
            "actor": actor,
            "host_running": host_running,
            "event": event_label,
        }
        import subprocess
        cmd = [
            "bash", str(emit_script), str(target),
            "--severity", severity,
            "--type", btype,
            "--detected-by", "bootstrap/reconcile-meta-sync.sh",
            "--scope-path", "_system/agent-state/meta-sync/PENDING.json",
            "--scope-op", "detect",
            "--remediation-action", ("refused" if not force else "notify"),
            "--context-json", json.dumps(ctx, separators=(",",":")),
        ]
        try:
            cp = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
            audit_emit_result = {"ok": cp.returncode == 0, "rc": cp.returncode}
        except Exception as e:
            audit_emit_result = {"ok": False, "error": str(e)}

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
    "actor": actor,
    "host_running": host_running,
    "checks": [{"name": c["name"], "ok": c.get("ok"), "skipped": c.get("skipped", False)} for c in checks],
    "failures": failures,
    "failing_check_names": failing_check_names,
    "context_relevance": relevance,
    "marker_archived": marker_archived,
    "pending_preserved": pending_preserved,
    "where_left_off_appended": wlo_appended,
    "where_left_off_created": wlo_created,
    "where_left_off_history_appended": wlo_history_appended,
    "notes_overflow_archived": len(notes_overflow),
    "audit_event_emitted": audit_emit_result,
    "history_path": str(hist_path),
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    print(env["result"])
    print(f"  actor={actor} host={host_running}")
    print(f"  checks: {checks_summary}")
    print(f"  context_relevance_hit: {relevance['hit']}")
    print(f"  where_left_off_appended: {wlo_appended} (created={wlo_created}, overflow_archived={len(notes_overflow)})")
    print(f"  history: {hist_path}")
    print(f"  pending_preserved: {pending_preserved}")
    if audit_emit_result is not None:
        print(f"  audit_event_emitted: {audit_emit_result.get('ok')}")

sys.exit(0 if env["ok"] else 1)
PY
