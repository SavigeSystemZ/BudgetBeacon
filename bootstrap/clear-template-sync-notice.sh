#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bootstrap/lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: clear-template-sync-notice.sh [target-repo]

Reset _system/TEMPLATE_SYNC_NOTICE.md to CLEARED after you finished the
post-template-sync health checklist (see _system/DOWNSTREAM_PRESERVATION_AND_SYNC_NOTICE_POLICY.md).

Default target-repo is the repo containing this bootstrap directory.
EOF
}

TARGET_REPO="${1:-}"
if [[ -z "${TARGET_REPO}" ]]; then
  TARGET_REPO="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

RESOLVED="$(cd -- "${TARGET_REPO}" && pwd)"
ver="$(aiaast_template_version "${RESOLVED}")"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
notice="${RESOLVED}/_system/TEMPLATE_SYNC_NOTICE.md"
mkdir -p "${RESOLVED}/_system"

python3 - <<'PY' "${notice}" "${ts}" "${ver}"
from pathlib import Path
import json
import sys

path = Path(sys.argv[1])
ts, ver = sys.argv[2], sys.argv[3]
body = "\n".join(
    [
        "# Template operating-layer sync notice",
        "",
        "**Agent gate:** CLEARED",
        "",
        f"**Cleared (UTC):** {ts}",
        f"**Installed template version marker:** {ver}",
        "",
        "No pending template-sync health gate. The next `init-project`,",
        "`install-missing-files`, or `update-template` write will set",
        "**PENDING_HEALTH_CHECK** again.",
        "",
        "<!-- machine_json: "
        + json.dumps(
            {
                "agent_gate": "CLEARED",
                "ts": ts,
                "installed_template_version": ver,
            },
            separators=(",", ":"),
        )
        + " -->",
        "",
    ]
)
path.write_text(body + "\n", encoding="utf-8")
PY

echo "Wrote cleared template sync notice to ${notice}"
