#!/usr/bin/env bash

# Shared helpers for AIAST bootstrap and maintenance scripts.

# --- Visual progress helpers ---
# Suppress ANSI codes when stdout is not a terminal (piped mode).

_aiaast_ansi_ok=0
[[ -t 1 ]] && _aiaast_ansi_ok=1

_aiaast_bold() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[1m' || true; }
_aiaast_green() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[32m' || true; }
_aiaast_yellow() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[33m' || true; }
_aiaast_cyan() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[36m' || true; }
_aiaast_red() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[31m' || true; }
_aiaast_reset() { [[ ${_aiaast_ansi_ok} -eq 1 ]] && printf '\033[0m' || true; }

aiaast_assert_non_root_for_repo_writes() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    cat >&2 <<'EOF'
Refusing to write repo-managed files as root.
Run this command as the intended repo owner instead, then repair any existing ownership drift before continuing.
EOF
    return 1
  fi
}

aiaast_section_header() {
  local title="$1"
  _aiaast_bold; _aiaast_cyan
  printf '=== %s ===\n' "${title}"
  _aiaast_reset
}

aiaast_progress_start() {
  local label="$1"
  _aiaast_yellow
  printf '  → %s...' "${label}"
  _aiaast_reset
}

aiaast_progress_step() {
  local label="$1"
  _aiaast_green
  printf '\r  ✓ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_done() {
  local label="${1:-done}"
  _aiaast_green
  printf '\r  ✓ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_warn() {
  local label="$1"
  _aiaast_yellow
  printf '  ⚠ %s\n' "${label}"
  _aiaast_reset
}

aiaast_progress_fail() {
  local label="$1"
  _aiaast_red
  printf '  ✗ %s\n' "${label}"
  _aiaast_reset
}

# --- Path classification helpers ---

aiaast_is_stateful_path() {
  case "$1" in
    "TODO.md"|\
    "FIXME.md"|\
    "WHERE_LEFT_OFF.md"|\
    "PLAN.md"|\
    "PRODUCT_BRIEF.md"|\
    "ROADMAP.md"|\
    "DESIGN_NOTES.md"|\
    "ARCHITECTURE_NOTES.md"|\
    "RESEARCH_NOTES.md"|\
    "TEST_STRATEGY.md"|\
    "RISK_REGISTER.md"|\
    "RELEASE_NOTES.md"|\
    "CHANGELOG.md"|\
    "_system/PROJECT_PROFILE.md"|\
    "_system/PROJECT_DOMAIN_MANIFEST.json"|\
    "_system/context/CURRENT_STATUS.md"|\
    "_system/context/DECISIONS.md"|\
    "_system/context/MEMORY.md"|\
    "_system/context/ARCHITECTURAL_INVARIANTS.md"|\
    "_system/context/ASSUMPTIONS.md"|\
    "_system/context/INTEGRATION_SURFACES.md"|\
    "_system/context/OPEN_QUESTIONS.md"|\
    "_system/context/QUALITY_DEBT.md"|\
    "_system/history/template-sync-events.jsonl")
      return 0
      ;;
  esac

  return 1
}

aiaast_is_local_config_path() {
  case "$1" in
    ".cursor/mcp.json"|\
    "_system/.template-install.json"|\
    "_system/SYSTEM_REGISTRY.json"|\
    "_system/TEMPLATE_SYNC_NOTICE.md"|\
    "AIAST_REMOVED.md")
      return 0
      ;;
  esac

  return 1
}

aiaast_is_manifest_excluded_path() {
  local rel="$1"

  if aiaast_is_stateful_path "${rel}" || aiaast_is_local_config_path "${rel}"; then
    return 0
  fi

  case "${rel}" in
    "README.md"|\
    "_system/INTEGRITY_MANIFEST.sha256"|\
    "claude_diff.patch"|\
    *.swp)
      return 0
      ;;
  esac

  return 1
}

aiaast_is_template_diff_skip_path() {
  local rel="$1"

  if aiaast_is_stateful_path "${rel}" || aiaast_is_local_config_path "${rel}"; then
    return 0
  fi

  case "${rel}" in
    "README.md")
      return 0
      ;;
  esac

  return 1
}

