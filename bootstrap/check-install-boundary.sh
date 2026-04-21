#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-install-boundary.sh [target-repo]

Fail if maintainer-only or foreign product layers are present inside an installed AIAST repo.
EOF
}

TARGET_REPO="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"

if [[ "${TARGET_REPO}" == "-h" || "${TARGET_REPO}" == "--help" ]]; then
  usage
  exit 0
fi

python3 - <<'PY' "${TARGET_REPO}"
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
forbidden = [
    "_META_AGENT_SYSTEM",
    "_TEMPLATE_FACTORY",
    "_MOS_TEMPLATE_FACTORY",
    "MOS_TEMPLATE",
    "MOS_SOURCE_LIBRARY",
    "_META_AGENT_SYSTEM/.meta-only",
    "_TEMPLATE_FACTORY/.factory-only",
    "_MOS_TEMPLATE_FACTORY/.factory-only",
    "MOS_SOURCE_LIBRARY/.source-library-only",
    "MOS_TEMPLATE/.installable-product-root",
]
issues = [item for item in forbidden if (repo / item).exists()]

if issues:
    print("install_boundary_failed")
    for item in issues:
        print(f"- unexpected maintainer-only or foreign product path present: {item}")
    raise SystemExit(1)

print("install_boundary_ok")
PY
