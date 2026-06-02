#!/usr/bin/env bash
# generate-app-context-pack.sh
#
# Materializes the app-context pack for a downstream repo: copies the selected
# archetype's neutral context templates from
# _system/app-context/templates/archetype/<id>/ into
# _system/app-context/archetype/. The 8 universal app-context files already
# ship in _system/app-context/.
#
# Idempotent: never overwrites an existing (possibly filled) file unless
# --force. Refuses parent-template mode (template neutrality).
# See _system/APP_CONTEXT_FILE_MATRIX.md and
# _system/APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md.
#
# Usage: generate-app-context-pack.sh [target-repo] [--archetype <id>]
#                                     [--force] [--json]
set -euo pipefail

TARGET="."
ARCHETYPE=""
FORCE=0
JSON=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --archetype) ARCHETYPE="${2:-}"; shift 2 ;;
    --force) FORCE=1; shift ;;
    --json) JSON=1; shift ;;
    -h|--help)
      echo "Usage: generate-app-context-pack.sh [target-repo] [--archetype <id>] [--force] [--json]"
      exit 0 ;;
    *) TARGET="$1"; shift ;;
  esac
done
[[ -d "${TARGET}" ]] || { echo "no such target: ${TARGET}" >&2; exit 2; }
TARGET="$(cd -- "${TARGET}" && pwd)"

# Role gate -- downstream-app tool.
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
  echo "Refusing: generate-app-context-pack is a downstream-app tool." >&2
  echo "The parent template ships app-context as placeholders plus a neutral" >&2
  echo "template library; it does not materialize a filled pack (template neutrality)." >&2
  exit 3
fi

ac="${TARGET}/_system/app-context"
tpl_root="${ac}/templates/archetype"
if [[ ! -d "${tpl_root}" ]]; then
  echo "Error: ${tpl_root} missing -- re-scaffold the AIAST operating layer." >&2
  exit 2
fi

# Resolve the archetype: --archetype, else an 'archetype: <id>' line in
# APP_IDENTITY.md or PROJECT_PROFILE.md.
if [[ -z "${ARCHETYPE}" ]]; then
  for src in "${ac}/APP_IDENTITY.md" "${TARGET}/_system/PROJECT_PROFILE.md"; do
    [[ -f "${src}" ]] || continue
    cand="$(grep -ioE 'archetype[: ]+[a-z0-9][a-z0-9-]*' "${src}" 2>/dev/null \
      | head -n1 | grep -oE '[a-z0-9][a-z0-9-]*$' || true)"
    if [[ -n "${cand}" && -d "${tpl_root}/${cand}" ]]; then
      ARCHETYPE="${cand}"
      break
    fi
  done
fi
if [[ -z "${ARCHETYPE}" ]]; then
  echo "Error: could not determine the archetype. Pass --archetype <id>." >&2
  echo "Valid ids:" >&2
  find "${tpl_root}" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort >&2
  exit 2
fi
if [[ ! -d "${tpl_root}/${ARCHETYPE}" ]]; then
  echo "Error: unknown archetype '${ARCHETYPE}'. Valid ids:" >&2
  find "${tpl_root}" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' | sort >&2
  exit 2
fi

dest="${ac}/archetype"
mkdir -p "${dest}"
created=0
skipped=0
while IFS= read -r f; do
  [[ -n "${f}" ]] || continue
  base="$(basename "${f}")"
  if [[ -e "${dest}/${base}" && ${FORCE} -eq 0 ]]; then
    skipped=$((skipped + 1))
    continue
  fi
  cp -p "${f}" "${dest}/${base}"
  created=$((created + 1))
done < <(find "${tpl_root}/${ARCHETYPE}" -maxdepth 1 -type f -name '*.md' | sort)

if [[ ${JSON} -eq 1 ]]; then
  python3 - "${ARCHETYPE}" "${created}" "${skipped}" <<'PY'
import json, sys
print(json.dumps({"ok": True, "archetype": sys.argv[1],
                  "materialized": int(sys.argv[2]),
                  "skipped_existing": int(sys.argv[3])}))
PY
else
  echo "app_context_pack_generated archetype=${ARCHETYPE} materialized=${created} skipped=${skipped}"
  echo "Universal files (already shipped): _system/app-context/*.md"
  echo "Archetype files: _system/app-context/archetype/"
  echo "Next: fill each file (see APP_SPECIFIC_CONTEXT_AUTHORING_STANDARD.md), then run:"
  echo "  bash bootstrap/validate-app-context-files.sh ."
fi
