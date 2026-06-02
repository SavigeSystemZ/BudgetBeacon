#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: init-project.sh <target-repo> [--app-name NAME] [--profile NAME]
                       [--strict] [--dry-run]
                       [--role downstream-app|parent-template]
                       [--install-root-shims] [--install-tool-global-redirects]
                       [--seed-orphan-meta-snapshot] [--myappz-root <path>]
                       [--template-root <path>] [--no-global-writes]

  --role  Write _system/.aiast-role.json with this role at end of init.
          Default: downstream-app. Use parent-template only when
          scaffolding a new AIAST template repository (rare).
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
APP_NAME=""
PROFILE=""
STRICT=0
DRY_RUN=0
README_DEST="README.md"
INSTALL_ROOT_SHIMS=0
INSTALL_TOOL_GLOBAL_REDIRECTS=0
SEED_ORPHAN_META_SNAPSHOT=0
NO_GLOBAL_WRITES=0
MYAPPZ_ROOT="${HOME}/.MyAppZ"
TEMPLATE_ROOT_OVERRIDE=""
INIT_ROLE="downstream-app"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --install-root-shims)
      INSTALL_ROOT_SHIMS=1
      shift
      ;;
    --install-tool-global-redirects)
      INSTALL_TOOL_GLOBAL_REDIRECTS=1
      shift
      ;;
    --seed-orphan-meta-snapshot)
      SEED_ORPHAN_META_SNAPSHOT=1
      shift
      ;;
    --myappz-root)
      MYAPPZ_ROOT="${2:-}"
      shift 2
      ;;
    --template-root)
      TEMPLATE_ROOT_OVERRIDE="${2:-}"
      shift 2
      ;;
    --no-global-writes)
      NO_GLOBAL_WRITES=1
      shift
      ;;
    --role)
      INIT_ROLE="${2:-}"
      case "${INIT_ROLE}" in
        downstream-app|parent-template) ;;
        *) echo "--role must be downstream-app or parent-template; got ${INIT_ROLE!r}" >&2; exit 2 ;;
      esac
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${TARGET_REPO}" ]]; then
        TARGET_REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${TARGET_REPO}" ]]; then
  usage
  exit 1
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(basename -- "${TARGET_REPO}")"
fi

if [[ -n "${TEMPLATE_ROOT_OVERRIDE}" ]]; then
  TEMPLATE_ROOT="$(cd -- "${TEMPLATE_ROOT_OVERRIDE}" && pwd)"
fi

PROFILE="$(aiaast_resolve_scaffold_profile "${TEMPLATE_ROOT}" "${PROFILE}")"

if [[ ${DRY_RUN} -eq 0 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

aiaast_assert_template_root "${TEMPLATE_ROOT}"

mkdir -p "${TARGET_REPO}"

# Refuse to silently widen restrictive perms on an existing target directory.
# rsync -a (used below to copy the template) overrides the destination dir
# mode from source, so a read-only target would be made writable without
# operator intent. Detect that before writes start.
if [[ ${DRY_RUN} -eq 0 ]] && [[ ! -w "${TARGET_REPO}" ]]; then
  echo "Target directory is not writable: ${TARGET_REPO}" >&2
  echo "Refusing to proceed (init-project would otherwise silently relax mode via rsync -a)." >&2
  echo "Adjust permissions (e.g. chmod u+w \"${TARGET_REPO}\") then re-run, or pick a different target." >&2
  exit 1
fi

if [[ -e "${TARGET_REPO}/README.md" ]]; then
  README_DEST="AI_SYSTEM_README.md"
fi

mapfile -t SOURCE_FILES < <(bash "${TEMPLATE_ROOT}/bootstrap/render-scaffold-profile.sh" "${TEMPLATE_ROOT}" --profile "${PROFILE}")
CONFLICTS=()

for rel in "${SOURCE_FILES[@]}"; do
  rel="${rel#./}"
  if [[ "${rel}" == "README.md" ]]; then
    dest="${TARGET_REPO}/${README_DEST}"
  else
    dest="${TARGET_REPO}/${rel}"
  fi
  if [[ -e "${dest}" ]]; then
    CONFLICTS+=("${dest}")
  fi
done

if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo "Refusing to overwrite existing files in ${TARGET_REPO}:" >&2
  printf '  %s\n' "${CONFLICTS[@]}" >&2
  cat >&2 <<'EOF'

This target repo already has template-managed files. init-project.sh is for
fresh installs only and never overwrites. Use one of these instead:

  bootstrap/install-missing-files.sh <repo>
      add only files that don't exist (preserve-first, safe on dirty trees)

  bootstrap/update-template.sh <repo> --source <TEMPLATE>
      additive update — adds new files, preserves drifted managed files

  bootstrap/update-template.sh <repo> --source <TEMPLATE> --refresh-managed --strict
      full canonical refresh — overwrites drifted managed files with
      template versions; commit local work first

EOF
  exit 1
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "Dry run: would copy operating system into ${TARGET_REPO}"
  echo "Dry run: scaffold profile ${PROFILE} selects ${#SOURCE_FILES[@]} files"
  echo "Dry run: would configure app name as ${APP_NAME}"
  echo "Dry run: would install AIAST version $(aiaast_template_version "${TEMPLATE_ROOT}")"
  if [[ "${README_DEST}" != "README.md" ]]; then
    echo "Dry run: would install template README as ${README_DEST}"
  fi
  echo "Dry run: would run alignment checks and emit session environment report"
  if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_ROOT_SHIMS} -eq 1 ]]; then
    echo "Dry run: would install root redirect shims under ${MYAPPZ_ROOT}"
  fi
  if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_TOOL_GLOBAL_REDIRECTS} -eq 1 ]]; then
    echo "Dry run: would install tool-global redirect notices"
  fi
  if [[ ${SEED_ORPHAN_META_SNAPSHOT} -eq 1 ]]; then
    echo "Dry run: would seed orphan snapshot lane metadata"
  fi
  exit 0
