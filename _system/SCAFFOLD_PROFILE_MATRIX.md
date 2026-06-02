# Scaffold Profile Matrix

Profiles define installable include/exclude behavior, default guardrails, and
validation expectations for downstream scaffolds.

The machine-readable contract lives in `_system/scaffold-profiles.json`.
`_system/runtime-profiles/scaffold-profiles.json` remains a legacy compatibility
surface for older validators. New scaffold behavior must use
`bootstrap/render-scaffold-profile.sh`.

## Profile Contract Fields

Each profile must declare:

- included surfaces
- excluded surfaces
- required docs
- required validators
- default guardrails
- installer expectations
- port/network expectations
- runtime foundation expectations
- mobile/desktop/web expectations
- security/privacy baseline
- fleet compatibility
- downstream mutability model
- quality score target

## Profile Matrix

### `minimal`
- included surfaces: base `_system`, context index, validation core
- excluded surfaces: optional benchmark and external harvest lanes
- required docs: `README.md`, `PLAN.md`, `TODO.md`
- required validators: `validate-system`, `check-system-awareness`
- default guardrails: strict boundary checks, no global writes
- installer expectations: basic install/repair/uninstall contract
- port/network expectations: loopback only, non-default port
- runtime expectations: minimal generated runtime foundations
- platform expectations: CLI-first
- security/privacy baseline: secrets redaction + least privilege
- fleet compatibility: single writer, optional observers
- downstream mutability: high for app-owned files
- quality score target: >=70

### `standard`
- included surfaces: full default template system
- excluded surfaces: maintainer-only MOS internals
- required docs: `PRODUCT_BRIEF.md`, `TEST_STRATEGY.md`, `RISK_REGISTER.md`
- required validators: `validate-system --strict`, `system-doctor`
- default guardrails: preserve-first updates
- installer expectations: standard installer and setup checks
- port/network expectations: governed ports + collision checks
- runtime expectations: standard runtime foundations
- platform expectations: web/desktop/cli baseline support
- security/privacy baseline: policy + audit trace
- fleet compatibility: multi-agent with scoped leases
- downstream mutability: app-owned files mutable, template-managed controlled
- quality score target: >=80

### `advanced`
- included surfaces: standard + extended governance and diagnostics
- excluded surfaces: maintainer-only source-repo artifacts
- required docs: standard docs + architecture and design notes
- required validators: strict + host-adapter and orchestration checks
- default guardrails: bounded auto-correction
- installer expectations: installer maturity and smoke checks
- port/network expectations: service-class-aware allocation
- runtime expectations: extended runtime foundations
- platform expectations: multi-surface support
- security/privacy baseline: hardened defaults
- fleet compatibility: concurrent lanes with heartbeats
- downstream mutability: constrained by contract
- quality score target: >=85

### `super`
- included surfaces: maximum installable governance surface
- excluded surfaces: maintainer-only master-repo planning
- required docs: full working-file set
- required validators: strict lane + factory alignment checks
- default guardrails: autonomous guardrails enabled
- installer expectations: release-grade install/repair validation
- port/network expectations: strict governed allocation + checks
- runtime expectations: complete runtime foundations
- platform expectations: web/desktop/mobile/cli adaptable
- security/privacy baseline: hardened + audit-ready
- fleet compatibility: full multi-agent protocol support
- downstream mutability: controlled by template contracts
- quality score target: >=90

### `security-heavy`
- included surfaces: security hardening + audit + authorized research mode
- excluded surfaces: insecure or unreviewed experimental paths
- required docs: threat model, security baseline, risk register
- required validators: security scan + strict system checks
- default guardrails: no unsafe auto-repair tiers
- installer expectations: privileged actions explicitly gated
- port/network expectations: loopback-first, no public DB/cache publishes
- runtime expectations: hardened runtime services
- platform expectations: security-focused deployment patterns
- security/privacy baseline: maximum hardening
- fleet compatibility: explicit security steward lane
- downstream mutability: restricted for security contracts
- quality score target: >=92

### `ai-heavy`
- included surfaces: AI runtime + prompt governance + fallback policy
- excluded surfaces: unconstrained provider-specific assumptions
- required docs: model policy, prompt safety, fallback map
- required validators: AI safety + strict core validators
- default guardrails: redaction and no-secrets-in-prompts
- installer expectations: provider config checks
- port/network expectations: governed AI service ports
- runtime expectations: AI scaffolds and dependency checks
- platform expectations: API + UI/agent surfaces
- security/privacy baseline: prompt and data protection controls
- fleet compatibility: AI lane and reviewer lane
- downstream mutability: moderate under policy
- quality score target: >=88

