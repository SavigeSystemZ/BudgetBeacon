# M15 Whole-Repo Analysis Prompt Pack (Tier S)

## M15.0 Deep Architectural Review

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Load the entire repo including all files in _system/ and all primary application source code.
Identify cross-cutting architectural patterns, boundary violations, and hidden dependencies.

Deliver:
1. architectural health scorecard
2. identification of "leaky" abstractions
3. specific recommendations for contract tightening
4. prioritized refactor roadmap with risk assessment
```

## M15.1 System-Wide Consistency Audit

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Scan all documentation in _system/ and compare against the actual implementation in the runtime code.
Detect contradictions between AGENTS.md, PROJECT_RULES.md, and the current codebase.

Deliver:
1. list of documentation-to-code mismatches
2. identification of stale or abandoned "truth" files
3. proposed updates to synchronize governance with reality
```

## M15.2 Comprehensive Impact Analysis

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, and _system/LOAD_ORDER.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Before a major refactor or breaking change, analyze the blast radius across the entire repository.
Identify affected components, broken tests, and necessary documentation updates.

Deliver:
1. dependency blast radius map
2. hidden side-effect warnings
3. step-by-step migration sequence for a zero-downtime/zero-breakage landing
```
