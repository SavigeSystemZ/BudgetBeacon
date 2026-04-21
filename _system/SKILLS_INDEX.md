# Skills Index

The skills in `.cursor/skills/` are reusable operating workflows for this system.

They support the shared roles defined in `_system/AGENT_ROLE_CATALOG.md`; they do not replace that role model.

For how skills, validation scripts, and handoff files fit together in one checklist, see `_system/SYSTEM_ORCHESTRATION_GUIDE.md`.

## Included skills

- `load-context` — boot a session correctly
- `code-review` — review changes against the repo contract
- `code-quality-review` — review code for clean code standards, naming, error handling, and anti-patterns
- `debug-playbook` — reproduce, localize, fix, and verify failures
- `verify-gate` — run and report required validation
- `prompt-pack-generator` — build grounded milestone prompts
- `mcp-config` — generate least-privilege MCP config
- `checkpoint-handoff` — prepare clean continuity for the next tool or human
- `architecture-review` — review structural decisions and boundaries
- `release-readiness` — assess milestone or release readiness
- `design-review` — assess product and interface quality
- `accessibility-review` — audit UI for WCAG compliance, keyboard access, and screen reader support
- `performance-review` — audit for performance budget compliance and optimization opportunities
- `dependency-review` — review dependencies for security, license, size, and necessity
- `concise-communication` — **opt-in** ultra-concise assistant output (output-token efficient; Caveman-style). Use command `/concise-session` or when the user asks for terse/token-efficient replies. Never default; never compress away requirements or handoff quality.
- `compress-context-input` — **opt-in** checklist for shrinking long **human-edited** markdown under `docs/` or `notes/` via `bootstrap/compress-context-file.sh` (upstream caveman-compress). Use command `/compress-context`. Does **not** replace tiered loading; never target generated adapters or contract files.

## Supporting tools

These bootstrap scripts support skill workflows but are not skills themselves:

- `bootstrap/compress-context-file.sh` — optional Caveman-style **input** file compression (denylisted paths + `docs/`/`notes/` allowlist); delegates to upstream caveman-compress when installed
- `bootstrap/wizard.sh` — interactive AIAST setup wizard
- `bootstrap/upgrade-assistant.sh` — interactive upgrade guide
- `bootstrap/run-sast.sh` — static application security testing
- `bootstrap/check-supply-chain.sh` — dependency supply chain audit
- `bootstrap/scan-container.sh` — container security scanning
- `bootstrap/check-network-bindings.sh` — network binding compliance
- `bootstrap/check-environment.sh` — runtime prerequisite validation
- `bootstrap/track-semantic-changes.sh` — semantic change classification
- `bootstrap/discover-plugins.sh` — plugin discovery and status
- `bootstrap/emit-tiered-context.sh` — context-budget-aware loading

## Rule

Skills extend repo behavior. They do not override `AGENTS.md`, `_system/PROJECT_RULES.md`, or the checkpoint and validation protocols.

When creating a new skill or substantially changing a skill workflow, consult `_system/GOLDEN_EXAMPLES_POLICY.md` and `_system/golden-examples/PATTERN_INDEX.md` first.
