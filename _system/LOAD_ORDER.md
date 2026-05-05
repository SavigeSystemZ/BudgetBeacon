# Load Order

Use this order to bootstrap quickly without wasting context.

## Checkpoint-first rule

Before anything else, on cold start check for an in-flight resume checkpoint:

```bash
bash bootstrap/resume-from-checkpoint.sh .
```

If a checkpoint exists (exit 0), paste or summarize the briefing at the top
of your first turn, then work through its `next_actions` list. A checkpoint
represents mid-session state from the previous agent (Claude, Codex, Cursor,
Gemini, Windsurf, DeepSeek, Cline, Continue, Aider, PearAI, or a local model)
and is fresher than `WHERE_LEFT_OFF.md`. When it disagrees with any other
resume surface, the checkpoint wins because it is newer. See
`_system/CHECKPOINT_PROTOCOL.md` for the full contract.

If no checkpoint exists (exit 3), skip this step and continue with the
bundle-first rule below. An agent that cannot run `bash` should open the
LATEST.md file inside `_system/checkpoints/` (when one exists) directly
instead.

## Template sync gate (downstream repos)

Immediately after the checkpoint rule, open `_system/TEMPLATE_SYNC_NOTICE.md`.

- If **`Agent gate: PENDING_HEALTH_CHECK`** appears, the operating layer was
  refreshed from the canonical AIAST template since the last human-reviewed
  clear. Complete the checklist in that file (and in
  `DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md`) **before** product
  feature work — typically `bootstrap/system-doctor.sh` and
  `bootstrap/validate-system.sh --strict`.
- If **`Agent gate: CLEARED`** or **`NOT_APPLICABLE_TEMPLATE_SOURCE`**, there
  is no pending template-rollup health block.
- After review: `bash bootstrap/clear-template-sync-notice.sh .`

## Bundle-first rule

Before defaulting to the full tier stack, check `_system/READ_BUNDLES.md` and
pick the smallest useful bundle for the task. Use the full tiered load when the
task is broad, the context is stale, or the work spans multiple subsystems.

## Tier 0 (optional orientation)

If you are new to the repo, onboarding multiple roles, or need a **single map** of how surfaces connect, **review/validation order**, and **expansion paths**, read once:

- `_system/SYSTEM_ORCHESTRATION_GUIDE.md`

## Tier 0: Operating contract

1. `AGENTS.md`
2. `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
3. `_system/REPO_OPERATING_PROFILE.md`
4. `_system/PROJECT_PROFILE.md`
5. `_system/CONTEXT_INDEX.md`
6. `_system/KEY.md`
7. `_system/LOAD_ORDER.md`
8. `_system/WORKING_FILES_GUIDE.md`
9. `_system/TEMPLATE_NEUTRALITY_POLICY.md`
10. `_system/MASTER_SYSTEM_PROMPT.md`
11. `_system/PROJECT_RULES.md`
12. `_system/MEMORY_RULES.md`
13. `_system/EXECUTION_PROTOCOL.md`
14. `_system/MULTI_AGENT_COORDINATION.md`
15. `_system/AGENT_ROLE_CATALOG.md`
16. `_system/AGENT_DISCOVERY_MATRIX.md`
17. `_system/SYSTEM_AWARENESS_PROTOCOL.md`
18. `_system/HALLUCINATION_DEFENSE_PROTOCOL.md`

## Tier 1: Current working state

19. `WHERE_LEFT_OFF.md`
20. `TODO.md`
21. `FIXME.md`
22. `PLAN.md`
23. `PRODUCT_BRIEF.md`
24. `ROADMAP.md`
25. `DESIGN_NOTES.md`
26. `ARCHITECTURE_NOTES.md`
27. `RESEARCH_NOTES.md`
28. `TEST_STRATEGY.md`
29. `RISK_REGISTER.md`
30. `RELEASE_NOTES.md`
31. `CHANGELOG.md`
32. `_system/context/CURRENT_STATUS.md`
33. `_system/context/DECISIONS.md`
34. `_system/context/MEMORY.md`
35. `_system/context/ARCHITECTURAL_INVARIANTS.md`
36. `_system/context/ASSUMPTIONS.md`
37. `_system/context/INTEGRATION_SURFACES.md`
38. `_system/context/OPEN_QUESTIONS.md`
39. `_system/context/QUALITY_DEBT.md`

## Tier 2: Execution references

40. `_system/VALIDATION_GATES.md`
41. `_system/HANDOFF_PROTOCOL.md`
42. `_system/DEBUG_REPAIR_PLAYBOOK.md`
43. `_system/CHECKPOINT_PROTOCOL.md` — mid-session checkpointing, rate-limit and crash recovery, cross-agent resume
43a. `_system/checkpoints/README.md` — checkpoint directory layout and rules (LATEST.md is generated at runtime)
43b. `bootstrap/write-checkpoint.sh` — agent-neutral checkpoint writer
43c. `bootstrap/resume-from-checkpoint.sh` — resume briefing reader
44. `_system/REPO_BOUNDARY_AND_BACKUP.md`
45. `_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md` — remotes, SSH, fetch/pull/push when sharing work
46. `_system/HOOK_AND_ORCHESTRATION_INDEX.md` — hooks, tool adapters, CI/GitHub, plugins, MCP companions
47. `_system/MCP_CONFIG.md`
48. `_system/SECURITY_REDACTION_AND_AUDIT.md`
49. `_system/PROVENANCE_AND_EVIDENCE.md`
50. `_system/DESIGN_EXCELLENCE_FRAMEWORK.md`
51. `_system/RELEASE_READINESS_PROTOCOL.md`
52. `_system/FAILURE_MODES_AND_RECOVERY.md`
53. `_system/CODING_STANDARDS.md`
54. `_system/PERFORMANCE_BUDGET.md`
55. `_system/ACCESSIBILITY_STANDARDS.md`
56. `_system/API_DESIGN_STANDARDS.md`
57. `_system/DEPENDENCY_GOVERNANCE.md`
58. `_system/MODERN_UI_PATTERNS.md`
59. `_system/OBSERVABILITY_STANDARDS.md`
60. `_system/DELIVERY_GATES.md`
61. `_system/SECURITY_HARDENING_CONTRACT.md`
62. `_system/SECURITY_BASELINE.md`
63. `_system/THREAT_MODEL_TEMPLATE.md`
64. `_system/AI_RULES.md`
65. `_system/REPO_CONVENTIONS.md`
66. `_system/AUTONOMOUS_GUARDRAILS_PROTOCOL.md`
67. `_system/REQUEST_ALIGNMENT_PROTOCOL.md`
68. `_system/INSTALLATION_GUIDE.md`
69. `_system/PACKAGING_GUIDE.md`
70. `_system/CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
71. `_system/AGENT_INSTALLER_AND_HOST_VALIDATION_PROTOCOL.md`
72. `_system/SUB_AGENT_HOST_DELEGATION.md`
73. `_system/MOBILE_GUIDE.md`
74. `_system/CHATBOT_GUIDE.md`
75. `_system/PLUGIN_CONTRACT.md`
76. `_system/SYSTEM_REGISTRY.json`

