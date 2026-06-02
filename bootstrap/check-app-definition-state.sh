#!/usr/bin/env bash
# check-app-definition-state.sh
#
# Identity/onboarding gate for repos scaffolded from this template.
#
# Resolves _system/.aiast-role.json:
#   - parent-template            -> meta-system template itself; no gate.
#   - downstream-app (or absent) -> this is a BLANK APP-BUILDING repo.
#       Determines whether the app is DEFINED yet (PRODUCT_BRIEF.md filled
#       and app/src/ has real source) and prints a clear directive so an
#       agent does not mistake a blank app repo for the meta-system.
#
# Exit: 0 always by default (advisory). With --strict, exits 3 when the
# app is undefined so a caller can hard-gate if it wants.
#
# Usage: check-app-definition-state.sh [target-repo] [--json] [--strict]
set -euo pipefail

TARGET="."
JSON=0
STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help) echo "Usage: check-app-definition-state.sh [target-repo] [--json] [--strict]"; exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

role="downstream-app"
role_file="${TARGET}/_system/.aiast-role.json"
role_missing=1
if [[ -f "${role_file}" ]]; then
  role_missing=0
  r="$(python3 - "${role_file}" <<'PY' 2>/dev/null || true
import json,sys
try:
    print((json.load(open(sys.argv[1])).get("role") or "").strip())
except Exception:
    print("")
PY
)"
  [[ -n "${r}" ]] && role="${r}"
fi

emit() {  # state directive
  local state="$1" directive="$2"
  if [[ ${JSON} -eq 1 ]]; then
    python3 - "$role" "$state" "$role_missing" "$directive" <<'PY'
import json,sys
print(json.dumps({
  "ok": True, "role": sys.argv[1], "app_state": sys.argv[2],
  "role_file_missing": sys.argv[3] == "1", "directive": sys.argv[4],
}))
PY
  else
    printf 'app_definition_state role=%s state=%s\n' "${role}" "${state}"
    printf '%s\n' "${directive}"
  fi
}

if [[ "${role}" == "parent-template" ]]; then
  emit "meta_template" "This IS the AIAST meta-system template (parent-template). Not an app repo; no app-definition gate. Follow AGENTS.md + GIT_SIDE_MIRROR_POLICY.md."
  exit 0
fi

# downstream-app (or role file missing -> treated as downstream-app).
#
# "Defined" is judged by real source in the repo's declared runtime roots.
# PRODUCT_BRIEF.md is unreliable for this: init-project pre-fills every field
# with guidance prose ("define the app promise in one clear sentence...",
# etc.), so a blank scaffold has a fully "non-empty" brief. Concrete app
# source is the one unambiguous signal. Erring toward "undefined" until code
# exists is the safe, intended behavior for an identity gate.
#
# Source roots: the isolated-layout default is app/src/, but hybrid-layout
# repos keep app code at top-level roots declared in PROJECT_PROFILE.md
# ("- Runtime code roots: src/, public/"). Check the declared roots too so a
# defined hybrid app is not falsely reported blank. See
# _system/HYBRID_APP_REPO_LAYOUT_CONTRACT.md.
declare -a source_roots=()
profile="${TARGET}/_system/PROJECT_PROFILE.md"
if [[ -f "${profile}" ]]; then
  roots_line="$(grep -m1 -E '^- Runtime code roots:' "${profile}" \
    | sed -E 's/^- Runtime code roots:[[:space:]]*//')"
  if [[ -n "${roots_line}" ]]; then
    IFS=',' read -ra _raw_roots <<< "${roots_line}"
    for _r in "${_raw_roots[@]}"; do
      _r="$(printf '%s' "${_r}" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s#/+$##')"
      [[ -n "${_r}" && "${_r}" != "."* && "${_r}" != /* ]] && source_roots+=("${_r}")
    done
  fi
fi
# Always also consider the isolated-layout default.
source_roots+=("app/src")

app_has_source=0
for _rel in "${source_roots[@]}"; do
  _dir="${TARGET}/${_rel}"
  [[ -d "${_dir}" ]] || continue
  # Real source = any file that is not README.md / .gitkeep / .gitignore.
  if find "${_dir}" -type f ! -name 'README.md' ! -name '.gitkeep' \
       ! -name '.gitignore' -print -quit 2>/dev/null | grep -q .; then
    app_has_source=1
    break
  fi
done

if [[ "${app_has_source}" == "1" ]]; then
  if [[ -f "${TARGET}/_system/personas/APP_PERSONA.md" ]]; then
    emit "app_defined" "App under construction; app-specific world-class persona is attached (_system/personas/APP_PERSONA.md). Keep building into app/ via the _system/ meta-system; re-run the forge-app-persona command if the domain/stack/quality-bar changes."
  else
    emit "app_defined_no_persona" "App under construction but NO app-specific persona yet. Run the cross-agent command 'forge-app-persona' (.cursor/commands/forge-app-persona.md, per _system/APP_PERSONA_CONTRACT.md) to evaluate this app and bolt a tailored world-class persona onto the meta-system at _system/personas/APP_PERSONA.md. Keep app code independent of _system/ and bootstrap/."
  fi
  exit 0
fi

# Blank app repo, app undefined — the gate fires.
directive=$'BLANK APP REPO — the application is NOT defined yet.\nThis repo is a blank app-building repo carrying a local meta-system; it is\nNOT the meta-system template. Do this first, in order:\n  1. Interview the operator: what is the app, who is it for, what is\n     success? Capture it in PRODUCT_BRIEF.md.\n  2. Then build the app INTO app/ using the _system/ meta-system\n     (planning, VALIDATION_GATES.md, DELIVERY_GATES.md, golden examples).\n  3. Do not develop or re-scaffold the meta-system itself.\nSee _system/APP_REPO_IDENTITY.md and app/README.md.'
emit "blank_app_undefined" "${directive}"
if [[ ${role_missing} -eq 1 && ${JSON} -eq 0 ]]; then
  echo "note: _system/.aiast-role.json missing — assumed downstream-app; restore via bootstrap/init-project.sh --role downstream-app"
fi
[[ ${STRICT} -eq 1 ]] && exit 3
exit 0
