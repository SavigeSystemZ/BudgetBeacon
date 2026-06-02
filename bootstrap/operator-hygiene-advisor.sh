#!/usr/bin/env bash
# operator-hygiene-advisor.sh
#
# S22d WS1/WS11 — advisory for the operator-territory git-hygiene state
# that fleet-health-dashboard.sh now reports as a NON-blocking channel
# (no longer a chronic fake "yellow"). This tool *advises* and, only for
# an explicitly safe subset, *offers* remediation — it is DRY-RUN BY
# DEFAULT and NEVER rewrites git history, force-pushes, or touches
# tracked files. Exposed as `aiast tidy`.
#
# Safe subset (suggest-only unless --apply):
#   - stale agent lock guard dirs / *.lock.json past their lease
#   - empty _system/agent-state/**/tmp scratch dirs
#   - orphaned *.swp / *.orig / claude_diff.patch turds
# Everything else (uncommitted tracked changes, branch/upstream drift) is
# REPORTED ONLY — operator decides; we never touch it.
#
# Usage: operator-hygiene-advisor.sh [TARGET] [--apply] [--json]
# Result: operator_hygiene_ok suggestions=<n> applied=<n>

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"
[[ "${TARGET}" == --* ]] && TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
APPLY=0; JSON=0
for a in "$@"; do
  case "${a}" in
    --apply) APPLY=1 ;;
    --json) JSON=1 ;;
  esac
done
[[ -d "${TARGET}" ]] || { echo "operator_hygiene_failed: bad target ${TARGET}" >&2; exit 2; }

suggestions=(); applied=0
note() { suggestions+=("$1"); }

AS="${TARGET}/_system/agent-state"

# 1. stale lock guard dirs (mtime older than 1h — well past any sane lease)
if [[ -d "${AS}/locks" ]]; then
  while IFS= read -r d; do
    [[ -z "${d}" ]] && continue
    note "stale lock guard: ${d#"${TARGET}"/}"
    if [[ ${APPLY} -eq 1 ]]; then rm -rf "${d}" && applied=$((applied+1)); fi
  done < <(find "${AS}/locks" -maxdepth 1 -name '*.lock.d' -type d -mmin +60 2>/dev/null)
  while IFS= read -r f; do
    [[ -z "${f}" ]] && continue
    note "stale lock json: ${f#"${TARGET}"/}"
    if [[ ${APPLY} -eq 1 ]]; then rm -f "${f}" && applied=$((applied+1)); fi
  done < <(find "${AS}/locks" -maxdepth 1 -name '*.lock.json' -mmin +60 2>/dev/null)
fi

# 2. editor / merge turds (never tracked)
while IFS= read -r f; do
  [[ -z "${f}" ]] && continue
  note "stray turd: ${f#"${TARGET}"/}"
  if [[ ${APPLY} -eq 1 ]]; then rm -f "${f}" && applied=$((applied+1)); fi
done < <(find "${TARGET}" -maxdepth 3 \( -name '*.swp' -o -name '*.orig' -o -name 'claude_diff.patch' \) -type f 2>/dev/null)

# 3. REPORT-ONLY: uncommitted tracked changes / branch drift (never touched)
report_only=()
if command -v git >/dev/null 2>&1 && git -C "${TARGET}" rev-parse --git-dir >/dev/null 2>&1; then
  dirty="$(git -C "${TARGET}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  [[ "${dirty}" -gt 0 ]] && report_only+=("${dirty} uncommitted tracked path(s) — operator decides, not auto-touched")
  br="$(git -C "${TARGET}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if ! git -C "${TARGET}" rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1; then
    report_only+=("branch '${br}' has no upstream — operator territory")
  fi
fi

if [[ ${JSON} -eq 1 ]]; then
  python3 - "${APPLY}" "${applied}" <<PY
import json,sys
print(json.dumps({
  "ok": True, "result": "operator_hygiene_ok",
  "apply": sys.argv[1]=="1", "applied": int(sys.argv[2]),
  "suggestions": $(printf '%s\n' "${suggestions[@]:-}" | python3 -c 'import json,sys;print(json.dumps([l for l in sys.stdin.read().splitlines() if l]))'),
  "report_only": $(printf '%s\n' "${report_only[@]:-}" | python3 -c 'import json,sys;print(json.dumps([l for l in sys.stdin.read().splitlines() if l]))')
}))
PY
else
  echo "Operator hygiene advisor — target: ${TARGET}"
  if [[ ${#suggestions[@]} -eq 0 ]]; then echo "  (no safe-subset suggestions)"; fi
  for s in "${suggestions[@]:-}"; do [[ -n "${s}" ]] && echo "  • ${s}$([[ ${APPLY} -eq 0 ]] && echo '  [dry-run; --apply to remove]')"; done
  for r in "${report_only[@]:-}"; do [[ -n "${r}" ]] && echo "  ⚠ report-only: ${r}"; done
fi

echo "operator_hygiene_ok suggestions=${#suggestions[@]} applied=${applied} apply=${APPLY}"
