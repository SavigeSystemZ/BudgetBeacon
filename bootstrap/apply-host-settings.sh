#!/usr/bin/env bash
# apply-host-settings.sh
#
# S19b — merge meta-managed host-settings (.aiaast.*) into per-app
# preserve-first siblings. Walks the host_settings block in
# _system/host-adapter-manifest.json and applies the per-host strategy:
#
#   claude  — native merge by Claude Code (no file mutation; informational pass)
#   copilot — JSON deep-merge (.aiaast.json → .json) preserving app keys
#   codex   — TOML key-merge (.aiaast.toml → .toml) preserving app keys
#   gemini  — JSON deep-merge
#   windsurf— JSON deep-merge
#   cursor  — JSON deep-merge
#
# Deep-merge semantics:
#   - dict + dict = recursive merge
#   - list  + list  = APP wins (preserve-first list values, append .aiaast
#                     entries that are not present)
#   - scalar + scalar = APP wins; .aiaast value recorded as "shadowed"
#   - missing in app = .aiaast value installed
#
# Actions per host:
#   created    — preserve-first file did not exist; .aiaast content seeded
#   merged     — preserve-first updated with non-conflicting .aiaast keys
#   unchanged  — preserve-first already had everything .aiaast specifies
#   shadowed   — one or more scalars conflicted; .aiaast value did not win
#                (not a failure — preserve-first is the customization surface)
#   skipped    — host status != active OR preserve_first/meta_managed is null
#
# Modes:
#   --dry-run   (default off) — report planned changes; do not write files
#   --json                    — JSON envelope on stdout
#   --target <dir>            — operate on a downstream repo instead of TEMPLATE
#
# Refuses to run inside a parent-template by default (aiaast lib guard);
# pass --allow-template to override (used only by smokes).

set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/lib/aiaast-lib.sh" ]]; then
  # shellcheck source=lib/aiaast-lib.sh
  source "${SCRIPT_DIR}/lib/aiaast-lib.sh" 2>/dev/null || true
fi

TARGET=""
DRY_RUN=0
EMIT_JSON=0
ALLOW_TEMPLATE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) EMIT_JSON=1; shift ;;
    --allow-template) ALLOW_TEMPLATE=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: apply-host-settings.sh [--target DIR] [--dry-run] [--json] [--allow-template]

Merges every active host's meta-managed .aiaast.* policy into its
preserve-first sibling. Per-host deep-merge strategy. See
_system/HOST_SETTINGS_BASELINE.md.
EOF
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  TARGET="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
fi

export AHS_TARGET="${TARGET}"
export AHS_DRY_RUN="${DRY_RUN}"
export AHS_EMIT_JSON="${EMIT_JSON}"
export AHS_ALLOW_TEMPLATE="${ALLOW_TEMPLATE}"

python3 <<'PY'
import json, os, sys
from pathlib import Path

target = Path(os.environ["AHS_TARGET"])
dry_run = os.environ["AHS_DRY_RUN"] == "1"
emit_json = os.environ["AHS_EMIT_JSON"] == "1"
allow_template = os.environ["AHS_ALLOW_TEMPLATE"] == "1"

try:
    import tomllib  # py311+
except ImportError:
    import tomli as tomllib  # type: ignore

# Parent-template guard: refuse to mutate TEMPLATE/* unless --allow-template.
def is_parent_template(root: Path) -> bool:
    sentinel = root / "_system" / ".template-version"
    if not sentinel.exists():
        return False
    # The TEMPLATE root is recognized by having both the sentinel AND
    # the _TEMPLATE_FACTORY/_MOS_TEMPLATE_FACTORY siblings outside it.
    parent = root.parent
    return (parent / "_TEMPLATE_FACTORY").exists() and (root.name == "TEMPLATE")

if is_parent_template(target) and not allow_template:
    msg = f"apply_host_settings_refused: target is parent TEMPLATE ({target}); pass --allow-template if intentional"
    if emit_json:
        print(json.dumps({"ok": False, "result": "apply_host_settings_refused",
                          "reason": "parent_template", "target": str(target)}))
    else:
        print(msg, file=sys.stderr)
    sys.exit(1)

