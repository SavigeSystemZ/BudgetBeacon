#!/usr/bin/env bash
# aiaast-classify.sh — path classification + path_category
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

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
    "_system/INTEGRITY_MANIFEST.sha256.sig"|\
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
aiaast_path_category() {
  local rel="$1"

  case "${rel}" in
    "AGENTS.md"|"CLAUDE.md"|"GEMINI.md"|"CODEX.md"|"WINDSURF.md"|"DEEPSEEK.md"|"PEARAI.md"|"LOCAL_MODELS.md"|"CURSOR.md"|"COPILOT.md"|"AIDER.md"|"AGENT_ZERO.md"|".cursorrules"|".windsurfrules"|".aider.conf.yml"|".continuerules"|".clinerules"|".github/copilot-instructions.md")
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
    .claude/settings.aiaast.json|.codex/config.aiaast.toml|.gemini/settings.aiaast.json|.windsurf/settings.aiaast.json|.cursor/settings.aiaast.json|.github/copilot-config.aiaast.json)
      printf '%s\n' "host-settings-meta"
      ;;
    .claude/settings.json|.codex/config.toml|.gemini/settings.json|.windsurf/settings.json|.cursor/settings.json|.github/copilot-config.json)
      printf '%s\n' "host-settings-app"
      ;;
    .claude/*|.codex/*|.gemini/*|.windsurf/*)
      printf '%s\n' "host-overlay"
      ;;
    .github/*)
      printf '%s\n' "copilot-overlay"
      ;;
    *)
      printf '%s\n' "unclassified"
      ;;
  esac
}
