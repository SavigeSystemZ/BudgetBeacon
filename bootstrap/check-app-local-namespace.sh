#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage: check-app-local-namespace.sh <repo-root> [--json] [--strict]

Validate app-local namespace artifacts. Behavior depends on _system/.aiast-role.json:

  role = parent-template:
    * .aiast-role.json present and parses
    * app-local-namespace.template.json present and parses
    * schemas/app-local-namespace.schema.json present and is valid JSON Schema
    * no live app-local-namespace.json (would indicate template mis-scaffolded)

  role = downstream-app:
    * .aiast-role.json present
    * app-local-namespace.json present and validates against the schema
    * app_id pattern correct; app_id suffix matches first 8 hex of app_uuid
    * repo_root_realpath equals realpath(<repo-root>)
    * allowed_repo_root equals repo_root_realpath
    * no forbidden_roots entry equals repo_root_realpath
    * namespaces.browser_profile_dir lives under repo_root_realpath
    * all lifecycle.immutable_fields are present in the document

Exit codes:
  0  ok
  1  validation failure
  2  bad arguments
EOF
}

if [[ $# -lt 1 ]]; then usage; exit 2; fi

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

if [[ ! -d "${TARGET}" ]]; then
  if [[ "${JSON_MODE}" -eq 1 ]]; then
    printf '{"ok":false,"script":"check-app-local-namespace.sh","code":"missing_target","message":"target does not exist"}\n'
  else
    echo "target does not exist: ${TARGET}" >&2
  fi
  exit 1
fi

TARGET="$(cd -- "${TARGET}" && pwd)"

python3 - "${TARGET}" "${JSON_MODE}" "${STRICT}" <<'PY'
from __future__ import annotations
import json, os, re, sys
from pathlib import Path

target = Path(sys.argv[1]).resolve()
json_mode = sys.argv[2] == "1"
strict = sys.argv[3] == "1"

role_file       = target / "_system" / ".aiast-role.json"
namespace_file  = target / "_system" / "app-local-namespace.json"
template_file   = target / "_system" / "app-local-namespace.template.json"
schema_file     = target / "_system" / "schemas" / "app-local-namespace.schema.json"

errors: list[str] = []
warnings: list[str] = []
mode = "unknown"

def load_json(p: Path):
    return json.loads(p.read_text())

if not role_file.is_file():
    errors.append(f"missing role sentinel: {role_file}")
else:
    try:
        role_doc = load_json(role_file)
    except Exception as e:
        errors.append(f"role sentinel does not parse as JSON: {e}")
        role_doc = {}
    mode = role_doc.get("role", "unknown")
    if mode not in ("parent-template", "downstream-app"):
        errors.append(f"role sentinel has unknown role: {mode!r}")

if not schema_file.is_file():
    errors.append(f"missing schema: {schema_file}")
else:
    try:
        schema = load_json(schema_file)
        if "$schema" not in schema or "type" not in schema:
            errors.append("schema file does not look like a JSON Schema (missing $schema or type)")
    except Exception as e:
        errors.append(f"schema does not parse: {e}")
        schema = None

if mode == "parent-template":
    if not template_file.is_file():
        errors.append(f"missing template: {template_file}")
    else:
        try:
            tpl = load_json(template_file)
            # every placeholder token must look like __X__
            txt = template_file.read_text()
            for tok in re.findall(r"__[A-Z0-9_]+__", txt):
                if not re.match(r"^__[A-Z][A-Z0-9_]*__$", tok):
                    errors.append(f"template has malformed placeholder: {tok}")
        except Exception as e:
            errors.append(f"template does not parse: {e}")
    if namespace_file.is_file():
        errors.append("parent-template repo has a live app-local-namespace.json — likely mis-scaffolded")

elif mode == "downstream-app":
    if not namespace_file.is_file():
        errors.append(f"missing namespace record: {namespace_file}")
    else:
        try:
            doc = load_json(namespace_file)
        except Exception as e:
            errors.append(f"namespace record does not parse: {e}")
            doc = None
        if doc is not None:
            # schema validation if jsonschema available
            try:
                import jsonschema  # type: ignore
                try:
                    jsonschema.validate(doc, schema)
                except Exception as e:
                    errors.append(f"schema validation failed: {e}")
            except ImportError:
                warnings.append("jsonschema not installed; schema validation skipped (install python3-jsonschema for strict)")

            app_id = doc.get("app_id", "")
            app_uuid = doc.get("app_uuid", "")
            if app_uuid and not app_id.endswith(app_uuid[:8]):
                errors.append(f"app_id suffix does not match first 8 hex of app_uuid")
            real = str(target)
            try:
                real = str(target.resolve())
            except Exception:
                pass
            if doc.get("repo_root_realpath") != real:
                errors.append(f"repo_root_realpath ({doc.get('repo_root_realpath')!r}) does not equal realpath(target) ({real!r})")
            if doc.get("allowed_repo_root") != doc.get("repo_root_realpath"):
                errors.append("allowed_repo_root must equal repo_root_realpath in v1")
            forb = doc.get("forbidden_roots", []) or []
            if doc.get("repo_root_realpath") in forb:
                errors.append("forbidden_roots contains the app's own repo_root_realpath")
            ns = doc.get("namespaces", {})
            bpd = ns.get("browser_profile_dir", "")
            if bpd and not bpd.startswith(doc.get("repo_root_realpath", "<none>")):
                errors.append("namespaces.browser_profile_dir is not under repo_root_realpath")
            for f in (doc.get("lifecycle", {}).get("immutable_fields") or []):
                if f not in doc:
                    errors.append(f"immutable field missing from document: {f}")

if strict and warnings:
    errors.extend(f"[strict] {w}" for w in warnings)

ok = not errors
if json_mode:
    out = {
        "ok": ok,
        "script": "check-app-local-namespace.sh",
        "mode": mode,
        "target": str(target),
        "errors": errors,
        "warnings": warnings,
    }
    print(json.dumps(out))
else:
    print(f"[check-app-local-namespace] mode={mode} target={target}")
    for w in warnings: print(f"  warn: {w}")
    for e in errors:   print(f"  error: {e}")
    print("ok" if ok else "FAIL")

sys.exit(0 if ok else 1)
PY
