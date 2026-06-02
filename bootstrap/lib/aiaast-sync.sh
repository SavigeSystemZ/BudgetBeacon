#!/usr/bin/env bash
# aiaast-sync.sh — onboarding + template/meta-sync notices + install metadata
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

aiaast_refresh_onboarding_baseline() {
  local script_dir="$1"
  local repo_root="$2"
  local app_name="${3:-}"
  local force="${4:-0}"

  if [[ -z "${app_name}" ]]; then
    app_name="$(aiaast_resolve_app_name "${repo_root}")"
  fi

  if aiaast_project_profile_needs_configuration "${repo_root}"; then
    bash "${script_dir}/configure-project-profile.sh" "${repo_root}" --app-name "${app_name}"
  fi

  # Runtime foundation templates under bootstrap/templates/runtime/ are
  # product-owned seeds: they are copied into the downstream on first
  # install and then customized by the app. They MUST NEVER be
  # force-overwritten by a refresh path — doing so destroys product work
  # (e.g. real install.sh, runtime-foundation.sh, compose.yml content).
  # The `force` parameter is intentionally ignored for the runtime-foundation
  # generator; generate-runtime-foundations.sh already preserves existing
  # files and only fills in missing ones when no --force flag is passed.
  bash "${script_dir}/generate-runtime-foundations.sh" "${repo_root}" --app-name "${app_name}"

  # Downstream-only additive installs (for example agent-surface migrations) set
  # AIAST_SKIP_ONBOARDING_SEEDS=1 so we never re-run suggest/seed passes that can
  # rewrite repo-owned narrative surfaces (PRODUCT_BRIEF, working files, context).
  if [[ "${AIAST_SKIP_ONBOARDING_SEEDS:-0}" == "1" ]]; then
    printf 'skipped_onboarding_seeds preserve-first (AIAST_SKIP_ONBOARDING_SEEDS=1)\n' >&2
    return 0
  fi

  bash "${script_dir}/suggest-project-profile.sh" "${repo_root}" --write
  bash "${script_dir}/seed-product-brief.sh" "${repo_root}" --app-name "${app_name}"
  bash "${script_dir}/recommend-starter-blueprint.sh" "${repo_root}" --write
  bash "${script_dir}/seed-test-strategy.sh" "${repo_root}"
  bash "${script_dir}/seed-risk-register.sh" "${repo_root}"
  bash "${script_dir}/seed-working-state.sh" "${repo_root}" --app-name "${app_name}"
}

# Write _system/TEMPLATE_SYNC_NOTICE.md plus append-only history after a
# successful bootstrap install/update (non-dry-run). See
# _system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md.
# Args: repo_root, event_label, refresh_managed (0|1)
aiaast_emit_template_sync_notice() {
  local repo_root="$1"
  local event_label="$2"
  local refresh_managed="${3:-0}"
  local ts ver hist_dir hist_file notice_path
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  ver="$(aiaast_template_version "${repo_root}")"
  hist_dir="${repo_root}/_system/history"
  hist_file="${hist_dir}/template-sync-events.jsonl"
  notice_path="${repo_root}/_system/TEMPLATE_SYNC_NOTICE.md"
  mkdir -p "${hist_dir}"
  printf '{"ts":"%s","event":"%s","refresh_managed":%s,"installed_template_version":"%s"}\n' \
    "${ts}" "${event_label}" "${refresh_managed}" "${ver}" >>"${hist_file}"
  python3 - <<'PY' "${notice_path}" "${ts}" "${event_label}" "${refresh_managed}" "${ver}"
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
ts, event, rm, ver = sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
rm_yes = rm == "1"
lines = [
    "# Template operating-layer sync notice",
    "",
    "**Agent gate:** PENDING_HEALTH_CHECK",
    "",
    f"**When (UTC):** {ts}",
    f"**Event:** {event}",
    "**Refresh-managed from source:** " + ("yes" if rm_yes else "no"),
    f"**Installed template version marker (`_system/.template-version`):** {ver}",
    "",
    "## What happened",
    "",
    "Bootstrap synchronized this **downstream application repository** with the",
    "canonical AIAST installable template (`TEMPLATE/`). This directory is **not**",
    "the master template copy; treat your pinned template checkout as the source of",
    "operating-layer churn.",
    "",
    "## Preserve-first reminder",
    "",
    "Stateful / repo-owned surfaces (for example `PRODUCT_BRIEF.md`,",
    "`_system/PROJECT_PROFILE.md`, `_system/context/*.md`, and standard working",
    "files) are protected from template **diff refresh** paths unless you explicitly",
    "chose `--refresh-managed`. If onboarding seeds ran, review narrative files for",
    "unintended edits before committing.",
    "",
    "## Health gate — run before product work",
    "",
    "1. `bash bootstrap/emit-session-environment.sh .`",
    "2. `bash bootstrap/system-doctor.sh . --strict` (or omit `--strict` once, then tighten)",
    "3. `bash bootstrap/validate-system.sh . --strict` when this repo should be contract-clean",
    "4. Review `git status` and resolve anything unexpected",
    "5. When satisfied: `bash bootstrap/clear-template-sync-notice.sh .`",
    "",
    "## Policy",
    "",
    "- `_system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`",
    "- `_system/UPGRADE_AND_DRIFT_POLICY.md`",
    "- `_system/AGENT_INIT_CONVERGENCE.md`",
    "",
    "<!-- machine_json: "
    + json.dumps(
        {
            "agent_gate": "PENDING_HEALTH_CHECK",
            "ts": ts,
            "event": event,
            "refresh_managed": rm_yes,
            "installed_template_version": ver,
        },
        separators=(",", ":"),
    )
    + " -->",
    "",
]
path.parent.mkdir(parents=True, exist_ok=True)
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
}

