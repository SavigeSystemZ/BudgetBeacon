#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: generate-system-registry.sh [target-repo] [--output <path>] [--write]

Generate a deterministic machine-readable registry of AIAST-managed files.
EOF
}

TARGET_REPO=""
OUTPUT_PATH=""
WRITE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --write)
      WRITE=1
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
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

if [[ ${WRITE} -eq 1 ]]; then
  aiaast_assert_non_root_for_repo_writes
fi

if [[ ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

if [[ ${WRITE} -eq 1 && -z "${OUTPUT_PATH}" ]]; then
  OUTPUT_PATH="${TARGET_REPO}/_system/SYSTEM_REGISTRY.json"
fi

mapfile -t managed_files < <(aiaast_print_managed_files "${TARGET_REPO}")

python3 - <<'PY' "${TARGET_REPO}" "${OUTPUT_PATH}" "${SCRIPT_DIR}/lib/aiaast-lib.sh" "${WRITE}" "${managed_files[@]}"
import json
import shlex
import subprocess
import sys
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
output_path = sys.argv[2]
lib_path = Path(sys.argv[3]).resolve()
write_enabled = sys.argv[4] == "1"
managed_files = list(sys.argv[5:])

def shell_out(func: str, rel: str) -> str:
    quoted_lib = shlex.quote(str(lib_path))
    cmd = (
        f"source {quoted_lib} >/dev/null 2>&1 && "
        f"{func} {shlex.quote(rel)}"
    )
    result = subprocess.run(
        ["bash", "-lc", cmd],
        cwd=repo_root,
        text=True,
        capture_output=True,
        check=True,
    )
    return result.stdout.strip()

entries = []
for rel in managed_files:
    path = repo_root / rel
    entries.append(
        {
            "category": shell_out("aiaast_path_category", rel),
            "kind": "file",
            "path": rel,
            "size_bytes": path.stat().st_size,
        }
    )

registry = {
    "template_name": "AIAST",
    "template_version": (repo_root / "_system/.template-version").read_text().strip() if (repo_root / "_system/.template-version").exists() else "unknown",
    "system_readme_path": "AI_SYSTEM_README.md" if (repo_root / "AI_SYSTEM_README.md").exists() else "README.md",
    "managed_file_count": len(entries),
    "entries": sorted(entries, key=lambda item: item["path"]),
}

payload = json.dumps(registry, indent=2, sort_keys=True) + "\n"

if write_enabled:
    out = Path(output_path).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(payload)
else:
    print(payload, end="")
PY

if [[ ${WRITE} -eq 1 ]]; then
  echo "Wrote system registry to ${OUTPUT_PATH}"
fi
