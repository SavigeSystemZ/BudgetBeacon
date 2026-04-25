#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: generate-operating-profile.sh [target-repo] [--format markdown|json|both] [--write] [--check]

Generate the repo operating profile that upstream hosts should ingest before emitting instructions.
EOF
}

TARGET_REPO=""
FORMAT="markdown"
WRITE=0
CHECK=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --format)
      FORMAT="${2:-}"
      shift 2
      ;;
    --write)
      WRITE=1
      shift
      ;;
    --check)
      CHECK=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ ${WRITE} -eq 1 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

if [[ ${WRITE} -eq 1 && ${CHECK} -eq 1 ]]; then
  echo "Use either --write or --check, not both." >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}" "${FORMAT}" "${WRITE}" "${CHECK}"
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
fmt = sys.argv[2]
write = sys.argv[3] == "1"
check = sys.argv[4] == "1"

md_path = repo / "_system" / "REPO_OPERATING_PROFILE.md"
json_path = repo / "_system" / "repo-operating-profile.json"

if fmt not in {"markdown", "json", "both"}:
    print(f"Unsupported format: {fmt}", file=sys.stderr)
    raise SystemExit(1)


def read_text(path: Path) -> str:
    return path.read_text() if path.exists() else ""


def field(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def split_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


version = (repo / "_system" / ".template-version").read_text().strip() if (repo / "_system" / ".template-version").exists() else "unknown"
profile_text = read_text(repo / "_system" / "PROJECT_PROFILE.md")
app_name = field(profile_text, "App name")
profile_state = "configured-project" if app_name else "template-seeded"
system_readme_path = "AI_SYSTEM_README.md" if (repo / "AI_SYSTEM_README.md").exists() else "README.md"

precedence_manifest = {}
precedence_path = repo / "_system" / "instruction-precedence.json"
if precedence_path.exists():
    precedence_manifest = json.loads(precedence_path.read_text())

capabilities = {}
capabilities_path = repo / "_system" / "aiaast-capabilities.json"
if capabilities_path.exists():
    capabilities = json.loads(capabilities_path.read_text())

canonical_files = precedence_manifest.get("canonical_repo_local_files") or [
    "AGENTS.md",
    "_system/PROJECT_PROFILE.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/LOAD_ORDER.md",
    "_system/MASTER_SYSTEM_PROMPT.md",
    "_system/PROJECT_RULES.md",
    "_system/AGENT_DISCOVERY_MATRIX.md",
]

load_order_anchor = [
    "AGENTS.md",
    "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
    "_system/REPO_OPERATING_PROFILE.md",
    "_system/PROJECT_PROFILE.md",
    "_system/CONTEXT_INDEX.md",
    "_system/LOAD_ORDER.md",
]

tool_adapters = {
    "codex": "CODEX.md",
    "claude": "CLAUDE.md",
    "gemini": "GEMINI.md",
    "windsurf": "WINDSURF.md",
    "cursor": ".cursorrules",
    "copilot": ".github/copilot-instructions.md",
}
tool_adapters_present = {name: path for name, path in tool_adapters.items() if (repo / path).exists()}

validation_commands = [
    "bootstrap/validate-system.sh <repo>",
    "bootstrap/check-install-boundary.sh <repo>",
    "bootstrap/validate-instruction-layer.sh <repo>",
    "bootstrap/check-host-adapter-alignment.sh <repo>",
    "bootstrap/check-host-ingestion.sh <repo>",
    "bootstrap/check-host-bundle.sh <repo>",
    "bootstrap/check-system-awareness.sh <repo>",
    "bootstrap/check-working-directory-alignment.sh <repo>",
    "bootstrap/check-project-target-consistency.sh <repo>",
    "bootstrap/check-global-shim-alignment.sh <repo>",
    "bootstrap/emit-session-environment.sh <repo>",
    "bootstrap/detect-instruction-conflicts.sh <repo> --strict",
    "bootstrap/system-doctor.sh <repo>",
    "bootstrap/check-packaging-targets.sh <repo>",
]
validation_commands = [cmd for cmd in validation_commands if (repo / cmd.split(" ")[0]).exists()]

packaging_manifests = split_csv(field(profile_text, "Packaging manifest paths")) or [
    "packaging/appimage.yml",
    "packaging/flatpak-manifest.json",
    "packaging/snapcraft.yaml",
]
installer_commands = split_csv(field(profile_text, "Installer commands")) or [
    "ops/install/install.sh",
    "ops/install/repair.sh",
    "ops/install/uninstall.sh",
    "ops/install/purge.sh",
]
android_module = field(profile_text, "Android module path") or "mobile/flutter/"
llm_config = field(profile_text, "LLM config path") or "ai/llm_config.yaml"
runtime_roots_present = [name for name in ("packaging", "ops", "mobile", "ai") if (repo / name).exists()]

terminology = precedence_manifest.get("canonical_terms") or {
    "repo_local_truth": "Facts stored in repo-local runtime/config/docs and the authoritative AIAST core docs.",
    "host_level_orchestration_context": "Task framing or operator intent emitted outside the repo.",
    "tool_overlay": "A tool-specific adapter or rules layer that sits on top of the repo-local core.",
    "runtime_system_boundary": "Runtime code must remain independent from _system/.",
}

payload = {
    "schema_version": "1.0.0",
    "template_name": "AIAST",
    "template_version": version,
    "profile_state": profile_state,
    "system_readme_path": system_readme_path,
    "canonical_instruction_files": canonical_files,
    "load_order_anchor": load_order_anchor,
    "read_bundles_contract_path": "_system/READ_BUNDLES.md" if (repo / "_system" / "READ_BUNDLES.md").exists() else "",
    "preferred_bundle_ids": [
        "template-evolution",
        "repo-onboarding",
        "runtime-foundations",
        "packaging-distribution",
        "adapter-host-emission",
        "release-readiness",
        "repo-pivot",
    ] if (repo / "_system" / "READ_BUNDLES.md").exists() else [],
    "terminology_mappings": terminology,
    "validation_commands": validation_commands,
    "packaging_install_expectations": {
        "runtime_foundation_generator": "bootstrap/generate-runtime-foundations.sh" if (repo / "bootstrap" / "generate-runtime-foundations.sh").exists() else "",
        "runtime_roots_present": runtime_roots_present,
        "expected_packaging_manifests": packaging_manifests,
        "expected_installer_commands": installer_commands,
        "expected_mobile_scaffold": android_module.rstrip("/"),
        "expected_ai_config": llm_config,
        "default_bind_model": "loopback-only by default",
        "default_port_range": "8000-9000",
    },
    "boundaries": {
        "runtime_system_boundary": "Runtime code must remain independent from _system/.",
        "agent_system_root": "_system/",
        "host_overwrite_policy": "Host-level orchestration context must not silently overwrite repo-local truth.",
    },
    "tool_adapters_present": tool_adapters_present,
    "precedence_contract": {
        "contract_path": "_system/INSTRUCTION_PRECEDENCE_CONTRACT.md",
        "manifest_path": "_system/instruction-precedence.json",
    },
    "prompt_emission_contract": "_system/PROMPT_EMISSION_CONTRACT.md",
    "change_impact_policy_path": "_system/TEMPLATE_CHANGE_IMPACT_POLICY.md" if (repo / "_system" / "TEMPLATE_CHANGE_IMPACT_POLICY.md").exists() else "",
    "self_healing_boundary_path": "_system/SELF_HEALING_BOUNDARY.md" if (repo / "_system" / "SELF_HEALING_BOUNDARY.md").exists() else "",
    "version_sensitive_research_protocol_path": "_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md" if (repo / "_system" / "VERSION_SENSITIVE_RESEARCH_PROTOCOL.md").exists() else "",
    "workspace_authority_protocol_path": "_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md" if (repo / "_system" / "WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md").exists() else "",
    "project_identity_scope_protocol_path": "_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md" if (repo / "_system" / "PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md").exists() else "",
    "global_redirect_shim_policy_path": "_system/GLOBAL_REDIRECT_SHIM_POLICY.md" if (repo / "_system" / "GLOBAL_REDIRECT_SHIM_POLICY.md").exists() else "",
    "scavenge_discovery_authorization_path": "_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md" if (repo / "_system" / "SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md").exists() else "",
    "session_environment_report_contract_path": "_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md" if (repo / "_system" / "SESSION_ENVIRONMENT_REPORT_CONTRACT.md").exists() else "",
    "orphan_meta_snapshot_policy_path": "_system/ORPHAN_META_SNAPSHOT_POLICY.md" if (repo / "_system" / "ORPHAN_META_SNAPSHOT_POLICY.md").exists() else "",
    "host_ingestion": {
        "host_adapter_generator": "bootstrap/generate-host-adapters.sh" if (repo / "bootstrap" / "generate-host-adapters.sh").exists() else "",
        "host_adapter_validator": "bootstrap/check-host-adapter-alignment.sh" if (repo / "bootstrap" / "check-host-adapter-alignment.sh").exists() else "",
        "host_adapter_manifest": "_system/host-adapter-manifest.json" if (repo / "_system" / "host-adapter-manifest.json").exists() else "",
        "prompt_emitter": "bootstrap/emit-host-prompt.sh" if (repo / "bootstrap" / "emit-host-prompt.sh").exists() else "",
        "prompt_validator": "bootstrap/check-host-ingestion.sh" if (repo / "bootstrap" / "check-host-ingestion.sh").exists() else "",
        "host_bundle_contract": "_system/HOST_BUNDLE_CONTRACT.md" if (repo / "_system" / "HOST_BUNDLE_CONTRACT.md").exists() else "",
        "host_bundle_emitter": "bootstrap/emit-host-bundle.sh" if (repo / "bootstrap" / "emit-host-bundle.sh").exists() else "",
        "host_bundle_validator": "bootstrap/check-host-bundle.sh" if (repo / "bootstrap" / "check-host-bundle.sh").exists() else "",
    },
    "golden_examples": {
        "policy_path": "_system/GOLDEN_EXAMPLES_POLICY.md" if (repo / "_system" / "GOLDEN_EXAMPLES_POLICY.md").exists() else "",
        "pattern_index_path": "_system/golden-examples/PATTERN_INDEX.md" if (repo / "_system" / "golden-examples" / "PATTERN_INDEX.md").exists() else "",
        "manifest_path": "_system/golden-examples/golden-example-manifest.json" if (repo / "_system" / "golden-examples" / "golden-example-manifest.json").exists() else "",
    },
    "version_markers": {
        "human_version": "AIAST_VERSION.md",
        "installed_version": "_system/.template-version",
        "capabilities_manifest": "_system/aiaast-capabilities.json" if capabilities else "",
    },
}

json_output = json.dumps(payload, indent=2, sort_keys=True) + "\n"

md_lines = [
    "# Repo Operating Profile",
    "",
    "## Summary",
    f"- Template: `AIAST` `{version}`",
    f"- Profile state: `{profile_state}`",
    f"- System README path: `{system_readme_path}`",
    "- Ingestion start: `AGENTS.md` -> `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` -> `_system/REPO_OPERATING_PROFILE.md` -> `_system/LOAD_ORDER.md`",
    "",
    "## Canonical instruction files",
]
md_lines.extend(f"- `{item}`" for item in canonical_files)
md_lines.extend([
    "",
    "## Load order anchor",
])
md_lines.extend(f"{idx}. `{item}`" for idx, item in enumerate(load_order_anchor, start=1))
md_lines.extend([
    "",
    "## Bundle model",
    f"- Read bundles contract: `{payload['read_bundles_contract_path']}`",
    f"- Preferred bundle ids: `{', '.join(payload['preferred_bundle_ids']) if payload['preferred_bundle_ids'] else 'none'}`",
    "",
    "## Terminology mappings",
])
md_lines.extend(f"- `{key.replace('_', '-')}`: {value}" for key, value in terminology.items())
md_lines.extend([
    "",
    "## Validation entrypoints",
])
md_lines.extend(f"- `{item}`" for item in validation_commands)
md_lines.extend([
    "",
    "## Packaging / install expectations",
    f"- Runtime foundation generator: `{payload['packaging_install_expectations']['runtime_foundation_generator']}`",
    f"- Current runtime roots present: `{', '.join(runtime_roots_present) if runtime_roots_present else 'none'}`",
    f"- Expected installer commands: `{', '.join(installer_commands)}`",
    f"- Expected packaging manifests: `{', '.join(packaging_manifests)}`",
    f"- Expected mobile scaffold: `{android_module.rstrip('/')}`",
    f"- Expected AI config: `{llm_config}`",
    "- Default bind model: `127.0.0.1` or `::1`",
    "- Default port range: `8000-9000`",
    "",
    "## Boundaries and adapters",
    "- Runtime/system boundary: runtime code must remain independent from `_system/`.",
    f"- Tool adapters present: `{', '.join(f'{name}:{path}' for name, path in tool_adapters_present.items())}`",
    "- Precedence contract: `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` + `_system/instruction-precedence.json`",
    "- Prompt emission contract: `_system/PROMPT_EMISSION_CONTRACT.md`",
    f"- Change impact policy: `{payload['change_impact_policy_path']}`",
    f"- Self-healing boundary: `{payload['self_healing_boundary_path']}`",
    f"- Version-sensitive research protocol: `{payload['version_sensitive_research_protocol_path']}`",
    f"- Workspace authority protocol: `{payload['workspace_authority_protocol_path']}`",
    f"- Project identity/scope protocol: `{payload['project_identity_scope_protocol_path']}`",
    f"- Global redirect shim policy: `{payload['global_redirect_shim_policy_path']}`",
    f"- Scavenge/discovery authorization: `{payload['scavenge_discovery_authorization_path']}`",
    f"- Session environment report contract: `{payload['session_environment_report_contract_path']}`",
    f"- Orphan meta snapshot policy: `{payload['orphan_meta_snapshot_policy_path']}`",
    f"- Host adapter generator: `{payload['host_ingestion']['host_adapter_generator']}`",
    f"- Host adapter validator: `{payload['host_ingestion']['host_adapter_validator']}`",
    f"- Host adapter manifest: `{payload['host_ingestion']['host_adapter_manifest']}`",
    f"- Host prompt emitter: `{payload['host_ingestion']['prompt_emitter']}`",
    f"- Host ingestion validator: `{payload['host_ingestion']['prompt_validator']}`",
    f"- Host bundle contract: `{payload['host_ingestion']['host_bundle_contract']}`",
    f"- Host bundle emitter: `{payload['host_ingestion']['host_bundle_emitter']}`",
    f"- Host bundle validator: `{payload['host_ingestion']['host_bundle_validator']}`",
    "",
    "## Golden examples",
    f"- Golden example policy: `{payload['golden_examples']['policy_path']}`",
    f"- Pattern index: `{payload['golden_examples']['pattern_index_path']}`",
    f"- Manifest: `{payload['golden_examples']['manifest_path']}`",
    "",
    "## Version and compatibility markers",
    "- Human-readable version: `AIAST_VERSION.md`",
    "- Installed version marker: `_system/.template-version`",
    "- Capabilities manifest: `_system/aiaast-capabilities.json`",
    "- Operating profile JSON: `_system/repo-operating-profile.json`",
])
markdown_output = "\n".join(md_lines) + "\n"

if check:
    issues: list[str] = []
    if not md_path.exists():
        issues.append("Missing generated file: _system/REPO_OPERATING_PROFILE.md")
    elif md_path.read_text() != markdown_output:
        issues.append("Stale generated file: _system/REPO_OPERATING_PROFILE.md")
    if not json_path.exists():
        issues.append("Missing generated file: _system/repo-operating-profile.json")
    elif json_path.read_text() != json_output:
        issues.append("Stale generated file: _system/repo-operating-profile.json")
    if issues:
        print("operating_profile_out_of_date")
        for item in issues:
            print(f"- {item}")
        raise SystemExit(1)
    print("operating_profile_up_to_date")
    raise SystemExit(0)

if write:
    md_path.write_text(markdown_output)
    json_path.write_text(json_output)
    print(f"Wrote {md_path.relative_to(repo)}")
    print(f"Wrote {json_path.relative_to(repo)}")
    raise SystemExit(0)

if fmt == "markdown":
    print(markdown_output, end="")
elif fmt == "json":
    print(json_output, end="")
else:
    print(markdown_output, end="")
    print(json_output, end="")
PY