# Emit a machine-readable meta-sync marker so the next agent that starts
# inside this downstream can detect the sync and run reconcile-meta-sync.sh
# before resuming project work. See _system/META_SYNC_RECONCILE_PROTOCOL.md.
#
# Args:
#   1: repo_root          (target downstream)
#   2: source_root        (TEMPLATE that performed the sync)
#   3: event_label        (e.g. "update-template", "scaffold-system")
#   4: refresh_managed    (0|1)
#   5: missing_csv        (optional comma-separated list)
#   6: drifted_csv        (optional comma-separated list)
#   7: always_refresh_csv (optional comma-separated list)
aiaast_emit_meta_sync_pending() {
  local repo_root="$1"
  local source_root="$2"
  local event_label="$3"
  local refresh_managed="${4:-0}"
  local missing_csv="${5:-}"
  local drifted_csv="${6:-}"
  local always_refresh_csv="${7:-}"

  # Parent-template refusal: do NOT drop a marker inside TEMPLATE/. The
  # marker is meant for *downstream* repos that consume TEMPLATE.
  if [[ -f "${repo_root}/_system/.template-version" ]] \
     && [[ "$(basename "${repo_root}")" == "TEMPLATE" ]] \
     && [[ -d "${repo_root}/../_TEMPLATE_FACTORY" ]]; then
    return 0
  fi

  local marker_dir="${repo_root}/_system/agent-state/meta-sync"
  local marker_path="${marker_dir}/PENDING.json"
  mkdir -p "${marker_dir}"

  local ts source_ver installed_ver host_running actor
  ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  source_ver="$(aiaast_template_version "${source_root}" 2>/dev/null || printf 'unknown')"
  installed_ver="$(aiaast_template_version "${repo_root}" 2>/dev/null || printf 'unknown')"
  host_running="${AIAST_HOST_ADAPTER:-unknown}"
  actor="${USER:-$(id -un 2>/dev/null || printf 'unknown')}"

  # Best-effort host-settings rollup (only if checker is present downstream).
  local hs_summary='null'
  if [[ -x "${repo_root}/bootstrap/check-host-settings-baseline.sh" ]]; then
    local hs_out
    if hs_out="$(bash "${repo_root}/bootstrap/check-host-settings-baseline.sh" "${repo_root}" --json 2>/dev/null)"; then
      hs_summary="$(printf '%s' "${hs_out}" | python3 -c 'import json,sys;print(json.dumps(json.load(sys.stdin).get("summary",None)))' 2>/dev/null || printf 'null')"
    fi
  fi

  python3 - <<'PY' \
    "${marker_path}" "${ts}" "${event_label}" "${refresh_managed}" \
    "${source_ver}" "${installed_ver}" "${host_running}" "${actor}" \
    "${source_root}" "${missing_csv}" "${drifted_csv}" \
    "${always_refresh_csv}" "${hs_summary}"
from pathlib import Path
import json, sys, os

(path, ts, event, rm, src_ver, inst_ver, host, actor, source_root,
 missing_csv, drifted_csv, always_refresh_csv, hs_summary_raw) = sys.argv[1:14]

def _split_csv(s):
    return [x for x in s.split(",") if x] if s else []

try:
    hs_summary = json.loads(hs_summary_raw) if hs_summary_raw and hs_summary_raw != "null" else None
except Exception:
    hs_summary = None

env = {
    "schema_version": "1.0.0",
    "kind": "meta_sync_pending",
    "emitted_at": ts,
    "emitter": {
        "tool": "bootstrap/update-template.sh",
        "event": event,
        "refresh_managed": rm == "1",
        "actor": actor,
        "host_running": host,
        "host_detected_via": "$AIAST_HOST_ADAPTER" if host != "unknown" else "none",
    },
    "template": {
        "version_before": inst_ver,
        "version_after": src_ver,
        "source_root_basename": Path(source_root).name if source_root else None,
    },
    "changeset": {
        "missing_installed":    _split_csv(missing_csv),
        "drifted_refreshed":    _split_csv(drifted_csv),
        "always_refresh_applied": _split_csv(always_refresh_csv),
        "host_settings": hs_summary,
    },
    "next_step": "bash bootstrap/reconcile-meta-sync.sh",
}
Path(path).parent.mkdir(parents=True, exist_ok=True)
Path(path).write_text(json.dumps(env, indent=2) + "\n", encoding="utf-8")
PY
}

