#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: init-app-namespace.sh <repo-root> --slug <slug> [options]

Generate _system/app-local-namespace.json for a downstream AIAST app repo.

Required:
  <repo-root>                Absolute or relative path to the downstream repo root.
  --slug <slug>              Lower-kebab handle (^[a-z0-9][a-z0-9-]{0,62}$).

Optional:
  --name <human-name>        Display name. Defaults to slug.
  --parent-template-path P   Absolute path of the AIAST parent template; added
                             to forbidden_roots if provided.
  --scan-siblings            Resolve all sibling directories under the parent
                             of <repo-root> and add them to forbidden_roots.
  --refresh                  Regenerate derived fields; preserve identity.
                             Refuses if app-local-namespace.json absent.
  --reset                    Regenerate identity (new app_uuid, new app_id).
                             Destructive to lineage; appends a 'reset' lifecycle
                             event preserving prior identity. Requires --confirm-reset.
  --confirm-reset            Required companion to --reset.
  --json                     Emit machine-readable envelope on stdout.
  -h, --help                 Show this help.

Behavior:
  * Refuses if _system/.aiast-role.json reports role == "parent-template".
  * Refuses if _system/app-local-namespace.json already exists, unless --refresh
    or --reset is passed.
  * Validates the freshly written record against
    _system/schemas/app-local-namespace.schema.json.
EOF
}

REPO_ROOT_ARG=""
SLUG=""
NAME=""
PARENT_TEMPLATE_PATH=""
SCAN_SIBLINGS=0
REFRESH=0
RESET=0
CONFIRM_RESET=0
JSON_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --slug)                 SLUG="${2:-}"; shift 2 ;;
    --name)                 NAME="${2:-}"; shift 2 ;;
    --parent-template-path) PARENT_TEMPLATE_PATH="${2:-}"; shift 2 ;;
    --scan-siblings)        SCAN_SIBLINGS=1; shift ;;
    --refresh)              REFRESH=1; shift ;;
    --reset)                RESET=1; shift ;;
    --confirm-reset)        CONFIRM_RESET=1; shift ;;
    --json)                 JSON_MODE=1; shift ;;
    --) shift; break ;;
    -*) echo "unknown flag: $1" >&2; usage; exit 2 ;;
    *)
      if [[ -z "${REPO_ROOT_ARG}" ]]; then
        REPO_ROOT_ARG="$1"
      else
        echo "unexpected positional arg: $1" >&2; usage; exit 2
      fi
      shift
      ;;
  esac
done

emit_error() {
  local code="$1"; local msg="$2"
  if [[ "${JSON_MODE}" -eq 1 ]]; then
    printf '{"ok":false,"script":"init-app-namespace.sh","code":"%s","message":"%s"}\n' "${code}" "${msg}"
  else
    printf 'init-app-namespace.sh: %s: %s\n' "${code}" "${msg}" >&2
  fi
  exit 1
}

[[ -z "${REPO_ROOT_ARG}" ]] && { usage >&2; exit 2; }

if [[ ! -d "${REPO_ROOT_ARG}" ]]; then
  emit_error "missing_repo_root" "repo root does not exist: ${REPO_ROOT_ARG}"
fi

REPO_ROOT="$(cd -- "${REPO_ROOT_ARG}" && pwd)"
REPO_ROOT_REALPATH="$(realpath -- "${REPO_ROOT}")"

ROLE_FILE="${REPO_ROOT}/_system/.aiast-role.json"
NAMESPACE_FILE="${REPO_ROOT}/_system/app-local-namespace.json"
TEMPLATE_FILE="${REPO_ROOT}/_system/app-local-namespace.template.json"
SCHEMA_FILE="${REPO_ROOT}/_system/schemas/app-local-namespace.schema.json"
VERSION_FILE="${REPO_ROOT}/AIAST_VERSION.md"
INSTALL_FILE="${REPO_ROOT}/_system/.template-install.json"

[[ -f "${TEMPLATE_FILE}" ]] || emit_error "missing_template" "expected ${TEMPLATE_FILE}"
[[ -f "${SCHEMA_FILE}"   ]] || emit_error "missing_schema"   "expected ${SCHEMA_FILE}"

