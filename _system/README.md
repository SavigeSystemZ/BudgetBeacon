# System Directory

`_system/` is the local agent operating system for the repository.

It exists to keep repo governance, prompting, agent workflow, MCP policy, validation, and continuity separate from runtime application code.

## What belongs here

- system prompts
- repo operating rules
- execution, debug, review, and checkpoint playbooks
- versioning, upgrade, drift, integrity, packaging, and CI scaffolds
- system registry, self-awareness, hallucination defense, and doctor flows
- instruction precedence, repo operating profile, prompt emission, and host-bundle contracts
- smallest-useful read bundles, template change-impact policy, self-healing
  boundary, and version-sensitive research discipline
- host-adapter policy and machine-readable adapter manifest
- golden example policy, pattern guides, and working-file exemplars
- MCP guidance and config examples
- prompt templates and prompt packs
- durable context state
- security, redaction, provenance, and audit rules
- observability, systemd, and plugin-extension contracts
- installation, packaging, mobile, and chatbot expansion guides
- working-file guidance and template-neutrality rules

## What does not belong here

- runtime source code
- production assets the app needs to execute
- secrets or user-level tokens
- machine-local settings files

## Design objective

Every project should have a project-local agent operating system that can be copied, evolved, and versioned with the project itself without coupling the app runtime to the system files.

That local system should stay readable to upstream hosts without becoming dependent on any one host or vendor wrapper.

The master template remains generic. Once copied into a real repo, these files become repo-local operating surfaces and should then be populated with app-specific truth.

## First read inside `_system/`

1. `PROJECT_PROFILE.md`
2. `INSTRUCTION_PRECEDENCE_CONTRACT.md`
3. `REPO_OPERATING_PROFILE.md`
4. `CONTEXT_INDEX.md`
5. `KEY.md`
6. `LOAD_ORDER.md`
7. `READ_BUNDLES.md`
8. `SYSTEM_ORCHESTRATION_GUIDE.md` (optional orientation: review order, validation order, how surfaces connect)
9. `WORKING_FILES_GUIDE.md`
10. `TEMPLATE_NEUTRALITY_POLICY.md`
11. `MASTER_SYSTEM_PROMPT.md`
12. `PROJECT_RULES.md`
13. `AGENT_DISCOVERY_MATRIX.md`
14. `UPGRADE_AND_DRIFT_POLICY.md`
15. `TEMPLATE_CHANGE_IMPACT_POLICY.md`
16. `SELF_HEALING_BOUNDARY.md`
17. `VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
18. `OBSERVABILITY_STANDARDS.md`
19. `SYSTEM_AWARENESS_PROTOCOL.md`
20. `HALLUCINATION_DEFENSE_PROTOCOL.md`
21. `DELIVERY_GATES.md`
22. `AUTONOMOUS_GUARDRAILS_PROTOCOL.md`
23. `REQUEST_ALIGNMENT_PROTOCOL.md`

When creating or upgrading working files, prompt packs, skills, or system docs, also load `GOLDEN_EXAMPLES_POLICY.md` and `golden-examples/PATTERN_INDEX.md`.

After scaffold into a real app repo, fill these app-specific placeholder
contracts early:

- `AI_RULES.md`
- `REPO_CONVENTIONS.md`
- `SECURITY_BASELINE.md`

If the task changes tool-entry or adapter-load surfaces, also load `HOST_ADAPTER_POLICY.md`.

If the task changes external host-export or bundle surfaces, also load `HOST_BUNDLE_CONTRACT.md`.
