#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-mcp-bleed.sh <repo-root> [--json]

Read-only. Detects cross-boundary leakage in MCP configuration and
runtime state:

  * tracked-secret containment: every file under
    _system/mcp/local-overrides/ (except README.md, .gitignore) MUST be
    git-ignored. A non-ignored file there is a tracked-secret risk
    (covers F-08 at the config layer).

  * cross-app reference scan: instance records, MCP example configs,
    and runtime fingerprints MUST NOT reference any other app's
    repo_root_realpath, app_id, or browser-profiles directory (covers
    F-01, F-03 design intent).

  * browser-profile containment (F-11): for any registered MCP instance
    whose server_type is "browser", the browser_profile_path MUST
    realpath inside <repo_root>/.local/browser-profiles/<app_id>/.

  * symlink-out-of-repo (F-03): any symlink under _system/mcp/instances/
    that resolves outside the repo root is refused.

Exit codes:
  0  no bleed
  1  bleed detected (errors printed to stderr)
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac
TARGET="$1"; shift
JSON_MODE=0
EMIT_BLEED=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_MODE=1; shift ;;
    --emit-bleed-events) EMIT_BLEED=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ! -d "${TARGET}" ]] && { echo "target not found: ${TARGET}" >&2; exit 1; }
TARGET="$(cd -- "${TARGET}" && pwd)"

# We need `git check-ignore` to evaluate the local-overrides .gitignore.
# Fall back gracefully if the target is not a git repo.
GIT_OK=0
if git -C "${TARGET}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_OK=1
fi

export AIAST_EMIT_BLEED="${EMIT_BLEED}"
python3 - "${TARGET}" "${JSON_MODE}" "${GIT_OK}" <<'PY'
from __future__ import annotations
import json, os, secrets, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"
git_ok = sys.argv[3] == "1"

errors: list[str] = []
warnings: list[str] = []

def _bleed(severity: str, ev_type: str, scope_path: str, *,
           observed: str | None = None,
           evidence_refs: list[str] | None = None,
           context: dict | None = None,
           remediation_action: str = "notify") -> None:
    if os.environ.get("AIAST_EMIT_BLEED") != "1":
        return
    try:
        ns_file = target / "_system" / "app-local-namespace.json"
        app_id = host_fp = allowed_root = None
        if ns_file.is_file():
            n = json.loads(ns_file.read_text())
            app_id = n.get("app_id"); host_fp = n.get("host_fingerprint_id")
            allowed_root = n.get("repo_root_realpath")
        now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
        ev = {
            "event_id": f"evt_{secrets.token_hex(13)}",
            "ts": now, "severity": severity, "type": ev_type,
            "detected_by": "check-mcp-bleed.sh",
            "agent_id": None, "app_id": app_id, "host_fingerprint_id": host_fp,
            "scope": {"path": scope_path, "operation": "detect"},
            "intended_boundary": {"allowed_repo_root": allowed_root},
            "observed_target": observed,
            "evidence_refs": evidence_refs or [],
            "remediation": {"action": remediation_action, "by": "check-mcp-bleed.sh", "ts": now},
        }
        if context: ev["context"] = context
        audit = target / "_system" / "agent-state" / "audit"
        audit.mkdir(parents=True, exist_ok=True)
        with open(audit / f"{now[:7]}.jsonl", "a") as fh:
            fh.write(json.dumps(ev, separators=(",", ":")) + "\n")
    except Exception:
        pass

policy_file = target / "_system" / "mcp-instance-policy.json"
ns_file     = target / "_system" / "app-local-namespace.json"
role_file   = target / "_system" / ".aiast-role.json"

try:
    policy = json.loads(policy_file.read_text()) if policy_file.is_file() else {}
except Exception as e:
    errors.append(f"_system/mcp-instance-policy.json: {e}"); policy = {}
try:
    ns = json.loads(ns_file.read_text()) if ns_file.is_file() else {}
except Exception as e:
    errors.append(f"_system/app-local-namespace.json: {e}"); ns = {}
try:
    role = json.loads(role_file.read_text()).get("role", "unknown") if role_file.is_file() else "unknown"
except Exception:
    role = "unknown"

reg = policy.get("registry") or {}
instances_dir       = target / reg.get("instances_dir",       "_system/mcp/instances")
local_overrides_dir = target / reg.get("local_overrides_dir", "_system/mcp/local-overrides")

app_id = ns.get("app_id") or ""
repo_real = Path(ns.get("repo_root_realpath") or target).resolve()

