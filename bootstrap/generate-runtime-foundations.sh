#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates/runtime"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: generate-runtime-foundations.sh <target-repo> [--app-name NAME] [--app-id ID] [--package-name NAME] [--version VERSION] [--force]

Generate project-owned runtime scaffolds such as packaging manifests, install scripts,
mobile foundations, and AI configuration examples.
EOF
}

TARGET_REPO=""
APP_NAME=""
APP_ID=""
PACKAGE_NAME=""
APP_VERSION="0.1.0"
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --app-id)
      APP_ID="${2:-}"
      shift 2
      ;;
    --package-name)
      PACKAGE_NAME="${2:-}"
      shift 2
      ;;
    --version)
      APP_VERSION="${2:-}"
      shift 2
      ;;
    --force)
      FORCE=1
      shift
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

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ ! -d "${TEMPLATES_DIR}" ]]; then
  echo "Missing runtime templates directory: ${TEMPLATES_DIR}" >&2
  exit 1
fi

python3 - <<'PY' "${TEMPLATES_DIR}" "${TARGET_REPO}" "${APP_NAME}" "${APP_ID}" "${PACKAGE_NAME}" "${APP_VERSION}" "${FORCE}" "${TEMPLATE_ROOT}"
from __future__ import annotations

import re
import stat
import sys
from pathlib import Path

templates_dir = Path(sys.argv[1]).resolve()
target_repo = Path(sys.argv[2]).resolve()
app_name = sys.argv[3].strip()
app_id = sys.argv[4].strip()
package_name = sys.argv[5].strip()
app_version = sys.argv[6].strip()
force = sys.argv[7] == "1"
template_root = Path(sys.argv[8]).resolve()


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    value = re.sub(r"-{2,}", "-", value).strip("-")
    return value or "app"


slug = slugify(app_name)
app_id = app_id or f"io.aiaast.{slug.replace('-', '.')}"
package_name = package_name or app_id
desktop_id = app_id
service_name = slug
android_label = app_name

context = {
    "__AIAST_APP_NAME__": app_name,
    "__AIAST_APP_SLUG__": slug,
    "__AIAST_APP_ID__": app_id,
    "__AIAST_PACKAGE_NAME__": package_name,
    "__AIAST_VERSION__": app_version,
    "__AIAST_DESKTOP_ID__": desktop_id,
    "__AIAST_SERVICE_NAME__": service_name,
    "__AIAST_BIND_ADDRESS__": "127.0.0.1",
    "__AIAST_PORT_RANGE_START__": "46300",
    "__AIAST_PORT_RANGE_END__": "46400",
    "__AIAST_COMPANY_NAME__": "Project Owner Placeholder",
    "__AIAST_AUTHOR_LINE__": "Built with AIAST runtime scaffolding",
    "__AIAST_EASTER_EGG_NAME__": "Internal credit note placeholder",
    "__AIAST_ANDROID_LABEL__": android_label,
    "__AIAST_RUNTIME_ROOT__": str(target_repo),
    "__AIAST_TEMPLATE_ROOT__": str(template_root),
}

created: list[str] = []
skipped: list[str] = []

for src in sorted(path for path in templates_dir.rglob("*") if path.is_file()):
    if "__pycache__" in src.parts or src.suffix == ".pyc":
        continue
    rel = src.relative_to(templates_dir)
    rendered_rel = str(rel)
    for key, value in context.items():
        rendered_rel = rendered_rel.replace(key, value)
    rendered_rel_path = Path(rendered_rel)
    target = target_repo / rendered_rel_path
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() and not force:
      skipped.append(str(rendered_rel_path))
      continue

    text = src.read_text()
    for key, value in context.items():
        text = text.replace(key, value)
    target.write_text(text)
    source_mode = stat.S_IMODE(src.stat().st_mode)
    if source_mode & 0o111:
        target.chmod(source_mode)
    created.append(str(rendered_rel_path))

if created:
    print("created_runtime_foundations")
    for rel in created:
        print(f"+ {rel}")
if skipped:
    print("skipped_existing_runtime_foundations")
    for rel in skipped:
        print(f"= {rel}")
PY
