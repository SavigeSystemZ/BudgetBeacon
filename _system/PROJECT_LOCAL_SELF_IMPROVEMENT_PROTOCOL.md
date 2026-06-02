# Project-Local Self-Improvement Protocol

This protocol defines how an agent building an app inside a **scaffolded
downstream repo** may safely improve its **own project-local AIAST copy**
while it works.

It is the downstream counterpart to `SELF_IMPROVEMENT_PROTOCOL.md`. That
protocol is the *maintainer* loop (harvest -> sanitize -> promote generic
improvements into the parent template). This protocol is the *downstream-local*
loop: improve the local copy in place, never the parent template.

## When this applies

Resolve role via `_system/.aiast-role.json` (`bootstrap/check-app-definition-state.sh`):

- `role = parent-template` -> this protocol does not apply; improve the
  template through the maintainer loop instead.
- `role = downstream-app` -> this protocol applies. The local AIAST copy in
  this repo is yours to tailor, within `SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`.

It is an **optional, additive overlay**: a downstream repo that never invokes
it is unaffected, and the parent template ships it inert.

## The loop: Detect -> Propose -> Apply -> Validate -> Record -> (Tag)

### 1. Detect a local need

Trigger the loop when you observe a concrete gap in *this repo's* operating
layer, for example:

- a missing or unfilled app-context file (`APP_CONTEXT_FILE_MATRIX.md`);
- an unclear or app-mismatched local rule;
- a repeated validation failure the current gates do not explain;
- a missing archetype detail for this app's stack;
- a weak handoff/checkpoint that lost continuity;
- a missing local MCP / agent-isolation note;
- a missing local prompt-pack variant for this app's domain.

A vague "could be better" is not a trigger. Name the gap and the evidence.

### 2. Propose

```
bash bootstrap/propose-local-self-improvement.sh \
  --title "<short imperative title>" \
  --scope "<path or surface inside this repo>" \
  --reason "<what gap this closes, with evidence>"
```

Writes `_system/self-improvement/proposals/<timestamp>-proposal.md`: a
reviewable record of intent, planned in-repo changes, the improvement class
(allowed / guarded), and rollback notes. Proposing changes nothing else.

### 3. Apply (local only)

```
bash bootstrap/apply-local-self-improvement.sh <proposal-id> --local-only
```

Records the base git commit and a reverse patch, performs the change **only inside this repo**, moves the proposal to `_system/self-improvement/applied/`,
and appends a ledger entry. It hard-refuses any path outside the repo root and
refuses to run in `parent-template` mode. See
`SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`.

### 4. Validate

Re-run the validators that own the changed scope, always including:

```
bash bootstrap/check-local-self-improvement.sh .
bash bootstrap/validate-app-context-files.sh .   # if app-context changed
bash bootstrap/validate-system.sh . --strict
```

A self-improvement is not "done" until validation passes. If validation fails,
roll back (`SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`) and revise the proposal —
do not leave a half-applied change.

### 5. Record evidence

The ledger entry (`_system/self-improvement/ledger.jsonl`) and the file in
`applied/` are the durable record: what changed, why, base commit, validation
result. A rejected or reverted proposal moves to
`_system/self-improvement/rejected/` with the reason.

### 6. Optionally tag a generic candidate

If the improvement turns out to be **generic** — useful to *every* AIAST app,
carrying no app-specific facts — tag it for the maintainer promotion loop:

```
bash bootstrap/tag-improvement-candidate.sh <file> \
  --description "Generic improvement found during downstream app build"
```

This only *records a candidate* in `_system/improvement-candidates.jsonl`. It
does not promote anything. Maintainers later harvest, sanitize, and promote it
per `SELF_IMPROVEMENT_PROTOCOL.md`. Promotion stays maintainer-gated.

## Candidate rubric — is a local improvement generic?

Tag as a candidate **only if all** hold:

- it carries no app name, domain fact, URL, port, secret, or stack-specific
  logic;
- it would help any AIAST app, not just this one;
- it improves a neutral surface — a bootstrap script, a validator, a neutral
  prompt, a golden-example pattern, a contract clarity fix;
- it does not depend on this app's third-party libraries or runtime.

If any fails, it is an app-specific local improvement: keep it local, do not
tag it. App-specific facts must never reach the parent template
(`TEMPLATE_NEUTRALITY_POLICY.md`).

## What "validated" means (validation gate)

A local self-improvement clears the gate when:

- `check-local-self-improvement.sh` reports the apply stayed in-repo and the
  ledger is intact;
- every validator owning the changed surface passes (e.g.
  `validate-app-context-files.sh` for app-context, `validate-system.sh
  --strict` for managed contracts);
- the change is recorded with rollback evidence;
- no parent-template, sibling-repo, or global surface was touched.

## Boundaries

Improvement classes (allowed / guarded / forbidden), the write-scope rule, and
rollback discipline are defined in `SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`.
Read it before applying anything.

---
**Authority:** AIAST downstream operating protocol; applies in `downstream-app`
repos. Subordinate to `INSTRUCTION_PRECEDENCE_CONTRACT.md` and the security and
containment contracts.
**Related:** `SELF_WRITING_BOUNDARY_AND_ROLLBACK.md`,
`SELF_IMPROVEMENT_PROTOCOL.md` (maintainer loop),
`APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md`, `SELF_HEALING_BOUNDARY.md`,
`WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md`.
