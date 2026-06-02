#!/usr/bin/env bash
# propose-local-self-improvement.sh
#
# Downstream project-local self-improvement -- step 2 (Propose).
# Writes a reviewable proposal under _system/self-improvement/proposals/.
# See _system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md and
# _system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md.
#
# Refuses in parent-template mode: the parent template evolves via the
# maintainer loop (_system/SELF_IMPROVEMENT_PROTOCOL.md), not this one.
#
# Usage: propose-local-self-improvement.sh [target-repo] \
#          --title "..." --scope "..." --reason "..." \
#          [--class allowed|guarded] [--json]
set -euo pipefail

TARGET="."
TITLE=""
SCOPE=""
REASON=""
CLASS="allowed"
JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)  TITLE="${2:-}"; shift 2 ;;
    --scope)  SCOPE="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --class)  CLASS="${2:-}"; shift 2 ;;
    --json)   JSON=1; shift ;;
    -h|--help)
      echo "Usage: propose-local-self-improvement.sh [target-repo] --title \"...\" --scope \"...\" --reason \"...\" [--class allowed|guarded] [--json]"
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done

[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

if [[ -z "${TITLE}" || -z "${SCOPE}" || -z "${REASON}" ]]; then
  echo "Error: --title, --scope, and --reason are all required." >&2
  exit 2
fi

case "${CLASS}" in
  allowed|guarded) ;;
  *) echo "Error: --class must be 'allowed' or 'guarded' -- see SELF_WRITING_BOUNDARY_AND_ROLLBACK.md." >&2; exit 2 ;;
esac

# Role gate -- this is a downstream-app tool.
role="downstream-app"
role_file="${TARGET}/_system/.aiast-role.json"
if [[ -f "${role_file}" ]]; then
  r="$(python3 - "${role_file}" <<'PY' 2>/dev/null || true
import json, sys
try:
    print((json.load(open(sys.argv[1])).get("role") or "").strip())
except Exception:
    print("")
PY
)"
  [[ -n "${r}" ]] && role="${r}"
fi
if [[ "${role}" == "parent-template" ]]; then
  echo "Refusing: propose-local-self-improvement is a downstream-app tool." >&2
  echo "The parent template evolves via the maintainer loop -- see _system/SELF_IMPROVEMENT_PROTOCOL.md." >&2
  exit 3
fi

proposals_dir="${TARGET}/_system/self-improvement/proposals"
mkdir -p "${proposals_dir}"

ts="$(date -u +%Y%m%dT%H%M%SZ)"
proposal_id="${ts}"
proposal_file="${proposals_dir}/${proposal_id}-proposal.md"
n=1
while [[ -e "${proposal_file}" ]]; do
  proposal_id="${ts}-${n}"
  proposal_file="${proposals_dir}/${proposal_id}-proposal.md"
  n=$((n + 1))
done

created="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  printf '# Self-Improvement Proposal: %s\n\n' "${TITLE}"
  printf -- '- Proposal ID: %s\n' "${proposal_id}"
  printf -- '- Created: %s\n' "${created}"
  printf -- '- Scope: %s\n' "${SCOPE}"
  printf -- '- Improvement class: %s\n' "${CLASS}"
  printf -- '- Status: proposed\n\n'
  printf '## Reason\n\n%s\n\n' "${REASON}"
  printf '## Planned in-repo changes\n\n'
  printf 'List the exact files/surfaces inside THIS repo to change. Every path\n'
  printf 'must resolve inside the repo root (SELF_WRITING_BOUNDARY_AND_ROLLBACK.md).\n\n- \n\n'
  printf '## Rollback notes\n\n'
  printf 'apply-local-self-improvement.sh records the base commit and a reverse\n'
  printf 'patch. To roll back, restore the changed paths from the base commit or\n'
  printf 'apply the reverse patch, then move this record to rejected/.\n\n'
  printf '## Validation\n\n'
  printf 'Validators to re-run after apply (always validate-system.sh --strict;\n'
  printf 'add validate-app-context-files.sh if app-context changed):\n\n- \n'
} > "${proposal_file}"

rel="_system/self-improvement/proposals/${proposal_id}-proposal.md"
if [[ ${JSON} -eq 1 ]]; then
  python3 - "${proposal_id}" "${rel}" "${TITLE}" "${CLASS}" <<'PY'
import json, sys
print(json.dumps({"ok": True, "proposal_id": sys.argv[1], "path": sys.argv[2],
                  "title": sys.argv[3], "class": sys.argv[4], "status": "proposed"}))
PY
else
  echo "self_improvement_proposal_created id=${proposal_id}"
  echo "Proposal written: ${rel}"
  echo "Next: make the in-repo changes, then run:"
  echo "  bash bootstrap/apply-local-self-improvement.sh . ${proposal_id} --local-only"
fi
