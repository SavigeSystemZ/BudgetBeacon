#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <target-repo> [--max-age-days N] [--allowlist FILE] [--apply] [--json]"
  exit 2
fi
repo="$1"; shift || true
max_age=14
apply=0
json_mode=0
allowlist="${repo}/TEMPLATE/_system/EVIDENCE_RETENTION_PROTECTED_ALLOWLIST.txt"
[[ -f "${repo}/_system/EVIDENCE_RETENTION_PROTECTED_ALLOWLIST.txt" ]] && allowlist="${repo}/_system/EVIDENCE_RETENTION_PROTECTED_ALLOWLIST.txt"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --max-age-days) max_age="${2:-14}"; shift 2 ;;
    --allowlist) allowlist="${2:-}"; shift 2 ;;
    --apply) apply=1; shift ;;
    --json) json_mode=1; shift ;;
    *)
      [[ "$json_mode" -eq 1 ]] && aiaast_json_error "invalid_argument" "unknown arg: $1" "check-evidence-retention.sh" "retention"
      [[ "$json_mode" -eq 0 ]] && echo "unknown arg: $1"
      exit 2
      ;;
  esac
done

evidence_dir="${repo}/_META_AGENT_SYSTEM/evidence"
[[ -d "$evidence_dir" ]] || mkdir -p "$evidence_dir"
cutoff_epoch="$(date -u -d "-${max_age} days" +%s)"
stale=0
deleted=0
protected=0

is_protected() {
  local name="$1"
  [[ -f "$allowlist" ]] || return 1
  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue
    [[ "$pattern" =~ ^# ]] && continue
    if [[ "$name" == $pattern ]]; then
      return 0
    fi
  done < "$allowlist"
  return 1
}

while IFS= read -r file; do
  base="$(basename "$file")"
  if is_protected "$base"; then
    protected=$((protected + 1))
    continue
  fi
  mtime="$(stat -c %Y "$file")"
  if [[ "$mtime" -lt "$cutoff_epoch" ]]; then
    stale=$((stale + 1))
    if [[ "$apply" -eq 1 ]]; then
      rm -f "$file"
      deleted=$((deleted + 1))
    fi
  fi
done < <(rg --files "$evidence_dir" -g "*.json" -g "*.md")

mode="report"
[[ "$apply" -eq 1 ]] && mode="apply"
if [[ "$json_mode" -eq 1 ]]; then
  aiaast_json_ok "{\"mode\":\"${mode}\",\"stale\":${stale},\"deleted\":${deleted},\"protected\":${protected},\"max_age_days\":${max_age}}" "check-evidence-retention.sh" "retention"
else
  echo "evidence_retention_ok mode=${mode} stale=${stale} deleted=${deleted} protected=${protected} max_age_days=${max_age}"
fi
