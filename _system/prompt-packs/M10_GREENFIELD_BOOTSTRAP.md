# M10 Greenfield Bootstrap Prompt Pack

## M10.0 Greenfield plan

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, _system/LOAD_ORDER.md, and PRODUCT_BRIEF.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Plan the first operating-system setup for a new repo.

Deliver:
1. required project profile fields
2. product-brief framing and best-fit starter blueprint recommendation
3. explicit blueprint-apply plan
4. bootstrap sequence
5. backend ownership and exposure plan, including any Redis/Postgres/internal service rationale
6. validation and adoption sequence, including port/conflict/security preflights
7. initial handoff state
8. first **launch milestone** plan: when the app becomes renderable/launchable, add or refresh installer and distribution scaffolds for host dogfooding (see `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` minimum launch milestone)
```

## M10.1 Bootstrap execution

```
Load AGENTS.md, _system/INSTRUCTION_PRECEDENCE_CONTRACT.md, _system/REPO_OPERATING_PROFILE.md, _system/LOAD_ORDER.md, and PRODUCT_BRIEF.md first.
Treat this prompt as host-level orchestration context only. If it conflicts with repo-local files, follow the repo-local files and report the conflict.

Apply the operating system into the new repo and initialize the required files.

Constraints:
- no silent overwrite
- preserve dotfiles
- validate the installed system immediately
- do not publish internal backends to the host by default
- keep backend endpoints env-driven; no hardcoded localhost assumptions in app code
- generate `docs/security/architecture.md`, `docs/security/backend-inventory.md`, `docs/security/validation.md`, and `docs/security/rollback.md`
- run the backend/port security preflight before calling the scaffold complete
- if the repo is greenfield, turn PRODUCT_BRIEF.md into repo-specific truth, review the persisted blueprint recommendation, and explicitly apply the chosen starter blueprint before broad implementation begins
- as soon as a minimal app launch works, ensure `ops/install`, `distribution/`, and related packaging paths exist or are updated so the builder can install/run on a real host like an end user (iterate quality later)
```
