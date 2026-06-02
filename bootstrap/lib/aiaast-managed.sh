#!/usr/bin/env bash
# aiaast-managed.sh — managed-file listing + copy/sync engine
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

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
    "ANTIGRAVITY.md"
    "CURSOR.md"
    "COPILOT.md"
    "AIDER.md"
    "AGENT_ZERO.md"
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
    ".claude"
    ".codex"
    ".gemini"
    ".windsurf"
    ".cursor"
    ".antigravitycli"
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
          ! -path '_system/agent-state/*' \
          ! -path '_system/self-improvement/proposals/*' \
          ! -path '_system/self-improvement/applied/*' \
          ! -path '_system/self-improvement/rejected/*' \
          ! -path '_system/self-improvement/ledger.jsonl' \
          ! -name 'INTEGRITY_MANIFEST.sha256.sig' \
          ! -name '.DS_Store' \
          ! -name '*.pyc' \
          ! -name '*.pyo' \
          ! -name '*.swp' \
          | sort
      )
    fi
  done | awk '!seen[$0]++'
}