## Tier 3: Prompting and tooling

77. `_system/PROMPTS_INDEX.md`
78. `_system/PROMPT_EMISSION_CONTRACT.md`
79. `_system/SKILLS_INDEX.md`
80. `_system/review-playbooks/`
81. `_system/prompt-templates/`
82. `_system/prompt-packs/`
83. `_system/ci/`
84. `_system/packaging/`
85. `_system/systemd/`
86. `_system/starter-blueprints/`
87. `bootstrap/system-doctor.sh`
88. `bootstrap/validate-instruction-layer.sh`
89. `bootstrap/detect-instruction-conflicts.sh`
90. `bootstrap/check-runtime-foundations.sh`
91. `bootstrap/check-evidence-quality.sh`
92. `bootstrap/check-working-file-staleness.sh`
93. `bootstrap/check-bootstrap-permissions.sh`
94. `bootstrap/run-autonomous-guardrails.sh`
95. `bootstrap/install-autonomous-guardrails.sh`
96. `.cursor/` rules, commands, skills, and agents if using Cursor (include Composer-oriented rules when using Composer)

## Targeted optional load

When the task is greenfield bootstrap, system evolution, prompt-authoring, skill-authoring, or working-file drafting, also load:

97. `_system/GOLDEN_EXAMPLES_POLICY.md`
98. `_system/golden-examples/PATTERN_INDEX.md`
99. relevant files under `_system/golden-examples/patterns/` or `_system/golden-examples/working-files/`
100. `_system/HOST_ADAPTER_POLICY.md` when the task changes tool-entry or adapter-load surfaces
101. `_system/HOST_BUNDLE_CONTRACT.md` when the task changes external host-export or bundle surfaces
102. `_system/design-system/THEME_GOVERNANCE.md` when changing global theme tokens or doing a visual overhaul
103. `_system/ports/PORT_POLICY.md` when adding Docker Compose, host publishes, or systemd socket ports
104. `_system/AUTH_AND_ONBOARDING_PATTERNS.md` when adding login, registration, guest mode, or dev-only seed admins

## Onboarding (load on demand)

105. `_system/INSTALLER_AND_UPGRADE_CONTRACT.md` — install, upgrade, repair, and state preservation
106. `_system/QUICKSTART.md` — 1-page onboarding
107. `_system/ARCHITECTURE_DIAGRAM.md` — visual system overview
108. `_system/TROUBLESHOOTING.md` — symptom-based FAQ
109. `_system/MIGRATION_GUIDE.md` — migration paths from other setups

## Fast path

If capacity is tight, load Tier 0 first, then `WHERE_LEFT_OFF.md`, `TODO.md`, `FIXME.md`, `PLAN.md`, and `PRODUCT_BRIEF.md`.

For context-budget-constrained models, use `bootstrap/emit-tiered-context.sh . --tier <A|B|C|D>` or `--model <name>` to get the appropriate load sequence. See `_system/CONTEXT_BUDGET_STRATEGY.md` for tier definitions.

When the task is installable AIAST evolution, self-healing, or version-sensitive
tooling work, also load:

110. `_system/READ_BUNDLES.md`
111. `_system/TEMPLATE_CHANGE_IMPACT_POLICY.md`
112. `_system/SELF_HEALING_BOUNDARY.md`
113. `_system/VERSION_SENSITIVE_RESEARCH_PROTOCOL.md`
114. `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`
115. `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md`
116. `_system/INSTRUCTION_DOMAIN_ALIGNMENT_PROTOCOL.md`
117. `_system/GLOBAL_REDIRECT_SHIM_POLICY.md`
118. `_system/SCAVENGE_AND_DISCOVERY_AUTHORIZATION.md`
119. `_system/SESSION_ENVIRONMENT_REPORT_CONTRACT.md`
120. `_system/ORPHAN_META_SNAPSHOT_POLICY.md`
