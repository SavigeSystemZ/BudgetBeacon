#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--out-dir PATH] [--signer NAME] [--apply] [--json]"
  exit 2
fi

repo="$1"; shift || true
repo_abs="$(cd -- "${repo}" && pwd)"

if [[ -d "${repo_abs}/TEMPLATE" && -d "${repo_abs}/_META_AGENT_SYSTEM" ]]; then
  source_root="${repo_abs}"
  template_root="${repo_abs}/TEMPLATE"
elif [[ "$(basename -- "${repo_abs}")" == "TEMPLATE" && -d "${repo_abs}/../_META_AGENT_SYSTEM" ]]; then
  source_root="$(cd -- "${repo_abs}/.." && pwd)"
  template_root="${repo_abs}"
else
  source_root="${repo_abs}"
  template_root="${repo_abs}"
fi

if [[ -d "${source_root}/_META_AGENT_SYSTEM" ]]; then
  out_dir="${source_root}/_META_AGENT_SYSTEM/evidence/release-packets"
else
  out_dir="${repo_abs}/_META_AGENT_SYSTEM/evidence/release-packets"
fi

apply=0
json_mode=0
signer=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --signer) signer="${2:-}"; shift 2 ;;
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "generate-release-packet.sh" "release-packet"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
manifest="${out_dir}/RELEASE_PACKET_${stamp}.json"
summary="${out_dir}/RELEASE_PACKET_${stamp}.md"
checksums="${out_dir}/RELEASE_PACKET_${stamp}.sha256"
artifact_index="${out_dir}/RELEASE_PACKET_${stamp}.artifacts.json"
head_sha="$(git -C "${source_root}" rev-parse HEAD 2>/dev/null || echo unknown)"
if [[ -z "${signer}" ]]; then
  signer="$(git -C "${source_root}" config user.email 2>/dev/null || git -C "${source_root}" config user.name 2>/dev/null || echo unknown)"
fi

packet_payload="$(
  python3 - "$source_root" "$template_root" "$out_dir" "$stamp" "$timestamp" "$head_sha" "$apply" "$signer" <<'PY'
from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

source_root = Path(sys.argv[1]).resolve()
template_root = Path(sys.argv[2]).resolve()
out_dir = Path(sys.argv[3]).resolve()
stamp = sys.argv[4]
timestamp = sys.argv[5]
head_sha = sys.argv[6]
apply = sys.argv[7] == "1"
signer = sys.argv[8]

manifest_path = out_dir / f"RELEASE_PACKET_{stamp}.json"
summary_path = out_dir / f"RELEASE_PACKET_{stamp}.md"
checksums_path = out_dir / f"RELEASE_PACKET_{stamp}.sha256"
artifact_index_path = out_dir / f"RELEASE_PACKET_{stamp}.artifacts.json"

include_patterns = [
    "_META_AGENT_SYSTEM/evidence/*.md",
    "_META_AGENT_SYSTEM/evidence/*.json",
    "TEMPLATE/_system/context/VALIDATION_EVIDENCE.md",
    "TEMPLATE/RELEASE_NOTES.md",
]

candidate_paths: set[Path] = set()
evidence_dir = source_root / "_META_AGENT_SYSTEM" / "evidence"
if evidence_dir.is_dir():
    for suffix in ("*.md", "*.json"):
        for path in evidence_dir.glob(suffix):
            if path.is_file():
                candidate_paths.add(path.resolve())

for path in (
    template_root / "_system" / "context" / "VALIDATION_EVIDENCE.md",
    template_root / "RELEASE_NOTES.md",
):
    if path.is_file():
        candidate_paths.add(path.resolve())

artifact_records = []
checksum_lines = []
for path in sorted(candidate_paths, key=lambda item: str(item.relative_to(source_root) if item.is_relative_to(source_root) else item)):
    if not path.is_file():
        continue
    rel_path = str(path.relative_to(source_root)) if path.is_relative_to(source_root) else str(path)
    data = path.read_bytes()
    digest = hashlib.sha256(data).hexdigest()
    artifact_records.append(
        {
            "path": rel_path,
            "size_bytes": len(data),
            "sha256": digest,
        }
    )
    checksum_lines.append(f"{digest}  {rel_path}")

