# Decisions

Record durable decisions here.

## Entry format

- Date:
- Decision:
- Reason:
- Impact:
- Follow-up:
- Revisit trigger:

## Entries

### 2026-04-12 — Import SACST governance mechanics in adapted form only

- **Decision:** Upgrade AIAST with SACST governance mechanics only, implemented as installable read-bundle, change-impact, self-healing-boundary, and version-sensitive-research contracts plus maintainer-only learning and promotion policy.
- **Reason:** AIAST was already stronger in app-builder breadth, host ingestion, orchestration, prompt emission, and adapter generation; the real gap was governance purity and promotion discipline, not infra-domain capability.
- **Impact:** Installable AIAST gained new `_system/` governance contracts while maintainer-only donor review and promotion doctrine stayed in `_META_AGENT_SYSTEM/` and `_TEMPLATE_FACTORY/`.
- **Follow-up:** Validate the tranche on real downstream app repos before broadening cross-template harvest rules or mirroring changes back into SACST.
- **Revisit trigger:** If bundle selection, change-impact governance, or promotion gates create repeated downstream friction that outweighs the drift they prevent.

### 2026-04-06 — GitHub PR and issue templates (installable template)

- **Decision:** Ship `.github/pull_request_template.md` and `.github/ISSUE_TEMPLATE/` with the template so downstream repos inherit merge and triage discipline without ad hoc copy-paste.
- **Reason:** Reduces bad merges, documents validation expectations, pairs with GitHub / CI steward role and `HOOK_AND_ORCHESTRATION_INDEX.md`.
- **Impact:** New files under `.github/` in copied repos; optional for teams that delete them.
- **Follow-up:** Master AIAST repo also uses root `.github/` templates for layer-specific checklists.
- **Revisit trigger:** If GitHub changes issue template schema or org-wide templates override repo templates.

### 2026-04-06 — Working-file freshness pass

- **Decision:** Refresh `PLAN.md`, `FIXME.md`, `RISK_REGISTER.md`, `TEST_STRATEGY.md` with baseline text and explicit template-review stamp to satisfy staleness checks and give downstream a clearer default.
- **Reason:** `check-working-file-staleness.sh` uses git history; substantive content + commit clears warnings and improves handoff quality.
- **Impact:** Downstream repos may merge or replace sections when they diverge from placeholder baselines.