fi

for rel in "${SOURCE_FILES[@]}"; do
  if [[ "${rel}" == "README.md" ]]; then
    aiaast_copy_rel_file "${TEMPLATE_ROOT}" "README.md" "${TARGET_REPO}" "${README_DEST}"
    if [[ "${README_DEST}" != "README.md" ]]; then
      echo "Installed template README as ${README_DEST} to avoid clobbering the app README"
    fi
  else
    aiaast_copy_rel_file "${TEMPLATE_ROOT}" "${rel}" "${TARGET_REPO}" "${rel}"
  fi
done
aiaast_refresh_onboarding_baseline "${TARGET_REPO}/bootstrap" "${TARGET_REPO}" "${APP_NAME}"
aiaast_write_install_metadata \
  "${TARGET_REPO}" \
  "$(cd -- "${TEMPLATE_ROOT}" && pwd)" \
  "$(aiaast_template_version "${TEMPLATE_ROOT}")" \
  "copied-template" \
  "${README_DEST}" \
  "install" \
  "${PROFILE}"
bash "${TARGET_REPO}/bootstrap/generate-host-adapters.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-system-key.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-system-registry.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/generate-operating-profile.sh" "${TARGET_REPO}" --write
bash "${TARGET_REPO}/bootstrap/verify-integrity.sh" --generate --target "${TARGET_REPO}"
expected_repo_target="$(basename -- "${TARGET_REPO}")"
bash "${TARGET_REPO}/bootstrap/check-working-directory-alignment.sh" "${TARGET_REPO}" --expected-target "${expected_repo_target}"
bash "${TARGET_REPO}/bootstrap/check-project-target-consistency.sh" "${TARGET_REPO}" --expected-target "${expected_repo_target}" || {
  echo "Project target consistency failed; refusing to continue writes." >&2
  exit 1
}
bash "${TARGET_REPO}/bootstrap/emit-session-environment.sh" "${TARGET_REPO}"
if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_ROOT_SHIMS} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/install-root-redirect-shims.sh" --myappz-root "${MYAPPZ_ROOT}" --target-repo "${TARGET_REPO}"
fi
if [[ ${NO_GLOBAL_WRITES} -eq 0 && ${INSTALL_TOOL_GLOBAL_REDIRECTS} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/install-tool-global-redirects.sh" --target-repo "${TARGET_REPO}"
fi
if [[ ${SEED_ORPHAN_META_SNAPSHOT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/snapshot-meta-to-orphan-branch.sh" "${TARGET_REPO}" --dry-run
fi
if [[ ${STRICT} -eq 1 ]]; then
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}" --strict
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO} --strict"
else
  bash "${TARGET_REPO}/bootstrap/validate-system.sh" "${TARGET_REPO}"
  validation_command="bootstrap/validate-system.sh ${TARGET_REPO}"
fi

aiaast_emit_template_sync_notice "${TARGET_REPO}" "init-project" 0

aiaast_record_validation_success \
  "${TARGET_REPO}" \
  "${validation_command}" \
  "AIAST install integrity, required files, config syntax, and awareness validation"

# Role sentinel: flip _system/.aiast-role.json to the requested role.
# Downstream apps (the common case) need role=downstream-app so the
# isolation validators (S1–S7) operate in downstream mode rather than
# refusing as parent-template.
if [[ -d "${TARGET_REPO}/_system" ]]; then
  python3 - "${TARGET_REPO}/_system/.aiast-role.json" "${INIT_ROLE}" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
role_file = Path(sys.argv[1])
role = sys.argv[2]
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
d = {}
if role_file.is_file():
    try: d = json.loads(role_file.read_text())
    except Exception: d = {}
prev = d.get("role")
d["role"] = role
d["set_at"] = now
d["set_by"] = "init-project.sh"
if prev and prev != role:
    d.setdefault("history", []).append({"ts": now, "from": prev, "to": role})
role_file.write_text(json.dumps(d, indent=2) + "\n")
PY
fi

# Scaffold isolation completion gate (advisory; downstream-app only).
# Runs every isolation validator in best-effort mode and surfaces a
# one-line summary. Failures are reported but do not abort init —
# operators address them and re-run with --strict from CI.
# See _system/SCAFFOLD_ISOLATION_COMPLETION_GATE.md.
if [[ -f "${TARGET_REPO}/_system/.aiast-role.json" ]] \
   && [[ -f "${TARGET_REPO}/_system/scaffold-isolation-gates.json" ]] \
   && [[ -f "${TARGET_REPO}/bootstrap/check-scaffold-isolation-gate.sh" ]]; then
  _role="$(python3 -c "import json,sys;
try: print(json.load(open(sys.argv[1])).get('role','unknown'))
except Exception: print('unknown')" "${TARGET_REPO}/_system/.aiast-role.json" 2>/dev/null || echo unknown)"
  if [[ "${_role}" == "downstream-app" ]]; then
    bash "${TARGET_REPO}/bootstrap/check-scaffold-isolation-gate.sh" "${TARGET_REPO}" --best-effort \
      || true
  fi
fi

# Blank-app onboarding seed (downstream-app only). Make the first agent
# session unmistakably see that this is a blank app repo awaiting an app
# definition: print the identity directive and prepend a one-time banner to
# the continuity file agents read on entry. Idempotent; never aborts init.
if [[ -f "${TARGET_REPO}/_system/.aiast-role.json" ]]; then
  _onb_role="$(python3 -c "import json,sys;
try: print(json.load(open(sys.argv[1])).get('role','downstream-app'))
except Exception: print('downstream-app')" "${TARGET_REPO}/_system/.aiast-role.json" 2>/dev/null || echo downstream-app)"
  if [[ "${_onb_role}" == "downstream-app" ]]; then
    if [[ -x "${TARGET_REPO}/bootstrap/check-app-definition-state.sh" ]]; then
      bash "${TARGET_REPO}/bootstrap/check-app-definition-state.sh" "${TARGET_REPO}" || true
    fi
    _wlo="${TARGET_REPO}/WHERE_LEFT_OFF.md"
    if [[ -f "${_wlo}" ]] && ! grep -q "BLANK APP REPO — define the app first" "${_wlo}" 2>/dev/null; then
      _tmp_wlo="$(mktemp)"
      {
        printf '## ⟢ BLANK APP REPO — define the app first\n\n'
        printf 'This repo was just scaffolded as a **blank app-building repo**\n'
        printf '(role=downstream-app). It is NOT the meta-system template.\n\n'
        printf 'First session: read `_system/APP_REPO_IDENTITY.md`, establish the\n'
        printf 'app with the operator, fill `PRODUCT_BRIEF.md`, then build the\n'
        printf 'app into `app/` using the `_system/` meta-system. Run\n'
        printf '`bootstrap/check-app-definition-state.sh` anytime to re-check.\n\n'
        printf -- '---\n\n'
        cat "${_wlo}"
      } > "${_tmp_wlo}" && mv "${_tmp_wlo}" "${_wlo}"
    fi
  fi
fi

echo "Initialized AIAST $(aiaast_template_version "${TEMPLATE_ROOT}") in ${TARGET_REPO}"