manifest_path = target / "_system/host-adapter-manifest.json"
if not manifest_path.exists():
    if emit_json:
        print(json.dumps({"ok": False, "result": "apply_host_settings_failed",
                          "reason": "manifest_missing"}))
    else:
        print(f"apply_host_settings_failed manifest_missing={manifest_path}", file=sys.stderr)
    sys.exit(1)

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
adapters = manifest.get("host_settings", {}).get("adapters", {})

MARKER = "$aiaast"

def strip_marker(payload):
    """Return a deep-copy of payload with the $aiaast marker block removed."""
    if not isinstance(payload, dict):
        return payload
    out = {k: v for k, v in payload.items() if k != MARKER}
    return out

def deep_merge(app, meta):
    """
    Returns (merged, summary) where summary tracks 'installed', 'shadowed',
    'list_appended'. app is preserve-first (wins on conflict); meta is .aiaast.
    """
    summary = {"installed": [], "shadowed": [], "list_appended": []}

    def _merge(a, m, path):
        if isinstance(a, dict) and isinstance(m, dict):
            out = dict(a)
            for k, mv in m.items():
                if k not in a:
                    out[k] = mv
                    summary["installed"].append(f"{path}{'.' if path else ''}{k}")
                else:
                    out[k] = _merge(a[k], mv, f"{path}{'.' if path else ''}{k}")
            return out
        if isinstance(a, list) and isinstance(m, list):
            extras = [x for x in m if x not in a]
            if extras:
                summary["list_appended"].append({"path": path, "added": extras})
            return list(a) + extras
        # Scalars or type mismatch: app wins.
        if a != m:
            summary["shadowed"].append({"path": path, "app": a, "meta": m})
        return a

    return _merge(app, meta, ""), summary

def write_toml(path: Path, payload: dict, dry: bool):
    """Tiny TOML serializer for the subset we use (sections + scalars + lists)."""
    if dry:
        return
    lines = []
    # Preserve $aiaast section if present (will be re-stripped on next apply).
    # We do NOT carry the marker into the preserve-first file.
    payload = {k: v for k, v in payload.items() if k != MARKER}
    # Header comment marker so operators see it's been touched.
    lines.append("# Generated/updated by bootstrap/apply-host-settings.sh.")
    lines.append("# Per-app preserve-first config. See _system/HOST_SETTINGS_BASELINE.md.")
    lines.append("")
    # Top-level scalars first, then sections.
    top_scalars = {k: v for k, v in payload.items() if not isinstance(v, dict)}
    sections    = {k: v for k, v in payload.items() if isinstance(v, dict)}
    def _emit_scalar(k, v, indent=""):
        if isinstance(v, bool):
            lines.append(f'{indent}{k} = {"true" if v else "false"}')
        elif isinstance(v, (int, float)):
            lines.append(f'{indent}{k} = {v}')
        elif isinstance(v, str):
            esc = v.replace("\\", "\\\\").replace('"', '\\"')
            lines.append(f'{indent}{k} = "{esc}"')
        elif isinstance(v, list):
            items = []
            for x in v:
                if isinstance(x, str):
                    esc = x.replace("\\", "\\\\").replace('"', '\\"')
                    items.append(f'"{esc}"')
                else:
                    items.append(json.dumps(x))
            lines.append(f'{indent}{k} = [{", ".join(items)}]')
        else:
            lines.append(f'{indent}{k} = {json.dumps(v)}')
    for k, v in top_scalars.items():
        _emit_scalar(k, v)
    for sec, body in sections.items():
        lines.append("")
        lines.append(f"[{sec}]")
        for k, v in body.items():
            if isinstance(v, dict):
                # Nested sub-section.
                lines.append("")
                lines.append(f"[{sec}.{k}]")
                for kk, vv in v.items():
                    _emit_scalar(kk, vv)
            else:
                _emit_scalar(k, v)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")

