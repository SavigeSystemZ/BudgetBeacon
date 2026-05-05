# Self-Improvement Protocol

This protocol defines how AIAST autonomously "learns" from improvements discovered in project-specific repositories without importing project-specific facts or context.

## The Loop: Harvest -> Sanitize -> Promote

### 1. Identify & Tag (Downstream)
When an agent or operator makes a generic improvement to the agent operating system in a project-specific repo (e.g., a better prompt, a more robust script, or a clearer rule):
- **Command:** `bash bootstrap/tag-improvement-candidate.sh <path> --description "..."`
- **Result:** The file/change is recorded in `_system/improvement-candidates.jsonl`.

### 2. Harvest (Maintainer)
Maintainers periodically scan registered candidates from the fleet:
- **Command:** `bash _META_AGENT_SYSTEM/scripts/harvest-improvements.sh`
- **Action:** Pulls candidate files into a temporary maintainer staging area.

### 3. Sanitize (Maintainer)
Every candidate must pass the **Neutrality Gate**:
- **Scrub:** Remove any project-specific names, URLs, ports, or logic.
- **Generalize:** Ensure the improvement applies to *all* AIAST projects.
- **Review:** Validate against the `PROMOTION_POLICY.md`.

### 4. Promote (Maintainer)
Once sanitized and approved, the improvement is merged into the master `TEMPLATE/`.
- **Command:** `_TEMPLATE_FACTORY/check-promotion-readiness.sh <path>`
- **Release:** The change is included in the next AIAST version bump.

## Candidate Criteria
An improvement is a candidate if it:
1. Fixes a logic bug in a bootstrap script.
2. Improves the clarity or effectiveness of a system prompt.
3. Enhances a validation check (e.g., adding a new edge case).
4. Adds a useful new neutral pattern to the golden examples.

## Prohibited from Promotion
1. Any file containing project-specific domain facts.
2. Hard-coded paths that only exist in one project.
3. Logic that depends on project-specific third-party libraries.
4. "Flavor" changes that deviate from the core AIAST design philosophy.

---
**Authority:** AIAST Promotion Policy (Maintainer-only)
**Downstream Tool:** `bootstrap/tag-improvement-candidate.sh`
**Maintainer Tool:** AIAST Harvest Script (Maintainer-only)
