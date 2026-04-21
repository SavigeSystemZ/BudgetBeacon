#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: configure-project-profile.sh <target-repo> [--app-name NAME]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
APP_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
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

aiaast_assert_non_root_for_repo_writes

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME="$(basename -- "${TARGET_REPO}")"
fi

PROFILE="${TARGET_REPO}/_system/PROJECT_PROFILE.md"

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

python3 - <<'PY' "${PROFILE}" "${APP_NAME}"
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
app_name = sys.argv[2]
slug = re.sub(r"[^a-z0-9]+", "-", app_name.lower()).strip("-") or "app"
app_id = f"io.aiaast.{slug.replace('-', '.')}"
text = path.read_text()


def replace_line(label: str, value: str) -> None:
    global text
    text = re.sub(
        rf"^- {re.escape(label)}:.*$",
        f"- {label}: {value}",
        text,
        count=1,
        flags=re.MULTILINE,
    )


replace_line("App name", app_name)
replace_line("App id", app_id)
replace_line("Desktop entry id", app_id)
replace_line("Android application id", app_id)
replace_line("Branch strategy", "main for runtime code, system for copied AIAST updates, optional short-lived feature branches")
replace_line("Packaging manifest paths", "packaging/appimage.yml, packaging/flatpak-manifest.json, packaging/snapcraft.yaml")
replace_line("Installer commands", "ops/install/install.sh, ops/install/repair.sh, ops/install/uninstall.sh, ops/install/purge.sh")
replace_line("Android module path", "mobile/flutter/")
replace_line("LLM config path", "ai/llm_config.yaml")
replace_line("Chatbot surfaces", "CLI REPL, REST endpoint, GUI side panel when a UI exists")
replace_line("Signing identity", "Release owner placeholder; replace before shipping signed artifacts")
path.write_text(text)
PY

echo "Configured project profile for ${APP_NAME}"