artifact_index_payload = {
    "version": "1.0.0",
    "artifact_count": len(artifact_records),
    "artifacts": artifact_records,
}
artifact_index_json = json.dumps(artifact_index_payload, indent=2, sort_keys=True) + "\n"
artifact_index_sha256 = hashlib.sha256(artifact_index_json.encode("utf-8")).hexdigest()

signature_payload = {
    "scheme": "sha256-artifact-index-v1",
    "status": "checksum_attested",
    "signer": signer,
    "signed_at": timestamp,
    "artifact_index_sha256": artifact_index_sha256,
}
packet_core = {
    "version": "3.0.0",
    "timestamp": timestamp,
    "source_root": str(source_root),
    "template_root": str(template_root),
    "head": head_sha,
    "includes": include_patterns,
    "artifact_count": len(artifact_records),
    "artifact_index": str(artifact_index_path),
    "artifact_index_sha256": artifact_index_sha256,
    "checksums": str(checksums_path),
}
packet_payload_sha256 = hashlib.sha256(
    json.dumps(packet_core, sort_keys=True, separators=(",", ":")).encode("utf-8")
).hexdigest()
signature_payload["packet_payload_sha256"] = packet_payload_sha256
manifest_payload = {
    **packet_core,
    "signature": signature_payload,
}

if apply:
    out_dir.mkdir(parents=True, exist_ok=True)
    artifact_index_path.write_text(artifact_index_json, encoding="utf-8")
    checksums_path.write_text("\n".join(checksum_lines) + ("\n" if checksum_lines else ""), encoding="utf-8")
    manifest_path.write_text(json.dumps(manifest_payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    summary_lines = [
        "# Release Packet",
        "",
        f"- version: `{manifest_payload['version']}`",
        f"- timestamp: `{timestamp}`",
        f"- head: `{head_sha}`",
        f"- manifest: `{manifest_path}`",
        f"- artifact_index: `{artifact_index_path}`",
        f"- artifact_index_sha256: `{artifact_index_sha256}`",
        f"- checksums: `{checksums_path}`",
        f"- signature_scheme: `{signature_payload['scheme']}`",
        f"- signature_status: `{signature_payload['status']}`",
        f"- signer: `{signer}`",
        f"- artifacts: `{len(artifact_records)}`",
        f"- mode: `apply`",
        "",
        "## Artifact Index",
        "",
    ]
    for record in artifact_records:
        summary_lines.append(f"- `{record['path']}` sha256 `{record['sha256']}` size `{record['size_bytes']}`")
    summary_path.write_text("\n".join(summary_lines) + "\n", encoding="utf-8")

print(json.dumps({
    "mode": "apply" if apply else "dry-run",
    "version": manifest_payload["version"],
    "manifest": str(manifest_path),
    "summary": str(summary_path),
    "checksums": str(checksums_path),
    "artifact_index": str(artifact_index_path),
    "artifact_count": len(artifact_records),
    "artifact_index_sha256": artifact_index_sha256,
    "signature": signature_payload,
}, separators=(",", ":")))
PY
)"

mode="$(python3 - <<'PY' "$packet_payload"
import json,sys
print(json.loads(sys.argv[1])["mode"])
PY
)"
manifest="$(python3 - <<'PY' "$packet_payload"
import json,sys
print(json.loads(sys.argv[1])["manifest"])
PY
)"
summary="$(python3 - <<'PY' "$packet_payload"
import json,sys
print(json.loads(sys.argv[1])["summary"])
PY
)"
checksums="$(python3 - <<'PY' "$packet_payload"
import json,sys
print(json.loads(sys.argv[1])["checksums"])
PY
)"
artifact_index="$(python3 - <<'PY' "$packet_payload"
import json,sys
print(json.loads(sys.argv[1])["artifact_index"])
PY
)"

if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "${packet_payload}" "generate-release-packet.sh" "release-packet"
else
  echo "release_packet_${mode} manifest=${manifest} summary=${summary} checksums=${checksums} artifact_index=${artifact_index}"
fi