aiaast_template_version() {
  local root="$1"
  local version_file="${root}/_system/.template-version"

  if [[ -f "${version_file}" ]]; then
    tr -d '\n' < "${version_file}"
    return 0
  fi

  echo "unknown"
}

aiaast_install_metadata_path() {
  local repo_root="$1"
  printf '%s\n' "${repo_root}/_system/.template-install.json"
}

aiaast_install_metadata_value() {
  local repo_root="$1"
  local key="$2"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  if [[ ! -f "${metadata_path}" ]]; then
    return 0
  fi

  python3 - <<'PY' "${metadata_path}" "${key}"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
try:
    data = json.loads(path.read_text())
except Exception:
    raise SystemExit(0)

value = data.get(key)
if value is not None:
    print(value)
PY
}

aiaast_detect_repo_mode() {
  local repo_root="$1"
  local install_mode
  local last_event

  install_mode="$(aiaast_install_metadata_value "${repo_root}" "install_mode")"
  last_event="$(aiaast_install_metadata_value "${repo_root}" "last_event")"

  if [[ "${install_mode}" == "template-placeholder" || "${last_event}" == "template-source" ]]; then
    printf '%s\n' "template"
  else
    printf '%s\n' "installed"
  fi
}

aiaast_resolve_repo_mode() {
  local repo_root="$1"
  local requested_mode="${2:-auto}"

  case "${requested_mode}" in
    auto)
      aiaast_detect_repo_mode "${repo_root}"
      ;;
    template|installed)
      printf '%s\n' "${requested_mode}"
      ;;
    *)
      echo "Unsupported repo mode: ${requested_mode}" >&2
      return 1
      ;;
  esac
}

aiaast_detect_system_readme_path() {
  local repo_root="$1"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  if [[ -f "${metadata_path}" ]]; then
    python3 - <<'PY' "${metadata_path}"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
    value = data.get("system_readme_path")
    if value:
        print(value)
except Exception:
    pass
PY
    return 0
  fi

  if [[ -f "${repo_root}/AI_SYSTEM_README.md" ]]; then
    echo "AI_SYSTEM_README.md"
  else
    echo "README.md"
  fi
}

aiaast_project_profile_needs_configuration() {
  local repo_root="$1"
  local profile_path="${repo_root}/_system/PROJECT_PROFILE.md"

  if [[ ! -f "${profile_path}" ]]; then
    return 1
  fi

  if grep -Eq '^- App name:[[:space:]]*$' "${profile_path}"; then
    return 0
  fi

  return 1
}

aiaast_resolve_app_name() {
  local repo_root="$1"
  local profile_path="${repo_root}/_system/PROJECT_PROFILE.md"
  local product_brief_path="${repo_root}/PRODUCT_BRIEF.md"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  local app_name
  app_name="$(
      python3 - <<'PY' "${profile_path}" "${product_brief_path}" "${metadata_path}"
from pathlib import Path
import json
import re
import sys

profile_path = Path(sys.argv[1])
brief_path = Path(sys.argv[2])
metadata_path = Path(sys.argv[3])

if profile_path.exists():
    text = profile_path.read_text()
    match = re.search(r"^- App name:[ \t]*(.+?)\s*$", text, re.MULTILINE)
    if match:
        value = match.group(1).strip()
        if value:
            print(value, end="")
            raise SystemExit(0)

if brief_path.exists():
    text = brief_path.read_text()
    match = re.search(r"^- Product name:[ \t]*(.+?)\s*$", text, re.MULTILINE)
    if match:
        value = match.group(1).strip()
        if value:
            print(value, end="")
            raise SystemExit(0)

if metadata_path.exists():
    try:
        data = json.loads(metadata_path.read_text())
    except Exception:
        data = {}
    value = str(data.get("app_name", "")).strip()
    if value:
        print(value, end="")
PY
  )"
  if [[ -n "${app_name}" ]]; then
    printf '%s\n' "${app_name}"
    return 0
  fi

  basename -- "${repo_root}"
}

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
  local app_name
  app_name="$(aiaast_resolve_app_name "${repo_root}")"

  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  python3 - <<'PY' "${metadata_path}" "${source_template}" "${source_version}" "${install_mode}" "${system_readme_path}" "${event}" "${app_name}"
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
        "installed_at": installed_at,
        "updated_at": now,
        "last_event": event,
    }
)

