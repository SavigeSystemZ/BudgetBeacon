#!/usr/bin/env bash
# apply-local-self-improvement.sh
#
# Downstream project-local self-improvement -- step 3 (Apply).
# Records the working-tree changes that realize a proposal: captures the base
# commit and a reverse patch, audits that every changed path is inside the repo
# root, moves the proposal to applied/, and appends a ledger entry.
#
# It records changes ONLY inside the active repo and refuses to run in
# parent-template mode -- it must never write the parent template or anything
# outside the repo. See _system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md and
# _system/PROJECT_LOCAL_SELF_IMPROVEMENT_PROTOCOL.md.
#
# Usage: apply-local-self-improvement.sh [target-repo] <proposal-id>
#                                        [--local-only] [--note "..."]
set -euo pipefail

TARGET="."
NOTE=""
JSON=0
POSITIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --local-only) shift ;;          # affirmation flag; apply is always local-only
    --note) NOTE="${2:-}"; shift 2 ;;
    --json) JSON=1; shift ;;
    -h|--help)
      echo "Usage: apply-local-self-improvement.sh [target-repo] <proposal-id> [--local-only] [--note \"...\"]"
      exit 0 ;;
    *) POSITIONAL+=("$1"); shift ;;
  esac
done

PROPOSAL_ID=""
if [[ ${#POSITIONAL[@]} -eq 1 ]]; then
  PROPOSAL_ID="${POSITIONAL[0]}"
elif [[ ${#POSITIONAL[@]} -eq 2 ]]; then
  TARGET="${POSITIONAL[0]}"
  PROPOSAL_ID="${POSITIONAL[1]}"
elif [[ ${#POSITIONAL[@]} -gt 2 ]]; then
  echo "Error: too many arguments." >&2
  exit 2
fi

[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"
[[ -n "${PROPOSAL_ID}" ]] || { echo "Error: <proposal-id> is required." >&2; exit 2; }

# Role gate -- downstream-app only; never write the parent template.
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
  echo "Refusing: apply-local-self-improvement is a downstream-app tool and must" >&2
  echo "not write the parent template. The parent template evolves via the" >&2
  echo "maintainer loop -- see _system/SELF_IMPROVEMENT_PROTOCOL.md." >&2
  exit 3
fi

# git is the rollback backing.
if ! git -C "${TARGET}" rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "Error: ${TARGET} is not a git repository -- git is the rollback backing." >&2
  exit 2
fi
repo_top="$(cd -- "$(git -C "${TARGET}" rev-parse --show-toplevel)" && pwd)"

# Locate the proposal (exact id or unique substring).
proposals_dir="${TARGET}/_system/self-improvement/proposals"
proposal_file="${proposals_dir}/${PROPOSAL_ID}-proposal.md"
if [[ ! -f "${proposal_file}" ]]; then
  matches=()
  if [[ -d "${proposals_dir}" ]]; then
    while IFS= read -r f; do
      [[ -n "${f}" ]] && matches+=("${f}")
    done < <(find "${proposals_dir}" -maxdepth 1 -type f -name "*${PROPOSAL_ID}*-proposal.md" | sort)
  fi
  if [[ ${#matches[@]} -eq 1 ]]; then
    proposal_file="${matches[0]}"
  elif [[ ${#matches[@]} -eq 0 ]]; then
    echo "Error: no proposal matching '${PROPOSAL_ID}' in _system/self-improvement/proposals/" >&2
    exit 2
  else
    echo "Error: '${PROPOSAL_ID}' matches multiple proposals; be more specific:" >&2
    printf '  %s\n' "${matches[@]}" >&2
    exit 2
  fi
fi
proposal_id="$(basename "${proposal_file}")"
proposal_id="${proposal_id%-proposal.md}"

# Base commit -- the rollback anchor.
base_sha="$(git -C "${repo_top}" rev-parse HEAD 2>/dev/null || echo "")"
[[ -n "${base_sha}" ]] || base_sha="UNCOMMITTED"

# Working-tree changes that realize this proposal.
changed=()
while IFS= read -r line; do
  [[ -n "${line}" ]] || continue
  p="${line:3}"
  p="${p##* -> }"
  p="${p#\"}"
  p="${p%\"}"
  changed+=("${p}")
done < <(git -C "${repo_top}" status --porcelain)

if [[ ${#changed[@]} -eq 0 ]]; then
  echo "Error: no working-tree changes detected in ${repo_top}." >&2
  echo "Make the in-repo changes the proposal describes, then re-run apply." >&2
  exit 2
fi

# Boundary audit -- a self-improvement records changes only inside the repo,
# never outside the repo and never a secret/.env path.
for p in "${changed[@]}"; do
  if [[ "${p}" == /* || "${p}" == *".."* ]]; then
    echo "Refusing: change path is not safely inside the repo root: ${p}" >&2
    echo "apply-local-self-improvement records changes only inside the repo." >&2
    echo "See _system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md (write-scope rule)." >&2
    exit 3
  fi
  case "${p}" in
    .env|*/.env|*.env|*/.env.*|*secrets/*|*secret/*)
      echo "Refusing: change touches a secret/.env path: ${p}" >&2
      echo "See _system/SELF_WRITING_BOUNDARY_AND_ROLLBACK.md (forbidden writes)." >&2
      exit 3 ;;
  esac
done

# Reverse patch -- captured BEFORE writing any self-improvement artifact so it
# reflects only the proposal's changes.
si_dir="${TARGET}/_system/self-improvement"
mkdir -p "${si_dir}/applied" "${si_dir}/rejected"
revpatch="${si_dir}/applied/${proposal_id}.revpatch"
if [[ "${base_sha}" != "UNCOMMITTED" ]]; then
  git -C "${repo_top}" diff -R "${base_sha}" > "${revpatch}" 2>/dev/null || : > "${revpatch}"
else
  : > "${revpatch}"
fi

applied_md="${si_dir}/applied/${proposal_id}-applied.md"
applied_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  cat "${proposal_file}"
  printf '\n---\n\n## Applied\n\n'
  printf -- '- Applied at: %s\n' "${applied_at}"
  printf -- '- Base commit: %s\n' "${base_sha}"
  printf -- '- Reverse patch: _system/self-improvement/applied/%s.revpatch\n' "${proposal_id}"
  [[ -n "${NOTE}" ]] && printf -- '- Note: %s\n' "${NOTE}"
  printf -- '- Changed files (%s):\n' "${#changed[@]}"
  printf '  - %s\n' "${changed[@]}"
  printf '\n### Rollback\n\n'
  printf 'Restore tracked files with: git checkout %s -- <paths>\n' "${base_sha}"
  printf 'or apply the reverse patch: git apply %s.revpatch\n' "${proposal_id}"
  printf 'New (untracked) files roll back by deletion. After rollback, move this\n'
  printf 'record to _system/self-improvement/rejected/ with the reason.\n'
} > "${applied_md}"
rm -f "${proposal_file}"

ledger="${si_dir}/ledger.jsonl"
python3 - "${ledger}" "${proposal_id}" "${base_sha}" "${NOTE}" "${changed[@]}" <<'PY'
import json, sys
from datetime import datetime, timezone
ledger, pid, base, note = sys.argv[1:5]
changed = sys.argv[5:]
rec = {
    "ts": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "id": pid,
    "status": "applied",
    "base_sha": base,
    "changed_files": changed,
}
if note:
    rec["note"] = note
with open(ledger, "a", encoding="utf-8") as fh:
    fh.write(json.dumps(rec) + "\n")
PY

if [[ ${JSON} -eq 1 ]]; then
  python3 - "${proposal_id}" "${base_sha}" "${#changed[@]}" <<'PY'
import json, sys
print(json.dumps({"ok": True, "proposal_id": sys.argv[1], "base_sha": sys.argv[2],
                  "changed_files": int(sys.argv[3]), "status": "applied"}))
PY
else
  echo "self_improvement_applied id=${proposal_id} base=${base_sha} changed=${#changed[@]}"
  echo "Applied record: _system/self-improvement/applied/${proposal_id}-applied.md"
  echo "Next: validate (validate-system.sh . --strict and scope validators), then commit."
fi