### `mobile-apk`
- included surfaces: mobile guide + packaging + installer checks
- excluded surfaces: non-mobile-only launch assumptions
- required docs: mobile UX, permissions policy, release guide
- required validators: APK build + mobile smoke + strict core
- default guardrails: signed artifact expectations
- installer expectations: mobile install path included
- port/network expectations: client-safe defaults
- runtime expectations: mobile runtime compatibility
- platform expectations: Android-first with backend compatibility
- security/privacy baseline: mobile permission minimization
- fleet compatibility: build + QA lanes
- downstream mutability: app features mutable, policy contracts fixed
- quality score target: >=85

### `desktop`
- included surfaces: desktop packaging and launcher standards
- excluded surfaces: mobile-only constraints
- required docs: installer, launch behavior, desktop UX
- required validators: desktop smoke + install checks + strict core
- default guardrails: launcher and path safety
- installer expectations: desktop installer readiness
- port/network expectations: local service safety checks
- runtime expectations: desktop runtime dependencies
- platform expectations: desktop-first
- security/privacy baseline: local data handling safeguards
- fleet compatibility: packaging + QA lanes
- downstream mutability: moderate
- quality score target: >=84

### `web-saas`
- included surfaces: web/api/package/deployment contracts
- excluded surfaces: host-specific desktop/mobile assumptions
- required docs: API, UX, auth, operations runbook
- required validators: API tests + security + build + strict core
- default guardrails: authz and data separation controls
- installer expectations: deploy and migration guidance
- port/network expectations: non-default published port policy
- runtime expectations: web and API runtime foundations
- platform expectations: web-first
- security/privacy baseline: SaaS-grade posture
- fleet compatibility: backend/frontend/review lanes
- downstream mutability: moderate under delivery gates
- quality score target: >=88

### `fullstack`
- included surfaces: web + API + data + install/deploy guidance
- excluded surfaces: irrelevant single-surface shortcuts
- required docs: data model, API, UX, deploy runbook
- required validators: unit/integration/build/security/strict core
- default guardrails: schema and migration safety
- installer expectations: fullstack setup + smoke checks
- port/network expectations: coordinated multi-service ports
- runtime expectations: complete app stack foundations
- platform expectations: fullstack web-centric
- security/privacy baseline: end-to-end access controls
- fleet compatibility: multi-lane domain routing
- downstream mutability: controlled with migration policies
- quality score target: >=89

### `homelab`
- included surfaces: service install, runtime, and ops visibility
- excluded surfaces: managed-cloud-only assumptions
- required docs: install, repair, backup, operations
- required validators: install + service + port checks + strict core
- default guardrails: preserve existing host state
- installer expectations: unattended and repairable workflows
- port/network expectations: local-network safe defaults
- runtime expectations: service lifecycle and resilience
- platform expectations: self-host and local infra
- security/privacy baseline: private-network hardening
- fleet compatibility: ops and reliability lanes
- downstream mutability: moderate with ops controls
- quality score target: >=83

### `meta-system-development`
- included surfaces: full installable + meta maintenance integration
- excluded surfaces: none of required maintainer pathways
- required docs: governance, evidence, rollout and boundary protocols
- required validators: strict + factory + meta validation lanes
- default guardrails: highest boundary and provenance controls
- installer expectations: template and downstream compatibility checks
- port/network expectations: governed and audited
- runtime expectations: full compatibility
- platform expectations: system-of-systems maintenance
- security/privacy baseline: maintainer-grade controls
- fleet compatibility: full fleet control tower
- downstream mutability: low for contract surfaces
- quality score target: >=95

## Enforcement Notes

- MOS maintainer-only surfaces are excluded from non-meta profiles.
- Profile authors must follow `_system/SCAFFOLD_PROFILE_AUTHORING_STANDARD.md`.
- Parent-template layers (`_META_AGENT_SYSTEM/`, `_TEMPLATE_FACTORY/`,
  `_MOS_TEMPLATE_FACTORY/`, `MOS_TEMPLATE/`, `MOS_SOURCE_LIBRARY/`) are never
  copied by normal app scaffolds. `meta-system-development` exposes maintainer
  contracts inside `TEMPLATE/_system/`; MOS projects still use MOS bootstrap.
- Until narrowed profiles have their own strict validators and benchmark
  evidence, profiles are policy overlays over the full installable AIAST
  operating layer rather than partial-file installs.
