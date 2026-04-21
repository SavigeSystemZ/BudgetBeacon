---
name: concise-communication
description: Opt-in ultra-concise assistant replies to reduce OUTPUT tokens (Caveman-style). Use when the user asks for caveman, token-efficient, terse, or compressed answers; or for long/cost-sensitive sessions. NOT default—never use for handoffs, legal/safety text, or verbatim user requirements.
---

# Concise communication (token-efficient output)

## Purpose

Compress **assistant output** (not user instructions): drop filler, hedging, and redundant prose while keeping **full technical accuracy**. Pattern aligns with the community **Caveman** skill ([JuliusBrussee/caveman](https://github.com/JuliusBrussee/caveman), MIT); this repo ships a **host-neutral** Cursor skill so any agent that reads `.cursor/skills/` can apply the same rules.

**Important:** Savings apply mainly to **output** tokens. **Input** context (repo, rules, large files) usually dominates cost—pair with `_system/CONTEXT_BUDGET_STRATEGY.md` and tiered loading for input-side efficiency. For optional compression of long **human-authored** notes (eligible `docs/` / `notes/` paths only), use `/compress-context` and `compress-context-input`—never confuse that workflow with this output skill.

## When to activate (explicit user intent)

- User says: caveman, concise, terse, token-efficient, fewer tokens, no fluff, bullet-only, etc.
- User runs command **`/concise-session`** (see `.cursor/commands/concise-session.md`).
- Long or budget-sensitive sessions **after** the user opts in.

## When NOT to use (override concise mode)

- **Handoff / continuity:** `WHERE_LEFT_OFF.md`, `HANDOFF_PROTOCOL.md`, checkpoint packets—must stay complete and unambiguous.
- **User instructions:** reproduce requirements **verbatim** when ambiguity would change behavior; do not “compress away” constraints.
- **Security, compliance, legal, accessibility:** prefer clarity over brevity; do not omit warnings or steps.
- **Exact quotes:** error messages, logs, file paths, commands, API signatures—copy verbatim.
- **Git commits / PRs / release notes:** use normal professional tone unless the user explicitly wants terse style there too.

## Intensity levels

| Level | Behavior |
|-------|----------|
| **lite** | Remove filler; keep full sentences and grammar. |
| **full** (default) | Short sentences; fragments OK; strip articles where safe; no pleasantries. |
| **ultra** | Telegraphic; minimal connective words; only for expert readers and non-handoff work. |

If the user does not specify, use **full**.

## Rules (always)

- Preserve **code blocks**, **inline code**, **paths**, **URLs**, **numbers/versions**, **commands**, and **quoted tool output** exactly.
- Do not shorten or paraphrase **user requirements** or **acceptance criteria**.
- Do not skip **validation steps** or **safety checks** to save words—state them compactly instead.
- Stop when the answer is complete; do not add engagement filler.

## Deactivate

- User says: normal mode, stop concise, verbose, full sentences, etc.

## Related

- `_system/CONTEXT_BUDGET_STRATEGY.md` — input-side tiering.
- `_system/CONTEXT_INDEX.md` — find other workflows.
- Upstream optional install: `npx skills add JuliusBrussee/caveman` (Claude Code/Codex plugins; separate from this repo skill).
