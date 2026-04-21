# Template Neutrality Policy

This policy keeps the master operating-system template reusable across many applications.

## Master template rule

Inside the master template source:

- working files may exist in app-shaped form
- section structures, entry formats, and usage rules are expected
- app-specific product facts must not be stored here

## Allowed content in the master template

- generic file structure
- example entry formats
- reusable operating rules
- placeholder headings
- neutralized golden-example packs that demonstrate quality level without carrying donor-app truth
- repo-agnostic design, architecture, testing, and risk guidance
- host-safe instruction contracts and machine-readable metadata that stay repo-agnostic

## Disallowed content in the master template

- real app names or product domains
- real repository URLs, ports, secrets, or credentials
- app-specific milestone plans
- app-specific design direction
- app-specific architecture or data model facts
- app-specific release notes or risk posture
- raw donor-repo excerpts that would cause a new project to inherit another app's live reality
- host-specific or vendor-specific policy that makes AIAST depend on one orchestrator
- maintainer-only AIAST planning, research, handoff state, or future system-design files that belong to the master source repo rather than to installed app repos

## Master-repo-only meta workspace

In the AIAST source repo, maintainer-only design and planning state belongs outside the installable tree in a dedicated master-repo-only meta workspace.

That workspace is allowed to carry AIAST-specific system-design truth precisely because it is not copied into app repos by the normal install flow.

## After install into a real repo

Once this system is copied into a target repo:

1. Fill in `_system/PROJECT_PROFILE.md`.
2. Replace placeholders with repo-specific truth.
3. Keep the working files current as the repo evolves.
4. Do not sync app-specific content back into the master template source.

## Why this exists

Without this rule, the master template becomes contaminated with one app's reality and stops being a clean operating base for the next app.

Host-safe prompt emission must stay path-based and generic. Use `_system/PROMPT_EMISSION_CONTRACT.md` as the rule surface for emitted prompts and `_system/HOST_BUNDLE_CONTRACT.md` for self-contained external bundles. They can reference canonical repo files, but they must not hardcode app-specific product facts or vendor-specific host dependencies into the master template.

Golden examples are allowed only when they are neutralized into structure, checklist, and quality-bar guidance. The donor-app provenance belongs in the factory, not in installed repos.