path.parent.mkdir(parents=True, exist_ok=True)
path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
PY
}

aiaast_list_files() {
  local root="$1"
  (cd "${root}" && find . -type f ! -path '*/.git/*' | sort)
}

aiaast_assert_template_root() {
  local root="$1"
  local marker="${root}/.installable-product-root"

  if [[ ! -f "${marker}" ]]; then
    echo "Source is not an AIAST installable product root: ${root}" >&2
    echo "Expected marker: ${marker}" >&2
    return 1
  fi

  if ! grep -Fxq 'product=AIAST' "${marker}"; then
    echo "Source marker does not identify an AIAST product root: ${marker}" >&2
    return 1
  fi

  local rel
  for rel in "AGENTS.md" "_system/.template-version" "bootstrap/init-project.sh"; do
    if [[ ! -e "${root}/${rel}" ]]; then
      echo "Source is missing required AIAST template file: ${rel}" >&2
      return 1
    fi
  done

  if [[ "$(aiaast_detect_repo_mode "${root}")" != "template" ]]; then
    echo "Refusing source that is not in template-source mode: ${root}" >&2
    echo "Only the canonical AIAST template root should be used as a lifecycle source." >&2
    return 1
  fi

  for rel in "_META_AGENT_SYSTEM" "_TEMPLATE_FACTORY" "MOS_TEMPLATE" "_MOS_TEMPLATE_FACTORY" "MOS_SOURCE_LIBRARY"; do
    if [[ -e "${root}/${rel}" ]]; then
      echo "Refusing source that contains maintainer-only or foreign product layers: ${root}/${rel}" >&2
      echo "Point AIAST install/update flows at the canonical template root in template-source mode, usually .../TEMPLATE" >&2
      return 1
    fi
  done
}

aiaast_list_manifest_files() {
  local root="$1"

  aiaast_print_managed_files "${root}" | while IFS= read -r rel; do
    rel="${rel#./}"
    if aiaast_is_manifest_excluded_path "${rel}"; then
      continue
    fi
    printf './%s\n' "${rel}"
  done
}

aiaast_copy_rel_file() {
  local source_root="$1"
  local source_rel="$2"
  local target_root="$3"
  local target_rel="$4"

  mkdir -p "$(dirname "${target_root}/${target_rel}")"
  cp -p "${source_root}/${source_rel}" "${target_root}/${target_rel}"
}

aiaast_sync_rel_file_mode() {
  local source_root="$1"
  local source_rel="$2"
  local target_root="$3"
  local target_rel="$4"
  local source_mode
  local target_mode

  [[ -e "${source_root}/${source_rel}" && -e "${target_root}/${target_rel}" ]] || return 0

  source_mode="$(stat -c '%a' "${source_root}/${source_rel}")"
  target_mode="$(stat -c '%a' "${target_root}/${target_rel}")"
  [[ "${source_mode}" == "${target_mode}" ]] && return 0

  chmod "${source_mode}" "${target_root}/${target_rel}"
}

aiaast_print_managed_files() {
  local repo_root="$1"
  local readme_path
  readme_path="$(aiaast_detect_system_readme_path "${repo_root}")"

  local root_files=(
    "AGENTS.md"
    "CLAUDE.md"
    "GEMINI.md"
    "CODEX.md"
    "WINDSURF.md"
    "DEEPSEEK.md"
    "PEARAI.md"
    "LOCAL_MODELS.md"
    ".cursorrules"
    ".windsurfrules"
    ".aider.conf.yml"
    ".continuerules"
    ".clinerules"
    "AIAST_VERSION.md"
    "AIAST_CHANGELOG.md"
    "TODO.md"
    "FIXME.md"
    "WHERE_LEFT_OFF.md"
    "CHANGELOG.md"
    "PLAN.md"
    "PRODUCT_BRIEF.md"
    "ROADMAP.md"
    "DESIGN_NOTES.md"
    "ARCHITECTURE_NOTES.md"
    "RESEARCH_NOTES.md"
    "TEST_STRATEGY.md"
    "RISK_REGISTER.md"
    "RELEASE_NOTES.md"
    ".credits-hidden"
    "LICENSE"
    "NOTICE"
    "${readme_path}"
  )
  local rel
  for rel in "${root_files[@]}"; do
    [[ -f "${repo_root}/${rel}" ]] && printf '%s\n' "${rel}"
  done

  local managed_dirs=(
    "bootstrap"
    "_system"
    ".cursor"
    ".github"
    "registry"
    "ops"
    "tools"
    "mobile"
    "ai"
    "packaging"
    "distribution"
    "docs"
    "notes"
  )
  local dir
  for dir in "${managed_dirs[@]}"; do
    if [[ -d "${repo_root}/${dir}" ]]; then
      (
        cd "${repo_root}"
        find "${dir}" -type f \
          ! -path '*/.git/*' \
          ! -path '*/__pycache__/*' \
          ! -path '_system/history/*' \
          ! -path '_system/automation/*.log' \
          ! -path '_system/automation/*.json' \
          ! -path '_system/automation/latest.log' \
          ! -name '.DS_Store' \
          ! -name '*.pyc' \
          ! -name '*.pyo' \
          ! -name '*.swp' \
          | sort
      )
    fi
  done | awk '!seen[$0]++'
}