def write_json(path: Path, payload: dict, dry: bool):
    if dry:
        return
    payload = {k: v for k, v in payload.items() if k != MARKER}
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

def load_payload(path: Path, fmt: str):
    text = path.read_text(encoding="utf-8")
    if fmt == "json":
        return json.loads(text)
    if fmt == "toml":
        return tomllib.loads(text)
    return {}

results = []
for name, cfg in sorted(adapters.items()):
    status = cfg.get("status", "")
    fmt = cfg.get("format", "json")
    pf  = cfg.get("preserve_first")
    mm  = cfg.get("meta_managed")
    native = bool(cfg.get("native_merge", False))

    entry = {"name": name, "status": status, "action": "skipped",
             "summary": {}, "preserve_first": pf, "meta_managed": mm}

    if status != "active" or not pf or not mm:
        entry["reason"] = "not_active_or_no_files"
        results.append(entry); continue

    mm_path = target / mm
    pf_path = target / pf
    if not mm_path.exists():
        entry["action"] = "error"; entry["reason"] = f"meta_managed_missing:{mm}"
        results.append(entry); continue

    if native:
        # Claude Code: host layers settings.json + settings.local.json natively.
        # We don't need to mutate preserve-first; the .aiaast file IS the layer.
        entry["action"] = "unchanged"; entry["reason"] = "native_merge"
        results.append(entry); continue

    try:
        meta_payload = load_payload(mm_path, fmt)
    except Exception as e:
        entry["action"] = "error"; entry["reason"] = f"meta_parse_error:{e}"
        results.append(entry); continue

    meta_clean = strip_marker(meta_payload)

    if not pf_path.exists():
        # Seed the preserve-first file with the cleaned meta payload.
        if fmt == "json":
            write_json(pf_path, meta_clean, dry_run)
        else:
            write_toml(pf_path, meta_clean, dry_run)
        entry["action"] = "created" if not dry_run else "would_create"
        results.append(entry); continue

    try:
        app_payload = load_payload(pf_path, fmt)
    except Exception as e:
        entry["action"] = "error"; entry["reason"] = f"app_parse_error:{e}"
        results.append(entry); continue

    merged, summary = deep_merge(app_payload, meta_clean)
    entry["summary"] = {k: v if not isinstance(v, list) else len(v)
                        for k, v in summary.items()}
    entry["summary_detail"] = summary

    if merged == app_payload:
        entry["action"] = "unchanged"
    else:
        if fmt == "json":
            write_json(pf_path, merged, dry_run)
        else:
            write_toml(pf_path, merged, dry_run)
        entry["action"] = ("would_merge" if dry_run else "merged")
        if summary["shadowed"]:
            entry["shadowed"] = True
    results.append(entry)

ok = all(r["action"] != "error" for r in results)
env = {
    "ok": ok,
    "result": "apply_host_settings_ok" if ok else "apply_host_settings_failed",
    "dry_run": dry_run,
    "target": str(target),
    "summary": {
        "total":     len(results),
        "created":   sum(1 for r in results if r["action"] in ("created","would_create")),
        "merged":    sum(1 for r in results if r["action"] in ("merged","would_merge")),
        "unchanged": sum(1 for r in results if r["action"] == "unchanged"),
        "skipped":   sum(1 for r in results if r["action"] == "skipped"),
        "errors":    sum(1 for r in results if r["action"] == "error"),
    },
    "adapters": results,
}

if emit_json:
    print(json.dumps(env, indent=2))
else:
    if ok:
        s = env["summary"]
        print(f"apply_host_settings_ok created={s['created']} merged={s['merged']} "
              f"unchanged={s['unchanged']} skipped={s['skipped']}")
    else:
        print("apply_host_settings_failed", file=sys.stderr)
        for r in results:
            if r["action"] == "error":
                print(f"  {r['name']}: {r.get('reason','')}", file=sys.stderr)

sys.exit(0 if ok else 1)
PY