# Role refusal.
if [[ -f "${ROLE_FILE}" ]]; then
  ROLE="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1])).get('role',''))" "${ROLE_FILE}" 2>/dev/null || true)"
  if [[ "${ROLE}" == "parent-template" ]]; then
    emit_error "wrong_role" "refusing to init app-local-namespace in a parent-template repo"
  fi
fi

# Pre-existing record handling.
if [[ -f "${NAMESPACE_FILE}" && "${REFRESH}" -eq 0 && "${RESET}" -eq 0 ]]; then
  emit_error "already_exists" "${NAMESPACE_FILE} exists; pass --refresh or --reset"
fi
if [[ "${RESET}" -eq 1 && "${CONFIRM_RESET}" -eq 0 ]]; then
  emit_error "reset_unconfirmed" "--reset requires --confirm-reset"
fi

# Slug required unless --refresh on existing.
if [[ -z "${SLUG}" ]]; then
  if [[ "${REFRESH}" -eq 1 && -f "${NAMESPACE_FILE}" ]]; then
    SLUG="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['app_slug'])" "${NAMESPACE_FILE}")"
  else
    emit_error "missing_slug" "--slug is required for create or reset"
  fi
fi
if ! [[ "${SLUG}" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]]; then
  emit_error "invalid_slug" "slug must match ^[a-z0-9][a-z0-9-]{0,62}$"
fi
[[ -z "${NAME}" ]] && NAME="${SLUG}"

# Mint or preserve identity.
mint_uuidv7() {
  python3 - <<'PY'
import os, time, uuid
# UUIDv7: 48-bit unix-ms timestamp + version/random
ms = int(time.time() * 1000) & ((1<<48)-1)
rand_a = int.from_bytes(os.urandom(2), 'big') & 0x0fff
rand_b = int.from_bytes(os.urandom(8), 'big') & ((1<<62)-1)
val = (ms << 80) | (0x7 << 76) | (rand_a << 64) | (0b10 << 62) | rand_b
print(str(uuid.UUID(int=val)))
PY
}

if [[ "${REFRESH}" -eq 1 && -f "${NAMESPACE_FILE}" && "${RESET}" -eq 0 ]]; then
  APP_UUID="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['app_uuid'])" "${NAMESPACE_FILE}")"
  CREATED_AT="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['created_at'])" "${NAMESPACE_FILE}")"
  PRIOR_EVENTS="$(python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1])).get('lifecycle',{}).get('events',[])))" "${NAMESPACE_FILE}")"
  ACTION="refreshed"
else
  APP_UUID="$(mint_uuidv7)"
  CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  PRIOR_EVENTS="[]"
  ACTION="created"
  if [[ "${RESET}" -eq 1 && -f "${NAMESPACE_FILE}" ]]; then
    PRIOR_EVENTS="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); evs=d.get('lifecycle',{}).get('events',[]); evs.append({'ts':'$(date -u +%Y-%m-%dT%H:%M:%SZ)','kind':'reset','details':{'prior_app_id':d['app_id'],'prior_app_uuid':d['app_uuid']}}); print(json.dumps(evs))" "${NAMESPACE_FILE}")"
    ACTION="reset"
  fi
fi

APP_UUID_PREFIX="${APP_UUID:0:8}"
APP_ID="${SLUG}-${APP_UUID_PREFIX}"
APP_ID_DB="$(printf '%s_' "${APP_ID}" | tr '-' '_')"

AIAST_TEMPLATE_VERSION="unknown"
if [[ -f "${VERSION_FILE}" ]]; then
  AIAST_TEMPLATE_VERSION="$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+' "${VERSION_FILE}" | head -n1 || echo unknown)"
fi
AIAST_INSTALL_ID="unknown"
if [[ -f "${INSTALL_FILE}" ]]; then
  AIAST_INSTALL_ID="$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('install_id', d.get('aiast_install_id','unknown')))" "${INSTALL_FILE}" 2>/dev/null || echo unknown)"
fi

CREATED_BY="${USER:-unknown}@$(hostname -s 2>/dev/null || echo unknown)"

# Resolve forbidden_roots.
FORBIDDEN_JSON="[]"
if [[ -n "${PARENT_TEMPLATE_PATH}" || "${SCAN_SIBLINGS}" -eq 1 ]]; then
  FORBIDDEN_JSON="$(
    python3 - "${REPO_ROOT_REALPATH}" "${PARENT_TEMPLATE_PATH}" "${SCAN_SIBLINGS}" <<'PY'
