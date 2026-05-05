# Instruction And Domain Alignment Protocol

This protocol prevents **wrong-app instruction accidents**: a human pastes a prompt meant for another product (for example cybersecurity or game client work) into a repo that is actually a **budgeting app**, **ledger**, or any other domain. Agents must **not** silently execute large off-domain changes.

It complements `_system/PROJECT_IDENTITY_AND_SCOPE_PROTOCOL.md`, which focuses on **which repo and path** are active. This document focuses on **what the user is asking for** versus **what this repo is allowed to become**.

## Authority sources (read before mutating)

1. `_system/PROJECT_DOMAIN_MANIFEST.json` — machine list of what this repo **is** and **guards against** (keywords for off-domain prompts).
2. `_system/PROJECT_PROFILE.md` — human narrative: repo purpose, product category, **Non-goals**, and constraints.
3. `PRODUCT_BRIEF.md` (if present) — product scope.

If `PROJECT_DOMAIN_MANIFEST.json` is missing, treat `_system/PROJECT_DOMAIN_MANIFEST.template.json` as the schema reference and **create** a repo-local manifest before relying on automated checks in CI.

## Mismatch detection (agent behavior)

Before **non-trivial writes** (new modules, architecture pivots, security-sensitive tooling, large dependency sets, or anything that would be expensive to undo):

1. **Paraphrase** the user request in one line: domain, implied stack, implied users.
2. **Compare** to `product_summary`, `primary_domains`, and `instruction_mismatch_guards` in `PROJECT_DOMAIN_MANIFEST.json`, and to **Non-goals** / **Repo purpose** in `PROJECT_PROFILE.md`.
3. If the request clearly belongs to a **different product category** than this repo, or hits **guard keywords** for off-domain work (see manifest), classify as **`DOMAIN_MISMATCH_SUSPECTED`**.

## Halt policy (fail closed on writes)

When `DOMAIN_MISMATCH_SUSPECTED`:

- **Do not** implement the off-domain feature set, add unrelated security tooling, or reshape the product into another vertical “because the user asked.”
- **Stop and ask** with a short, factual warning: what repo identity says vs what the prompt implies.
- Resume **only** if the operator explicitly confirms with the exact phrase documented in the active `PROJECT_DOMAIN_MANIFEST.json` field `cross_domain_confirmation_phrase` (default recommendation: `CONFIRM_CROSS_DOMAIN_INSTRUCTION` — teams may customize the string in their manifest).

If the user clarifies that the prompt was a mistake, cancel the off-domain work and continue within scope.

## Optional automation

- `bootstrap/check-instruction-domain-alignment.sh` can scan a pasted instruction against the manifest for **keyword-level** signals. It does not replace agent judgment; it helps hooks and humans catch obvious collisions.

## Maintenance

- When the product **pivots**, update both `PROJECT_DOMAIN_MANIFEST.json` and `PROJECT_PROFILE.md` in the same change set and run `bootstrap/validate-system.sh . --strict`.