aiaast_record_validation_success() {
  local repo_root="$1"
  local validation_command="$2"
  local validation_scope="$3"

  python3 - <<'PY' "${repo_root}" "${validation_command}" "${validation_scope}"
from pathlib import Path
from datetime import datetime, timezone
import re
import sys

repo = Path(sys.argv[1])
command = sys.argv[2]
scope = sys.argv[3]
timestamp = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

status_path = repo / "_system/context/CURRENT_STATUS.md"
where_left_off_path = repo / "WHERE_LEFT_OFF.md"

status_text = status_path.read_text()
status_text = re.sub(
    r"^- Latest known passing validation:.*$",
    f"- Latest known passing validation: {command} -> pass",
    status_text,
    count=1,
    flags=re.MULTILINE,
)
status_text = re.sub(
    r"^- Current confidence level:.*$",
    "- Current confidence level: Partial but structurally validated",
    status_text,
    count=1,
    flags=re.MULTILINE,
)
status_text = re.sub(
    r"^- Last updated:.*$",
    f"- Last updated: {timestamp}",
    status_text,
    count=1,
    flags=re.MULTILINE,
)
status_text = re.sub(
    r"^- Updated by:.*$",
    "- Updated by: bootstrap lifecycle validation",
    status_text,
    count=1,
    flags=re.MULTILINE,
)
status_path.write_text(status_text)

where_text = where_left_off_path.read_text()
where_text = re.sub(r"^- Command:.*$", f"- Command: {command}", where_text, count=1, flags=re.MULTILINE)
where_text = re.sub(r"^- Result:.*$", "- Result: pass", where_text, count=1, flags=re.MULTILINE)
where_text = re.sub(r"^- Scope:.*$", f"- Scope: {scope}", where_text, count=1, flags=re.MULTILINE)
where_left_off_path.write_text(where_text)
PY
}

aiaast_write_install_metadata() {
  local repo_root="$1"
  local source_template="$2"
  local source_version="$3"
  local install_mode="$4"
  local system_readme_path="$5"
  local event="$6"
  local scaffold_profile="${7:-}"
  local app_name
  app_name="$(aiaast_resolve_app_name "${repo_root}")"
  scaffold_profile="$(aiaast_resolve_scaffold_profile "${repo_root}" "${scaffold_profile}")"

  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  python3 - <<'PY' "${metadata_path}" "${source_template}" "${source_version}" "${install_mode}" "${system_readme_path}" "${event}" "${app_name}" "${scaffold_profile}"
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

path = Path(sys.argv[1])
source_template_raw = sys.argv[2]
source_version = sys.argv[3]
install_mode = sys.argv[4]
system_readme_path = sys.argv[5]
event = sys.argv[6]
app_name = sys.argv[7]
scaffold_profile = sys.argv[8]
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

source_template = source_template_raw
if source_template_raw and source_template_raw != "TEMPLATE":
    candidate = Path(source_template_raw)
    if candidate.is_absolute() or "/" in source_template_raw:
        source_template = candidate.name or "TEMPLATE"

data = {}
if path.exists():
    try:
        data = json.loads(path.read_text())
    except Exception:
        data = {}

installed_at = data.get("installed_at")
if not installed_at or installed_at == "UNSET":
    installed_at = now

data.update(
    {
        "template_name": "AIAST",
        "template_version": source_version,
        "source_template": source_template,
        "app_name": app_name,
        "install_mode": install_mode,
        "system_readme_path": system_readme_path,
        "scaffold_profile": scaffold_profile,
        "installed_at": installed_at,
        "updated_at": now,
        "last_event": event,
    }
)

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
}

