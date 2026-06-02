#!/usr/bin/env bash
# aiaast-repo.sh — template version, install metadata, profile + repo-mode
# S22b WS6: module of the aiaast-lib.sh facade (sourced via aiaast-lib.sh;
# same path + function names as before — fully back-compatible).

aiaast_template_version() {
  local root="$1"
  local version_file="${root}/_system/.template-version"

  if [[ -f "${version_file}" ]]; then
    tr -d '\n' < "${version_file}"
    return 0
  fi

  echo "unknown"
}

aiaast_install_metadata_path() {
  local repo_root="$1"
  printf '%s\n' "${repo_root}/_system/.template-install.json"
}

aiaast_install_metadata_value() {
  local repo_root="$1"
  local key="$2"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  if [[ ! -f "${metadata_path}" ]]; then
    return 0
  fi

  python3 - <<'PY' "${metadata_path}" "${key}"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
key = sys.argv[2]
try:
    data = json.loads(path.read_text())
except Exception:
    raise SystemExit(0)

value = data.get(key)
if value is not None:
    print(value)
PY
}

aiaast_scaffold_profile_manifest_path() {
  local repo_root="$1"

  if [[ -f "${repo_root}/_system/scaffold-profiles.json" ]]; then
    printf '%s\n' "${repo_root}/_system/scaffold-profiles.json"
    return 0
  fi

  if [[ -f "${repo_root}/_system/runtime-profiles/scaffold-profiles.json" ]]; then
    printf '%s\n' "${repo_root}/_system/runtime-profiles/scaffold-profiles.json"
    return 0
  fi

  return 1
}

aiaast_resolve_scaffold_profile() {
  local repo_root="$1"
  local requested="${2:-}"
  local profile

  if [[ -n "${requested}" ]]; then
    profile="${requested}"
  else
    profile="$(aiaast_install_metadata_value "${repo_root}" "scaffold_profile")"
  fi

  if [[ -z "${profile}" ]]; then
    profile="standard"
  fi

  printf '%s\n' "${profile}"
}

aiaast_detect_repo_mode() {
  local repo_root="$1"
  local install_mode
  local last_event

  install_mode="$(aiaast_install_metadata_value "${repo_root}" "install_mode")"
  last_event="$(aiaast_install_metadata_value "${repo_root}" "last_event")"

  if [[ "${install_mode}" == "template-placeholder" || "${last_event}" == "template-source" ]]; then
    printf '%s\n' "template"
  else
    printf '%s\n' "installed"
  fi
}

aiaast_resolve_repo_mode() {
  local repo_root="$1"
  local requested_mode="${2:-auto}"

  case "${requested_mode}" in
    auto)
      aiaast_detect_repo_mode "${repo_root}"
      ;;
    template|installed)
      printf '%s\n' "${requested_mode}"
      ;;
    *)
      echo "Unsupported repo mode: ${requested_mode}" >&2
      return 1
      ;;
  esac
}

aiaast_detect_system_readme_path() {
  local repo_root="$1"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  if [[ -f "${metadata_path}" ]]; then
    python3 - <<'PY' "${metadata_path}"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
try:
    data = json.loads(path.read_text())
    value = data.get("system_readme_path")
    if value:
        print(value)
except Exception:
    pass
PY
    return 0
  fi

  if [[ -f "${repo_root}/AI_SYSTEM_README.md" ]]; then
    echo "AI_SYSTEM_README.md"
  else
    echo "README.md"
  fi
}

aiaast_project_profile_needs_configuration() {
  local repo_root="$1"
  local profile_path="${repo_root}/_system/PROJECT_PROFILE.md"

  if [[ ! -f "${profile_path}" ]]; then
    return 1
  fi

  if grep -Eq '^- App name:[[:space:]]*$' "${profile_path}"; then
    return 0
  fi

  return 1
}

aiaast_resolve_app_name() {
  local repo_root="$1"
  local profile_path="${repo_root}/_system/PROJECT_PROFILE.md"
  local product_brief_path="${repo_root}/PRODUCT_BRIEF.md"
  local metadata_path
  metadata_path="$(aiaast_install_metadata_path "${repo_root}")"

  local app_name
  app_name="$(
      python3 - <<'PY' "${profile_path}" "${product_brief_path}" "${metadata_path}"
from pathlib import Path
import json
import re
import sys

profile_path = Path(sys.argv[1])
brief_path = Path(sys.argv[2])
metadata_path = Path(sys.argv[3])

if profile_path.exists():
    text = profile_path.read_text()
    match = re.search(r"^- App name:[ \t]*(.+?)\s*$", text, re.MULTILINE)
    if match:
        value = match.group(1).strip()
        if value:
            print(value, end="")
            raise SystemExit(0)

if brief_path.exists():
    text = brief_path.read_text()
    match = re.search(r"^- Product name:[ \t]*(.+?)\s*$", text, re.MULTILINE)
    if match:
        value = match.group(1).strip()
        if value:
            print(value, end="")
            raise SystemExit(0)

if metadata_path.exists():
    try:
        data = json.loads(metadata_path.read_text())
    except Exception:
        data = {}
    value = str(data.get("app_name", "")).strip()
    if value:
        print(value, end="")
PY
  )"
  if [[ -n "${app_name}" ]]; then
    printf '%s\n' "${app_name}"
    return 0
  fi

  basename -- "${repo_root}"
}
