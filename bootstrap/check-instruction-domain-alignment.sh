#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: check-instruction-domain-alignment.sh <repo-root> [--validate-manifest | --message <text> | --message-file <path>]

  --validate-manifest   Ensure PROJECT_DOMAIN_MANIFEST.json exists and parses (default when no message).
  --message <text>      Scan instruction text for manifest guard keywords (case-insensitive).
  --message-file <path> Read message from file (UTF-8).

Exit codes:
  0  OK or no manifest (skip)
  3  Guard keyword match — treat as DOMAIN_MISMATCH_SUSPECTED (halt writes without confirmation)
EOF
}

REPO=""
MODE="validate"
MESSAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --validate-manifest)
      MODE="validate"
      shift
      ;;
    --message)
      MESSAGE="${2:-}"
      MODE="scan"
      shift 2
      ;;
    --message-file)
      MESSAGE="$(cat "${2:-}")"
      MODE="scan"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      if [[ -z "${REPO}" ]]; then
        REPO="$1"
        shift
      else
        echo "Unexpected argument: $1" >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "${REPO}" || ! -d "${REPO}" ]]; then
  usage
  exit 1
fi

ROOT="$(cd -- "${REPO}" && pwd)"

python3 - <<'PY' "${ROOT}" "${MODE}" "${MESSAGE}"
from __future__ import annotations

import json
import sys
from pathlib import Path

repo = Path(sys.argv[1]).resolve()
mode = sys.argv[2]
message = sys.argv[3]

manifest_path = repo / "_system" / "PROJECT_DOMAIN_MANIFEST.json"

if not manifest_path.is_file():
    print("instruction_domain_alignment_skip (no manifest)")
    raise SystemExit(0)

try:
    data = json.loads(manifest_path.read_text())
except Exception as exc:
    print(f"instruction_domain_manifest_invalid: {exc}", file=sys.stderr)
    raise SystemExit(2)

if mode == "validate":
    for key in ("schema_version", "product_summary", "primary_domains", "instruction_mismatch_guards"):
        if key not in data:
            print(f"instruction_domain_manifest_invalid: missing key {key}", file=sys.stderr)
            raise SystemExit(2)
    print("instruction_domain_manifest_ok")
    raise SystemExit(0)

# scan mode
text = (message or "").lower()
if not text.strip():
    print("instruction_domain_alignment_skip (empty message)")
    raise SystemExit(0)

hits = []
for guard in data.get("instruction_mismatch_guards", []) or []:
    gid = guard.get("id", "unknown")
    for kw in guard.get("keywords", []) or []:
        if not isinstance(kw, str) or not kw.strip():
            continue
        if kw.lower() in text:
            hits.append(f"{gid}:{kw}")

if hits:
    print("instruction_domain_mismatch_suspected")
    for h in hits:
        print(f"- matched_guard {h}")
    phrase = data.get("cross_domain_confirmation_phrase") or "CONFIRM_CROSS_DOMAIN_INSTRUCTION"
    print(f"- required_confirmation_phrase: {phrase}")
    raise SystemExit(3)

print("instruction_domain_alignment_ok")
PY
