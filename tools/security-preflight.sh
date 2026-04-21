#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

required_files=(
  "ops/env/.env.example"
  "ops/compose/compose.yml"
  "docs/security/architecture.md"
  "docs/security/backend-inventory.md"
  "docs/security/validation.md"
  "docs/security/rollback.md"
  "registry/ports.yaml"
  "registry/backend-assignments.yaml"
)

for rel in "${required_files[@]}"; do
  if [[ ! -f "${ROOT_DIR}/${rel}" ]]; then
    echo "missing required security surface: ${rel}" >&2
    exit 1
  fi
done

python3 "${ROOT_DIR}/tools/check-port-collisions.py" "${ROOT_DIR}" >/dev/null

python3 - <<'PY' "${ROOT_DIR}"
from __future__ import annotations

import re
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
env_path = root / "ops" / "env" / ".env.example"
compose_path = root / "ops" / "compose" / "compose.yml"

env_text = env_path.read_text()
compose_text = compose_path.read_text()
errors: list[str] = []

def env_value(key: str) -> str:
    match = re.search(rf"^{re.escape(key)}=(.*)$", env_text, re.MULTILINE)
    return match.group(1).strip() if match else ""

for key in (
    "REDIS_URL",
    "REDIS_HOST",
    "REDIS_PORT",
    "REDIS_USERNAME",
    "REDIS_PASSWORD",
    "PUBLISH_REDIS_PORT",
    "REDIS_HOST_BIND",
):
    if not env_value(key):
        errors.append(f"missing backend env placeholder: {key}")

if env_value("PUBLISH_REDIS_PORT") != "false":
    errors.append("PUBLISH_REDIS_PORT must default to false")
if env_value("PUBLISH_POSTGRES_PORT") != "false":
    errors.append("PUBLISH_POSTGRES_PORT must default to false")

exec_start = env_value("APP_EXEC_START")
if "http.server" in exec_start and "--bind" not in exec_start:
    errors.append("APP_EXEC_START must carry an explicit bind flag")

for service_name in ("postgres", "redis", "dragonfly", "minio"):
    match = re.search(rf"(?ms)^  {service_name}:\n(.*?)(?=^  [a-zA-Z0-9_-]+:|\Z)", compose_text)
    if not match:
        continue
    block = match.group(1)
    if re.search(r"(?m)^\s+ports:\s*$", block):
        errors.append(f"internal backend `{service_name}` is host-published by default")

code_hits: list[str] = []
for path in root.rglob("*"):
    if not path.is_file():
        continue
    rel = str(path.relative_to(root))
    if rel.startswith(("docs/", "_system/", "bootstrap/", "ops/env/", "ops/install/", "ops/compose/", "tools/", "registry/")):
        continue
    if path.suffix not in {".py", ".ts", ".tsx", ".js", ".jsx", ".json", ".yaml", ".yml", ".toml", ".env"}:
        continue
    text = path.read_text(errors="ignore")
    if "127.0.0.1" in text or "localhost" in text:
        code_hits.append(rel)

if code_hits:
    errors.append("hardcoded loopback backend references outside env/docs: " + ", ".join(sorted(code_hits)[:10]))

if errors:
    for error in errors:
        print(error, file=sys.stderr)
    raise SystemExit(1)
PY

echo "security_preflight_ok"