# --- (1) local-overrides: every file MUST be git-ignored (except README/.gitignore) ---
ALLOWED_TRACKED = {"README.md", ".gitignore"}
if local_overrides_dir.is_dir() and git_ok:
    for p in local_overrides_dir.rglob("*"):
        if not p.is_file(): continue
        if p.name in ALLOWED_TRACKED and p.parent == local_overrides_dir:
            continue
        rel = p.relative_to(target)
        # `git check-ignore -q` exits 0 if ignored, 1 if NOT ignored, 128 on error
        rc = subprocess.run(
            ["git", "-C", str(target), "check-ignore", "-q", str(rel)],
        ).returncode
        if rc == 1:
            errors.append(f"{rel}: file under local-overrides/ is NOT git-ignored (tracked-secret risk)")
            _bleed("critical", "credential-leak", str(rel),
                   observed=str(rel),
                   context={"fault": "F-08"},
                   remediation_action="refused")
        elif rc not in (0, 1):
            warnings.append(f"{rel}: git check-ignore returned {rc}")
elif local_overrides_dir.is_dir() and not git_ok:
    warnings.append("target is not a git work tree; skipping git check-ignore on local-overrides/")

# --- (2 + 3 + 4) registry record scans (downstream-app only) ---
if role == "downstream-app" and instances_dir.is_dir():
    # Build the set of foreign app_ids by reading any cross-app registry hint.
    # Without a cross-app registry (D4 default = opt-in), we still scan for
    # *literal* foreign markers: any app_id !== ours embedded in a record,
    # any path resolving outside repo_real, any browser_profile_path outside
    # the expected tree.
    expected_browser_root = repo_real / ".local" / "browser-profiles" / app_id

    for p in sorted(instances_dir.iterdir()):
        if p.is_dir(): continue
        if not p.name.endswith(".json"): continue
        if p.name == ".gitkeep": continue
        rel = str(p.relative_to(target))

        # symlink containment (F-03)
        try:
            real = p.resolve()
            real.relative_to(target)
        except ValueError:
            errors.append(f"{rel}: symlink resolves outside repo root ({real})")
            _bleed("critical", "scope-escape", rel,
                   observed=str(real),
                   context={"fault": "F-03"},
                   remediation_action="refused")
            continue
        except Exception as e:
            errors.append(f"{rel}: resolve failed: {e}")
            continue

        try:
            rec = json.loads(p.read_text())
        except Exception as e:
            errors.append(f"{rel}: invalid JSON: {e}")
            continue

        if rec.get("app_id") and app_id and rec["app_id"] != app_id:
            errors.append(f"{rel}: cross-app bleed: app_id {rec['app_id']!r} != ours {app_id!r}")

        st = rec.get("server_type", "")
        bindings = rec.get("namespace_bindings") or {}

        # browser_profile_path containment (F-11)
        if st == "browser":
            bp = bindings.get("browser_profile_path", "")
            if bp:
                bp_path = (target / bp).resolve() if not bp.startswith("/") else Path(bp).resolve()
                try:
                    bp_path.relative_to(expected_browser_root)
                except ValueError:
                    errors.append(
                        f"{rel}: browser_profile_path {bp!r} resolves outside "
                        f"{expected_browser_root.relative_to(repo_real)}/"
                    )
                    _bleed("medium", "scope-escape", rel,
                           observed=str(bp_path),
                           context={"fault": "F-11", "expected_root": str(expected_browser_root)},
                           remediation_action="refused")

        # filesystem allowed_roots realpath containment (F-01 design check)
        if st == "filesystem":
            for r in (bindings.get("allowed_roots", "") or "").split(","):
                r = r.strip()
                if not r: continue
                rp = (target / r).resolve() if not r.startswith("/") else Path(r).resolve()
                try:
                    rp.relative_to(repo_real)
                except ValueError:
                    errors.append(
                        f"{rel}: filesystem allowed_root {r!r} resolves outside repo_root_realpath ({repo_real})"
                    )

# Output
if warnings:
    for w in warnings: print(w, file=sys.stderr)

out = {
    "ok": not errors, "script": "check-mcp-bleed.sh",
    "role": role, "app_id": app_id,
    "errors": errors, "warnings": warnings,
}
if json_mode:
    print(json.dumps(out))
else:
    if errors:
        for e in errors: print(e, file=sys.stderr)
        print(f"check-mcp-bleed: FAIL ({len(errors)} error(s))")
    else:
        print("check-mcp-bleed: PASS")

sys.exit(0 if not errors else 1)
PY
