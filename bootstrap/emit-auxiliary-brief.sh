#!/usr/bin/env bash
# Emit a markdown auxiliary brief for parallel host CLI / IDE workers.
# Contract: _system/SUB_AGENT_HOST_DELEGATION.md
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: emit-auxiliary-brief.sh [--primary NAME] [--allowed PATHS] [--forbidden ITEMS]
       [--branch REF] [--spec TEXT] [--deliverables TEXT] [--stop TEXT]

Prints a frozen handoff block to stdout. Defaults are placeholders you should replace.

Environment (optional): AUX_PRIMARY AUX_ALLOWED AUX_FORBIDDEN AUX_BRANCH AUX_SPEC
  AUX_DELIVERABLES AUX_STOP
EOF
}

PRIMARY="${AUX_PRIMARY:-<tool name>}"
ALLOWED="${AUX_ALLOWED:-<e.g. src/api/ only>}"
FORBIDDEN="${AUX_FORBIDDEN:-<e.g. PLAN.md, WHERE_LEFT_OFF.md, lockfiles>}"
BRANCH="${AUX_BRANCH:-<sha or branch>}"
SPEC="${AUX_SPEC:-<link or paragraph>}"
DELIVER="${AUX_DELIVERABLES:-<e.g. patch + file list>}"
STOP="${AUX_STOP:-<acceptance criteria>}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --primary)
      PRIMARY="${2:-}"; shift 2 ;;
    --allowed)
      ALLOWED="${2:-}"; shift 2 ;;
    --forbidden)
      FORBIDDEN="${2:-}"; shift 2 ;;
    --branch)
      BRANCH="${2:-}"; shift 2 ;;
    --spec)
      SPEC="${2:-}"; shift 2 ;;
    --deliverables)
      DELIVER="${2:-}"; shift 2 ;;
    --stop)
      STOP="${2:-}"; shift 2 ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cat <<EOF
## Role
You are an auxiliary worker. Primary session: ${PRIMARY}. Read-only unless stated.

## Allowed writes
- Paths: ${ALLOWED} OR read-only review.

## Forbidden
- Do not edit: ${FORBIDDEN}
- Do not run destructive or secret-exporting commands; no production deploys without explicit approval.

## Swarm Fleet Rules
- **Active Branch:** ${BRANCH} (Must follow ai/<agent_name>/<feature> pattern)
- **Commit Protocol:** Use \`TEMPLATE/bootstrap/git-swarm-manager.sh auto-push\` ONLY.
- **SSoT Alignment:** All system rules MUST be written to \`TEMPLATE/_system/\`.

## Inputs
- Branch / commit: ${BRANCH}
- Spec / ticket: ${SPEC}

## Resilience & Recovery
- **Heartbeat:** Report MCP connectivity status in your first turn.
- **Contingency:** If you detect a hard-fail or auth issue, refer to \`_system/AUTH_RECOVERY_PROTOCOL.md\` and inform the primary.
- **Reclamation:** If no heartbeat is detected for 2 turns, the primary WILL reclaim this task.

## Deliverables
- ${DELIVER}
- Stop when: ${STOP}

## Hand back
- Post summary to primary; primary merges and validates per _system/HANDOFF_PROTOCOL.md.
EOF
