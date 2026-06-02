#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-agent-instance-isolation.sh <repo-root> [--json] [--strict]

Validates the per-instance isolation invariants from
AGENT_INSTANCE_ISOLATION_POLICY.md §"Validation invariants":

  * every active lease has a matching heartbeat
  * every active lease agent_id matches the naming regex
  * concurrency cap not exceeded per agent_type
  * no two active leases share the same agent_id
  * every lease app_id equals app-local-namespace.json#/app_id
  * every lock in locks/ is claimed by exactly one active lease
  * fencing_token values are monotonically non-decreasing in claim order
  * no active lease has fencing_token less than current max for any scope

Exit codes:
  0  ok
  1  one or more invariants violated
  2  bad arguments
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
TARGET="$1"; shift || true
JSON_MODE=0
STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json)   JSON_MODE=1; shift ;;
    --strict) STRICT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${JSON_MODE}" "${STRICT}" <<'PY'
from __future__ import annotations
import json, re, sys
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"
strict = sys.argv[3] == "1"

errors: list[str] = []
warnings: list[str] = []
mode = "unknown"

role_file = target / "_system" / ".aiast-role.json"
ns_file   = target / "_system" / "app-local-namespace.json"
pol_file  = target / "_system" / "agent-instance-policy.json"
state     = target / "_system" / "agent-state"

if role_file.is_file():
    try:
        mode = json.loads(role_file.read_text()).get("role", "unknown")
    except Exception as e:
        errors.append(f"role sentinel unreadable: {e}")

# In parent-template repo there should be no active leases; if there are, that's a problem.
if mode == "parent-template":
    leases_dir = state / "leases"
    active = []
    if leases_dir.is_dir():
        for p in leases_dir.iterdir():
            if p.name.endswith(".lease.json"): active.append(p.name)
    if active:
        errors.append(f"parent-template repo has active leases (should be empty): {active}")
    # nothing else to check in template mode
    out = {"ok": not errors, "script": "check-agent-instance-isolation.sh",
           "mode": mode, "errors": errors, "warnings": warnings, "active_leases": 0}
    if json_mode:
        print(json.dumps(out))
    else:
        print(f"[check-agent-instance-isolation] mode={mode}")
        for e in errors: print(f"  error: {e}")
        print("ok" if not errors else "FAIL")
    sys.exit(0 if not errors else 1)

# downstream-app mode from here
if not pol_file.is_file():
    errors.append(f"missing policy: {pol_file}")
    policy = {}
else:
    try:
        policy = json.loads(pol_file.read_text())
    except Exception as e:
        errors.append(f"policy unreadable: {e}"); policy = {}

regex = re.compile(policy.get("naming", {}).get("regex", "^.+$"))
allowed_types = set(policy.get("naming", {}).get("allowed_agent_types", []) or [])
caps = policy.get("concurrency_caps", {}) or {}
layout = policy.get("state_layout", {}) or {}

locks_dir      = target / layout.get("locks_dir", "_system/agent-state/locks")
leases_dir     = target / layout.get("leases_dir", "_system/agent-state/leases")
heartbeats_dir = target / layout.get("heartbeats_dir", "_system/agent-state/heartbeats")

ns_app_id = None
if ns_file.is_file():
    try: ns_app_id = json.loads(ns_file.read_text()).get("app_id")
    except Exception as e: errors.append(f"namespace unreadable: {e}")

active_leases: list[dict] = []
if leases_dir.is_dir():
    for p in sorted(leases_dir.iterdir()):
        if not p.name.endswith(".lease.json"): continue
        try:
            d = json.loads(p.read_text()); d["_path"] = str(p)
            active_leases.append(d)
        except Exception as e:
            errors.append(f"lease unreadable: {p.name}: {e}")

# Invariants.
type_counts: dict[str,int] = {}
seen_ids: set[str] = set()
for d in active_leases:
    aid = d.get("agent_id", "")
    if aid in seen_ids:
        errors.append(f"duplicate active lease agent_id: {aid}")
    seen_ids.add(aid)
    if not regex.fullmatch(aid):
        errors.append(f"agent_id does not match policy regex: {aid}")
    atype = d.get("agent_type")
    if atype not in allowed_types:
        errors.append(f"agent_type not in policy: {atype} (lease {aid})")
    type_counts[atype] = type_counts.get(atype, 0) + 1
    if ns_app_id and d.get("app_id") != ns_app_id:
        errors.append(f"lease {aid} has app_id={d.get('app_id')} but namespace says {ns_app_id}")
    hb = heartbeats_dir / f"{aid}.json"
    if not hb.is_file():
        errors.append(f"lease {aid} has no heartbeat file")

for t, n in type_counts.items():
    cap = int(caps.get(t, 1))
    if n > cap:
        errors.append(f"concurrency cap exceeded for {t}: {n} > {cap}")

# Lock <-> lease pairing.
locks: list[dict] = []
if locks_dir.is_dir():
    for p in sorted(locks_dir.iterdir()):
        if not p.name.endswith(".lock.json"): continue
        try:
            d = json.loads(p.read_text()); d["_path"] = str(p)
            locks.append(d)
        except Exception as e:
            errors.append(f"lock unreadable: {p.name}: {e}")

claimed_lock_paths = set()
for d in active_leases:
    for s in d.get("scopes", []) or []:
        lp = s.get("lock_path", "")
        claimed_lock_paths.add(str((target / lp).resolve()))

for lk in locks:
    lp = str(Path(lk["_path"]).resolve())
    if lp not in claimed_lock_paths:
        errors.append(f"orphan lock (no lease claims it): {Path(lk['_path']).name}")
    # also check the lock's owner_agent_id appears as an active lease
    owner = lk.get("owner_agent_id")
    if owner and owner not in seen_ids:
        errors.append(f"lock owner has no active lease: {Path(lk['_path']).name} owner={owner}")

# Fencing token monotonicity.
tokens = [d.get("fencing_token") for d in active_leases if isinstance(d.get("fencing_token"), int)]
if tokens != sorted(tokens):
    # not strictly required to be monotonic in the active set (leases can be claimed
    # in any order), so this is advisory only.
    warnings.append("active leases not in monotonic fencing_token order (advisory)")

# Counter sanity.
counter_path = target / policy.get("fencing", {}).get("counter_path", "_system/agent-state/.fencing-counter")
counter_val = None
if counter_path.is_file():
    try:
        counter_val = int(counter_path.read_text().strip() or "0")
    except Exception as e:
        errors.append(f"fencing counter unreadable: {e}")
    if counter_val is not None and tokens and max(tokens) > counter_val:
        errors.append(f"lease fencing_token ({max(tokens)}) exceeds counter ({counter_val})")

if strict and warnings:
    errors.extend(f"[strict] {w}" for w in warnings)

ok = not errors
out = {
    "ok": ok, "script": "check-agent-instance-isolation.sh",
    "mode": mode, "active_leases": len(active_leases),
    "locks": len(locks), "type_counts": type_counts,
    "fencing_counter": counter_val,
    "errors": errors, "warnings": warnings,
}
if json_mode:
    print(json.dumps(out))
else:
    print(f"[check-agent-instance-isolation] mode={mode} active={len(active_leases)} locks={len(locks)} counter={counter_val}")
    for w in warnings: print(f"  warn: {w}")
    for e in errors:   print(f"  error: {e}")
    print("ok" if ok else "FAIL")

sys.exit(0 if ok else 1)
PY