import json, os, sys
repo_real, parent_tpl, scan = sys.argv[1], sys.argv[2], sys.argv[3] == "1"
out = []
if parent_tpl:
    try: out.append(os.path.realpath(parent_tpl))
    except Exception: pass
if scan:
    parent_dir = os.path.dirname(repo_real)
    if parent_dir and os.path.isdir(parent_dir):
        for name in sorted(os.listdir(parent_dir)):
            cand = os.path.realpath(os.path.join(parent_dir, name))
            if cand != repo_real and os.path.isdir(cand):
                out.append(cand)
seen, dedup = set(), []
for p in out:
    if p and p not in seen and p != repo_real:
        seen.add(p); dedup.append(p)
print(json.dumps(dedup))
PY
  )"
fi

# Render.
RENDERED="$(
  python3 - <<PY
import json
tpl = json.load(open("${TEMPLATE_FILE}"))
subs = {
    "__APP_SLUG__": "${SLUG}",
    "__APP_UUID__": "${APP_UUID}",
    "__APP_UUID_PREFIX__": "${APP_UUID_PREFIX}",
    "__APP_NAME__": "${NAME}",
    "__REPO_ROOT__": "${REPO_ROOT}",
    "__REPO_ROOT_REALPATH__": "${REPO_ROOT_REALPATH}",
    "__AIAST_INSTALL_ID__": "${AIAST_INSTALL_ID}",
    "__AIAST_TEMPLATE_VERSION__": "${AIAST_TEMPLATE_VERSION}",
    "__CREATED_AT__": "${CREATED_AT}",
    "__CREATED_BY__": "${CREATED_BY}",
    "__APP_ID__": "${APP_ID}",
    "__APP_ID_DB__": "${APP_ID_DB}",
}
def walk(v):
    if isinstance(v, str):
        for k, r in subs.items(): v = v.replace(k, r)
        return v
    if isinstance(v, list): return [walk(x) for x in v]
    if isinstance(v, dict): return {k: walk(x) for k, x in v.items()}
    return v
out = walk(tpl)
out["forbidden_roots"] = json.loads('${FORBIDDEN_JSON}')
prior = json.loads('${PRIOR_EVENTS}')
new_event = {"ts": "${CREATED_AT}", "kind": ("${ACTION}" if "${ACTION}" in ("created","reset") else "renamed"),
             "details": {"by": "init-app-namespace.sh", "template_version": "${AIAST_TEMPLATE_VERSION}"}}
if "${ACTION}" == "refreshed":
    new_event["kind"] = "renamed"
events = prior if prior else []
events.append(new_event)
out["lifecycle"]["events"] = events
print(json.dumps(out, indent=2))
PY
)"

# Persist atomically first, then validate the file on disk (avoids stdin/heredoc shadowing).
TMP="${NAMESPACE_FILE}.tmp.$$"
printf '%s\n' "${RENDERED}" > "${TMP}"

if ! python3 - "${SCHEMA_FILE}" "${TMP}" <<'PY'
import json, sys
schema_path, doc_path = sys.argv[1], sys.argv[2]
try:
    schema = json.load(open(schema_path))
    doc = json.load(open(doc_path))
except Exception as e:
    sys.stderr.write(f"[init-app-namespace] could not load schema/doc: {e}\n")
    sys.exit(1)
try:
    import jsonschema  # type: ignore
except ImportError:
    sys.stderr.write("[init-app-namespace] jsonschema not installed; skipping strict validation (advisory)\n")
    sys.exit(0)
try:
    jsonschema.validate(doc, schema)
except jsonschema.ValidationError as e:
    sys.stderr.write(f"[init-app-namespace] schema validation failed: {e.message}\n")
    sys.exit(1)
PY
then
  rm -f -- "${TMP}"
  emit_error "schema_invalid" "rendered namespace failed schema validation"
fi

mv -- "${TMP}" "${NAMESPACE_FILE}"

if [[ "${JSON_MODE}" -eq 1 ]]; then
  printf '{"ok":true,"script":"init-app-namespace.sh","action":"%s","app_id":"%s","path":"%s"}\n' "${ACTION}" "${APP_ID}" "${NAMESPACE_FILE}"
else
  printf 'init-app-namespace.sh: %s %s at %s\n' "${ACTION}" "${APP_ID}" "${NAMESPACE_FILE}"
fi
