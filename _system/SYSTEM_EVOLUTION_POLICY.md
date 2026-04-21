# System Evolution Policy

This operating system should evolve without collapsing into duplication or drift.

## Adding new tools

- add the adapter file
- update `AGENT_DISCOVERY_MATRIX.md`
- update `CONTEXT_INDEX.md` if load order changes
- ensure the adapter does not contradict `AGENTS.md`
- if the adapter is part of the generated adapter set, follow `_system/HOST_ADAPTER_POLICY.md`, update `_system/host-adapter-manifest.json`, and regenerate via `bootstrap/generate-host-adapters.sh`

## Adding new subsystems

- prefer one authoritative doc per subsystem
- link it from `CONTEXT_INDEX.md`
- add it to `LOAD_ORDER.md` only if it is routinely required
- if the subsystem benefits from reusable examples, add or update the golden example pack instead of copying donor-app prose directly into canonical docs
- if the subsystem exports host-facing snapshots, give it one explicit contract and one validator instead of scattering host-specific rules across multiple docs
- if the subsystem changes installable behavior, classify it with
  `TEMPLATE_CHANGE_IMPACT_POLICY.md`

## Deprecating files

- mark the replacement in the deprecated file
- update indexes and adapters
- remove the old file only after the replacement is fully live

## Versioning the operating system

- update `CHANGELOG.md`
- update `_TEMPLATE_FACTORY/BUILD_REPORT.md` in the master repo when the canonical template meaningfully changes
- keep `_TEMPLATE_FACTORY/SOURCE_LIBRARY/` as the provenance base for future merge work
- refresh `_TEMPLATE_FACTORY/GOLDEN_EXAMPLES/` when donor maturity or selection changed
- use `bootstrap/install-missing-files.sh` to seed newly added files into existing installed repos without overwriting repo-owned state, while also backfilling missing generated runtime scaffolds and safe onboarding defaults
- if tool-entry or adapter-load surfaces changed, run `bootstrap/check-host-adapter-alignment.sh` before declaring the change done
- if external host-emission or bundle surfaces changed, run `bootstrap/check-host-ingestion.sh` and `bootstrap/check-host-bundle.sh` before declaring the change done
- if current framework, package, installer, platform, or API behavior influences
  the design, follow `VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
