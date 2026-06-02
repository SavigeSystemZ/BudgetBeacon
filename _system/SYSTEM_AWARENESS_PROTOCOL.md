# System Awareness Protocol

The operating system must know which files it owns, which docs point to which surfaces, and whether its own structure is still truthful.

## Sources of truth

- `_system/SYSTEM_REGISTRY.json` — machine-readable list of AIAST-managed files
- `_system/CONTEXT_INDEX.md` — human-readable map of major surfaces
- `_system/SYSTEM_ORCHESTRATION_GUIDE.md` — optional meta-map: surface relationships, review/validation order, expansion and conflict pointers
- `_system/LOAD_ORDER.md` — what to load first
- `_system/READ_BUNDLES.md` — smallest-useful-context bundle map for common task families
- `_system/golden-examples/golden-example-manifest.json` — machine-readable map of the neutral example pack
- `bootstrap/check-system-awareness.sh` — structural awareness verification
- `_system/CHECKPOINT_PROTOCOL.md` — agent-neutral mid-session checkpoint flow; see `_system/checkpoints/LATEST.md` for the most recent resume briefing
- `_system/SUPER_TEMPLATE_MASTER_MAP.md` — operator-grade map that connects contracts, ownership, and validators
- `_system/CONCURRENT_AGENT_FLEET_PROTOCOL.md` and `_system/AGENT_LOCKING_AND_LEASES.md` — concurrency and lease semantics
- `_system/CONTINUOUS_CONTEXT_RECORDING_PROTOCOL.md` — continuous context evidence and event recording contract
- `bootstrap/write-checkpoint.sh` / `bootstrap/resume-from-checkpoint.sh` — write and read checkpoints under `_system/checkpoints/`

## Rules

- Regenerate the registry whenever AIAST-managed files are added, removed, or renamed.
- Core docs must not reference paths that do not exist locally.
- Core docs must mention critical self-awareness and recovery commands so agents can find them under pressure.
- New installable contracts must be wired into discovery surfaces before they are
  treated as part of the operating system.
- Golden-example discovery docs must stay aligned with the actual installed example files.
- Registry drift is a system problem, not a cosmetic issue.

## Commands

- `bootstrap/generate-system-registry.sh <repo> --write`
- `bootstrap/check-system-awareness.sh <repo>`
- `bootstrap/system-doctor.sh <repo>`
- `bootstrap/check-master-map-completeness.sh <repo>`
- `bootstrap/check-agent-locks.sh <repo>`
- `bootstrap/check-context-freshness.sh <repo>`
- `bootstrap/resume-from-checkpoint.sh <repo>` — on cold start, read any existing mid-session checkpoint before loading tiers
- `bootstrap/write-checkpoint.sh <repo> --kind <kind> --agent <id> --phase <text> --next <step>` — persist mid-session state so another agent can resume after rate limits, crashes, or handoff
