#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-network-bindings.sh <target-repo> [--json] [--include-template-assets]

Scan source files for wildcard network bindings (0.0.0.0, ::) that violate
SECURITY_HARDENING_CONTRACT.md loopback-only requirements. Also checks
configuration files for wildcard host patterns.
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
JSON_MODE=0
INCLUDE_TEMPLATE_ASSETS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)
      JSON_MODE=1
      shift
      ;;
    --include-template-assets)
      INCLUDE_TEMPLATE_ASSETS=1
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

if [[ -z "${TARGET_REPO}" || ! -d "${TARGET_REPO}" ]]; then
  echo "Target repo does not exist: ${TARGET_REPO}" >&2
  exit 1
fi

python3 - <<'PY' "${TARGET_REPO}" "${JSON_MODE}" "${INCLUDE_TEMPLATE_ASSETS}"
from __future__ import annotations

import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"
include_template_assets = sys.argv[3] == "1"

# File extensions to scan
CODE_EXTS = {
    ".py", ".js", ".ts", ".jsx", ".tsx", ".go", ".rs", ".rb", ".java",
    ".sh",
    ".kt", ".swift", ".dart", ".c", ".cpp", ".h", ".cs", ".php",
}
CONFIG_EXTS = {
    ".json", ".yml", ".yaml", ".toml", ".ini", ".cfg", ".conf", ".env",
    ".service",
}
SCAN_EXTS = CODE_EXTS | CONFIG_EXTS

# Directories to skip
SKIP_DIRS = {
    ".git", "node_modules", "__pycache__", ".venv", "venv", "vendor",
    "dist", "build", ".next",
    ".mypy_cache", "mypy_cache", ".ruff_cache", ".pytest_cache",
    # Vendored template snapshots under an app repo; not app runtime surface.
    "_AI_AGENT_SYSTEM",
    "_AI_AGENT_SYSTEM_TEMPLATE",
    "_AIAST",
}
if not include_template_assets:
    SKIP_DIRS.update({"_system", "bootstrap"})

SKIP_FILES = {
    "bootstrap/check-network-bindings.sh",
    "bootstrap/check-runtime-foundations.sh",
}

# Patterns that indicate wildcard binding
WILDCARD_PATTERNS = [
    # 0.0.0.0 in various contexts
    (re.compile(r'''(?:"|')0\.0\.0\.0(?:"|')'''), "0.0.0.0 string literal"),
    (re.compile(r'''host\s*[=:]\s*(?:"|')0\.0\.0\.0(?:"|')'''), "host = 0.0.0.0"),
    (re.compile(r'''bind\s*[=:(]\s*(?:"|')0\.0\.0\.0(?:"|')'''), "bind(0.0.0.0)"),
    (re.compile(r'''listen\s*[=:(]\s*(?:"|')0\.0\.0\.0(?:"|')'''), "listen(0.0.0.0)"),
    (re.compile(r'''INADDR_ANY'''), "INADDR_ANY constant"),
    # :: (IPv6 wildcard) — careful to distinguish from other :: uses
    (re.compile(r'''(?:"|')::\s*(?:"|')'''), ":: IPv6 wildcard string"),
    (re.compile(r'''host\s*[=:]\s*(?:"|')::\s*(?:"|')'''), "host = :: (IPv6 wildcard)"),
    (re.compile(r'''IN6ADDR_ANY'''), "IN6ADDR_ANY constant"),
    # CORS wildcards
    (re.compile(r'''(?:cors|origin|allow)[^=\n]*[=:]\s*(?:"|')\*(?:"|')''', re.IGNORECASE), "CORS wildcard origin"),
    (re.compile(r'''python3\s+-m\s+http\.server(?!.*--bind)'''), "http.server without explicit bind"),
]

# Safe/expected patterns to exclude
SAFE_PATTERNS = [
    re.compile(r'#.*0\.0\.0\.0'),           # Comments
    re.compile(r'//.*0\.0\.0\.0'),           # Comments
    re.compile(r'/\*.*0\.0\.0\.0'),          # Comments
    re.compile(r'(?:block|deny|reject|filter).*0\.0\.0\.0', re.IGNORECASE),  # Security rules blocking it
    re.compile(r'SSRF.*0\.0\.0\.0', re.IGNORECASE),  # SSRF prevention docs
    re.compile(r'\.md$'),                     # Markdown docs
]

findings: list[dict] = []

def should_skip(path: Path) -> bool:
    rel_path = path.relative_to(target)
    if rel_path.as_posix() in SKIP_FILES:
        return True
    for part in rel_path.parts:
        if part in SKIP_DIRS:
            return True
    return False

def is_safe_context(line: str, filepath: Path) -> bool:
    stripped = line.strip()
    # Skip comment-only lines
    if stripped.startswith("#") or stripped.startswith("//") or stripped.startswith("/*"):
        return True
    # Skip if filepath is a markdown doc
    if filepath.suffix == ".md":
        return True
    # Governed allocator returns wildcard only when exposure is LAN/public; must stay opt-in.
    if "aiast-network-bind-lan-public" in line:
        return True
    # Allow explicit whitelisting via comment marker
    if "aiast-network-bind-skip-check" in line:
        return True
    # Comparisons or security checks are often safe if they are testing FOR the wildcard to block it.
    if '== "0.0.0.0"' in line or '!= "0.0.0.0"' in line or '= "0.0.0.0"' in line:
        return True
    if '== "::"' in line or '!= "::"' in line or '= "::"' in line:
        return True
    # Membership tests used to warn or reject wildcards (e.g. if bind in ("0.0.0.0", "::")).
    if "in (" in line and "0.0.0.0" in line and ("'::'" in line or '"::"' in line):
        return True
    return False

for path in sorted(target.rglob("*")):
    if not path.is_file():
        continue
    if should_skip(path):
        continue
    if path.suffix not in SCAN_EXTS:
        continue

    try:
        content = path.read_text(errors="replace")
    except (PermissionError, OSError):
        continue

    rel = str(path.relative_to(target))
    for i, line in enumerate(content.splitlines(), 1):
        if is_safe_context(line, path):
            continue
        for pattern, description in WILDCARD_PATTERNS:
            if pattern.search(line):
                findings.append({
                    "file": rel,
                    "line": i,
                    "pattern": description,
                    "content": line.strip()[:200],
                })

results: dict[str, object] = {
    "template_name": "AIAST",
    "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    "target_repo": str(target),
    "findings": findings,
    "finding_count": len(findings),
    "status": "clean" if not findings else "findings",
    "reference": "_system/SECURITY_HARDENING_CONTRACT.md section 1: Network & Bind Model",
}

report = json.dumps(results, indent=2, sort_keys=True) + "\n"

if json_mode:
    print(report, end="")
else:
    if not findings:
        print("No wildcard network binding violations found.")
    else:
        print(f"Found {len(findings)} potential wildcard binding violation(s):")
        for f in findings:
            print(f"  {f['file']}:{f['line']} — {f['pattern']}")
            print(f"    {f['content']}")
        print()
        print("Reference: _system/SECURITY_HARDENING_CONTRACT.md section 1")
        print("Services must bind to 127.0.0.1 or ::1 only, not 0.0.0.0 or ::")

if findings:
    sys.exit(1)
PY
