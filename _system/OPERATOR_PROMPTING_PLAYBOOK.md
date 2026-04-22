# Operator Prompting Playbook

This playbook provides reusable command patterns for high-signal multi-agent work in AIAST-installed repos.

It is vendor-neutral and designed to produce execution-ready outputs instead of generic prose.

## Core Operating Pattern

Use execution contracts, not open-ended prompts.

Minimum contract sections:

1. Role
2. Mission
3. Context packet
4. Constraints and non-negotiables
5. Output contract
6. Completion criteria
7. Validation requirements
8. Stop/approval gates

## Context Packet Template

Use this structure before major runs:

```text
PROJECT:
GOAL:
CURRENT_STATE:
CONSTRAINTS:
NON_NEGOTIABLES:
KNOWN_RISKS:
REQUIRED_OUTPUT:
SUCCESS_CRITERIA:
```

## Massive Continuous Run Protocol

Use when a task should continue across multiple phases without early stopping.

Required clauses:

- phase-based execution
- dependency-aware ordering
- short milestone updates only
- self-review after each phase
- blocker reporting with attempted mitigations
- explicit final status: done, partial, blocked

Safety rule: continuous execution is not infinite chat. Use checkpoints and resumable state in repo files.

## Multi-Agent Topologies

### Planner -> Executor -> Critic -> Synthesizer

Use for quality-critical work:

1. Planner defines task graph and acceptance criteria.
2. Executor performs implementation.
3. Critic red-teams correctness and risk.
4. Synthesizer merges results and removes contradictions.

### Fan-Out / Fan-In

Use for parallelizable research or analysis:

- Fan-out: assign disjoint subproblems.
- Fan-in: reconcile conflicts, rank options, emit one integrated output.

## Prompt Language That Improves Outcomes

Prefer these terms:

- output contract
- acceptance criteria
- verification loop
- dependency-aware execution
- regression check
- approval gate
- rollback plan
- traceability

Avoid weak commands such as "make it better" without constraints.

## Master Prompt Skeleton

```text
ROLE:
Act as [role].

MISSION:
Deliver [exact output].

CONTEXT:
[context packet]

EXECUTION MODE:
Phased, dependency-aware, with critic pass and validation loop.

NON_NEGOTIABLES:
[what must not change]

OUTPUT CONTRACT:
[required sections]

COMPLETION CRITERIA:
[definition of done]
```

## Evaluation Rubric Pattern

Before finalizing, score output 1-10 on:

- correctness
- completeness
- actionability
- risk handling
- implementation realism
- maintainability

Revise any category below 9 if task criticality requires world-class output.

## Coding-Agent Command Addendum

For implementation tasks, include:

- inspect before editing
- preserve working behavior unless instructed otherwise
- small reversible diffs
- validation commands with results
- explicit regression-risk callout

## Security and Safety Prompt Guardrails

Always require:

- least privilege
- no secret exposure
- explicit approval for destructive actions
- rollback instructions for risky operations

## Downstream Adaptation Rule

Project-specific repos should keep this playbook as a base and append domain-specific variants (for example security-heavy, performance-heavy, product-design-heavy) without overriding core safety or truthfulness requirements.