aiaast_path_category() {
  local rel="$1"

  case "${rel}" in
    "AGENTS.md"|"CLAUDE.md"|"GEMINI.md"|"CODEX.md"|"WINDSURF.md"|"DEEPSEEK.md"|"PEARAI.md"|"LOCAL_MODELS.md"|".cursorrules"|".windsurfrules"|".aider.conf.yml"|".continuerules"|".clinerules"|".github/copilot-instructions.md")
      printf '%s\n' "entrypoint"
      ;;
    "README.md"|"AI_SYSTEM_README.md"|"AIAST_VERSION.md"|"AIAST_CHANGELOG.md")
      printf '%s\n' "system-metadata"
      ;;
    "TODO.md"|"FIXME.md"|"WHERE_LEFT_OFF.md"|"CHANGELOG.md"|"PLAN.md"|"PRODUCT_BRIEF.md"|"ROADMAP.md"|"DESIGN_NOTES.md"|"ARCHITECTURE_NOTES.md"|"RESEARCH_NOTES.md"|"TEST_STRATEGY.md"|"RISK_REGISTER.md"|"RELEASE_NOTES.md")
      printf '%s\n' "working-state"
      ;;
    bootstrap/*)
      printf '%s\n' "bootstrap"
      ;;
    registry/*)
      printf '%s\n' "registry"
      ;;
    ops/*)
      printf '%s\n' "ops"
      ;;
    tools/*)
      printf '%s\n' "tools"
      ;;
    mobile/*)
      printf '%s\n' "mobile"
      ;;
    ai/*)
      printf '%s\n' "ai"
      ;;
    packaging/*)
      printf '%s\n' "packaging"
      ;;
    _system/context/*)
      printf '%s\n' "system-context"
      ;;
    _system/review-playbooks/*)
      printf '%s\n' "review-playbook"
      ;;
    _system/prompt-packs/*|_system/prompt-templates/*)
      printf '%s\n' "prompting"
      ;;
    _system/starter-blueprints/*)
      printf '%s\n' "starter-blueprint"
      ;;
    _system/mcp/*)
      printf '%s\n' "mcp"
      ;;
    _system/ci/*)
      printf '%s\n' "ci"
      ;;
    _system/packaging/*)
      printf '%s\n' "packaging"
      ;;
    _system/plugins/*)
      printf '%s\n' "plugin"
      ;;
    _system/systemd/*)
      printf '%s\n' "systemd"
      ;;
    _system/*)
      printf '%s\n' "system-core"
      ;;
    .cursor/agents/*)
      printf '%s\n' "cursor-agent"
      ;;
    .cursor/commands/*)
      printf '%s\n' "cursor-command"
      ;;
    .cursor/rules/*)
      printf '%s\n' "cursor-rule"
      ;;
    .cursor/skills/*)
      printf '%s\n' "cursor-skill"
      ;;
    .cursor/*)
      printf '%s\n' "cursor-overlay"
      ;;
    .github/*)
      printf '%s\n' "copilot-overlay"
      ;;
    *)
      printf '%s\n' "unclassified"
      ;;
  esac
}
