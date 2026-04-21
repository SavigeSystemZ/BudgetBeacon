#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BLUEPRINT_DIR="${SCRIPT_DIR}/../_system/starter-blueprints"

usage() {
  cat <<'EOF'
Usage: recommend-starter-blueprint.sh <target-repo> [--write]

Infer an advisory starter-blueprint recommendation from repo-local product truth and runtime signals.
This script never applies a blueprint automatically.
EOF
}

TARGET_REPO=""
WRITE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)
      WRITE=1
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

if [[ -z "${TARGET_REPO}" ]]; then
  usage
  exit 1
fi

PROFILE="${TARGET_REPO}/_system/PROJECT_PROFILE.md"
PRODUCT_BRIEF="${TARGET_REPO}/PRODUCT_BRIEF.md"

for path in "${PROFILE}" "${PRODUCT_BRIEF}"; do
  if [[ ! -f "${path}" ]]; then
    echo "Missing required file: ${path}" >&2
    exit 1
  fi
done

python3 - <<'PY' "${TARGET_REPO}" "${BLUEPRINT_DIR}" "${PROFILE}" "${PRODUCT_BRIEF}" "${WRITE}"
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path

repo_root = Path(sys.argv[1]).resolve()
blueprint_dir = Path(sys.argv[2]).resolve()
profile_path = Path(sys.argv[3]).resolve()
product_brief_path = Path(sys.argv[4]).resolve()
write_enabled = sys.argv[5] == "1"

profile_text = profile_path.read_text()
brief_text = product_brief_path.read_text()

FOUNDATION_PATHS = {
    "mobile/README.md",
    "mobile/flutter/README.md",
    "mobile/flutter/pubspec.yaml",
    "mobile/flutter/lib/main.dart",
    "mobile/flutter/android/app/src/main/AndroidManifest.xml",
    "ai/README.md",
    "ai/llm_config.yaml",
    "ai/chatbot-intents.md",
    "ops/install/README.md",
    "ops/install/install.sh",
    "ops/install/uninstall.sh",
    "ops/install/repair.sh",
    "ops/install/purge.sh",
    "ops/install/lib/runtime-foundation.sh",
    "ops/install/lib/port_allocator.py",
    "ops/env/.env.example",
    "ops/compose/compose.yml",
    "ops/logging/README.md",
    "packaging/README.md",
    "packaging/appimage.yml",
    "packaging/flatpak-manifest.json",
    "packaging/snapcraft.yaml",
    "packaging/signing/README.md",
}

IGNORE_PREFIXES = {
    ".git",
    "_system",
    "bootstrap",
    ".cursor",
    ".github",
    "node_modules",
    ".venv",
    "dist",
    "build",
    "target",
}

PLACEHOLDER_MARKERS = (
    "set once the product shape is specific enough to exclude lookalikes",
    "define the app promise in one clear sentence before major implementation begins",
    "capture the user pain, operator leverage, or market opportunity this app resolves",
    "name the real people or operators who should benefit first",
    "list the core flows the first milestone must prove",
    "record the measurable signal that shows the app is genuinely useful",
    "state what this repo should not try to solve in the first phase",
    "deliberate, differentiated, and product-specific rather than template-generic",
    "fast, clear, low-friction flows with designed states from the first milestone",
    "snappy enough that the first slice feels trustworthy under normal use",
    "clear degraded states, explicit error handling, and no fake capability claims",
    "security-conscious defaults, honest validation claims, and explicit handling of risky actions",
    "manual review required until product framing or repo signals are stronger",
    "review the persisted recommendation, then explicitly choose the blueprint that matches the intended product shape",
    "not yet selected",
    "choose a starter blueprint after the product frame and delivery surfaces are clearer",
    "decide after selecting a starter blueprint",
    "prove one end-to-end user-facing or operator-facing slice with real validation",
    "confirm one real build, launch, test, or smoke path early and keep it passing",
    "starter blueprint, persistence model, deployment targets, packaging expectations, and ai scope",
)

TEXT_EXTENSIONS = {
    ".py",
    ".ts",
    ".tsx",
    ".js",
    ".jsx",
    ".go",
    ".rs",
    ".java",
    ".kt",
    ".graphql",
    ".gql",
    ".proto",
    ".json",
    ".toml",
    ".yaml",
    ".yml",
}


def field(text: str, label: str) -> str:
    match = re.search(rf"^- {re.escape(label)}:[ \t]*(.*)$", text, re.MULTILINE)
    return match.group(1).strip() if match else ""


def replace_label(text: str, label: str, value: str) -> str:
    return re.sub(
        rf"^- {re.escape(label)}:.*$",
        f"- {label}: {value}",
        text,
        count=1,
        flags=re.MULTILINE,
    )


def ensure_build_shape_fields(text: str) -> str:
    labels = [
        "Recommended starter blueprint",
        "Recommendation confidence",
        "Recommendation rationale",
        "Selected starter blueprint",
        "Why this blueprint fits",
        "Planned repo shape",
        "First milestone",
        "Initial validation focus",
        "Next decision gates",
    ]
    missing = [label for label in labels if not re.search(rf"^- {re.escape(label)}:", text, re.MULTILINE)]
    if not missing:
        return text
    anchor = "## Build shape\n\n"
    if anchor not in text:
        return text
    insertion = "".join(f"- {label}:\n" for label in missing)
    return text.replace(anchor, anchor + insertion, 1)


def meaningful(value: str) -> str:
    candidate = " ".join(value.strip().split())
    if not candidate:
        return ""
    lowered = candidate.lower()
    if any(marker in lowered for marker in PLACEHOLDER_MARKERS):
        return ""
    return candidate


def contains_term(text: str, term: str) -> bool:
    normalized = " ".join(text.split()).lower()
    escaped = re.escape(term.lower()).replace(r"\ ", r"\s+")
    pattern = re.compile(rf"(?<![a-z0-9]){escaped}(?![a-z0-9])")
    return bool(pattern.search(normalized))


def has_keywords_in(text: str, *words: str) -> bool:
    return any(contains_term(text, word) for word in words)


def rel(path: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def is_foundation_path(path: Path) -> bool:
    return rel(path) in FOUNDATION_PATHS


def should_ignore(path: Path) -> bool:
    relative = rel(path)
    first = relative.split("/", 1)[0]
    if first in IGNORE_PREFIXES:
        return True
    return False


def iter_repo_files() -> list[Path]:
    files: list[Path] = []
    for path in repo_root.rglob("*"):
        if not path.is_file():
            continue
        if should_ignore(path):
            continue
        files.append(path)
    return files


def package_json() -> dict:
    path = repo_root / "package.json"
    if not path.exists():
        return {}
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def package_has_dependency(name: str) -> bool:
    pkg = package_json()
    deps = {}
    for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        deps.update(pkg.get(key) or {})
    return name in deps


def file_exists(path_str: str) -> bool:
    return (repo_root / path_str).exists()


def has_non_foundation_file(prefix: str, suffix: str | None = None) -> bool:
    base = repo_root / prefix
    if not base.exists():
        return False
    for path in base.rglob("*"):
        if not path.is_file():
            continue
        if is_foundation_path(path):
            continue
        if suffix and path.suffix != suffix:
            continue
        return True
    return False


def find_text(pattern: str) -> bool:
    regex = re.compile(pattern, re.IGNORECASE)
    for path in iter_repo_files():
        if path.suffix not in TEXT_EXTENSIONS:
            continue
        if is_foundation_path(path):
            continue
        try:
            text = path.read_text()
        except Exception:
            continue
        if regex.search(text):
            return True
    return False


def blueprint_titles() -> dict[str, str]:
    titles: dict[str, str] = {}
    for path in sorted(blueprint_dir.glob("*.md")):
        if path.name == "README.md":
            continue
        titles[path.stem] = path.read_text().splitlines()[0].removeprefix("# ").strip()
    return titles


titles = blueprint_titles()
scores: dict[str, int] = {blueprint_id: 0 for blueprint_id in titles}
reasons: dict[str, list[str]] = defaultdict(list)


def add_score(blueprint_id: str, points: int, reason: str) -> None:
    scores[blueprint_id] += points
    reasons[blueprint_id].append(reason)


profile_blob = " ".join(
    filter(
        None,
        [
            meaningful(field(profile_text, "Repo purpose")),
            meaningful(field(profile_text, "Product category")),
            meaningful(field(profile_text, "Primary users")),
            meaningful(field(profile_text, "Main workflows")),
            meaningful(field(profile_text, "Primary success criteria")),
            meaningful(field(profile_text, "Non-goals")),
            meaningful(field(profile_text, "Runtime code roots")),
            meaningful(field(profile_text, "Primary frameworks")),
            meaningful(field(profile_text, "Build tools")),
            meaningful(field(profile_text, "Build entrypoints")),
            meaningful(field(profile_text, "Format")),
            meaningful(field(profile_text, "Lint")),
            meaningful(field(profile_text, "Typecheck")),
            meaningful(field(profile_text, "Unit tests")),
            meaningful(field(profile_text, "Integration tests")),
            meaningful(field(profile_text, "End-to-end or smoke")),
            meaningful(field(profile_text, "Build")),
            meaningful(field(profile_text, "Install / launch verification")),
            meaningful(field(profile_text, "Packaging verification")),
            meaningful(field(profile_text, "Mobile targets")),
            meaningful(field(profile_text, "Mobile release artifacts")),
            meaningful(field(profile_text, "Mobile build flavors")),
        ],
    )
)
brief_blob = " ".join(
    filter(
        None,
        [
            meaningful(field(brief_text, "Product category")),
            meaningful(field(brief_text, "One-line summary")),
            meaningful(field(brief_text, "Why it should exist")),
            meaningful(field(brief_text, "Primary users")),
            meaningful(field(brief_text, "Primary workflows")),
            meaningful(field(brief_text, "Success indicators")),
            meaningful(field(brief_text, "Non-goals")),
            meaningful(field(brief_text, "Planned repo shape")),
            meaningful(field(brief_text, "First milestone")),
        ],
    )
)
intent_blob = f"{profile_blob} {brief_blob}".strip().lower()


def has_keywords(*words: str) -> bool:
    return has_keywords_in(intent_blob, *words)


flutter_frameworks = meaningful(field(profile_text, "Primary frameworks")).lower()
runtime_roots = meaningful(field(profile_text, "Runtime code roots")).lower()
build_entrypoints = meaningful(field(profile_text, "Build entrypoints")).lower()
validation_blob = " ".join(
    filter(
        None,
        [
            meaningful(field(profile_text, "Format")),
            meaningful(field(profile_text, "Lint")),
            meaningful(field(profile_text, "Typecheck")),
            meaningful(field(profile_text, "Unit tests")),
            meaningful(field(profile_text, "Integration tests")),
            meaningful(field(profile_text, "End-to-end or smoke")),
            meaningful(field(profile_text, "Build")),
            meaningful(field(profile_text, "Install / launch verification")),
            meaningful(field(profile_text, "Packaging verification")),
        ],
    )
).lower()
mobile_delivery_blob = " ".join(
    filter(
        None,
        [
            meaningful(field(profile_text, "Mobile targets")),
            meaningful(field(profile_text, "Mobile release artifacts")),
            meaningful(field(profile_text, "Mobile build flavors")),
        ],
    )
).lower()


if package_has_dependency("next") or file_exists("next.config.ts") or file_exists("next.config.js") or file_exists("next.config.mjs"):
    add_score("NEXT_JS_FULLSTACK", 8, "Next.js runtime signals were found in the repo.")
if package_has_dependency("react"):
    add_score("REACT_VITE_TYPESCRIPT", 2, "React dependency detected.")
if file_exists("vite.config.ts") or file_exists("vite.config.js") or file_exists("vite.config.mjs"):
    add_score("REACT_VITE_TYPESCRIPT", 5, "Vite config detected.")
if file_exists("index.html") and not file_exists("package.json") and not file_exists("pyproject.toml") and not file_exists("go.mod") and not file_exists("Cargo.toml"):
    add_score("STATIC_FRONTEND", 6, "Static-site root files exist without an app toolchain.")
if find_text(r"\bfrom fastapi import\b|\bimport fastapi\b"):
    add_score("FASTAPI_API", 8, "FastAPI imports were detected in runtime code.")
if find_text(r"\bgraphene\b|\bgraphql\b|\bapollo-server\b|\b@apollo/server\b|\basync-graphql\b|\bjuniper\b"):
    add_score("GRAPHQL_API", 8, "GraphQL framework or schema signals were detected.")
if find_text(r"\bgrpc\b|\btonic\b|\bgrpcio\b|\b@grpc/grpc-js\b") or any(path.suffix == ".proto" for path in iter_repo_files()):
    add_score("GRPC_SERVICE", 8, "gRPC or protobuf signals were detected.")
if file_exists("go.mod"):
    add_score("GO_SERVICE", 6, "Go module detected.")
if file_exists("Cargo.toml") and file_exists("src/main.rs"):
    add_score("RUST_CLI_TOOL", 4, "Rust CLI entrypoint detected.")
if file_exists("pyproject.toml") and (file_exists("src/__main__.py") or find_text(r"\btyper\b|\bclick\b")):
    add_score("PYTHON_CLI_TOOL", 8, "Python CLI entrypoint or CLI framework detected.")
if find_text(r"\bclap\b"):
    add_score("RUST_CLI_TOOL", 3, "Rust clap dependency or usage detected.")
if find_text(r"\bcelery\b|\brq\b|\bsidekiq\b") or file_exists("workers") or file_exists("worker"):
    add_score("BACKGROUND_WORKER", 8, "Background worker signals were detected.")
if file_exists("alembic.ini") or file_exists("prisma") or file_exists("migrations") or file_exists("diesel.toml"):
    add_score("DATABASE_MIGRATIONS", 7, "Migration tooling or migration roots were detected.")
if package_has_dependency("@tauri-apps/api") or file_exists("src-tauri"):
    add_score("TAURI_DESKTOP", 8, "Tauri signals were detected.")
if file_exists("pubspec.yaml"):
    add_score("FLUTTER_ANDROID_CLIENT", 6, "Flutter project file detected.")
if has_non_foundation_file("mobile/flutter/lib", ".dart"):
    add_score("FLUTTER_ANDROID_CLIENT", 4, "Non-foundation Flutter code exists.")

if has_keywords("frontend", "web app", "dashboard", "browser", "website", "portal", "landing page"):
    add_score("REACT_VITE_TYPESCRIPT", 3, "Product framing points to an interactive frontend surface.")
    add_score("STATIC_FRONTEND", 2, "Product framing points to a browser-facing surface.")
if has_keywords("next.js", "app router", "fullstack web", "server components"):
    add_score("NEXT_JS_FULLSTACK", 4, "Product framing explicitly mentions a Next.js-style fullstack web app.")
if has_keywords("api", "backend", "service", "server"):
    add_score("FASTAPI_API", 2, "Product framing points to an API or service layer.")
    add_score("GO_SERVICE", 1, "Product framing points to a service-oriented repo shape.")
if has_keywords("graphql"):
    add_score("GRAPHQL_API", 4, "Product framing explicitly mentions GraphQL.")
if has_keywords("grpc", "protobuf"):
    add_score("GRPC_SERVICE", 4, "Product framing explicitly mentions gRPC or protobuf.")
if has_keywords("worker", "background job", "scheduler", "queue consumer", "queue", "cron"):
    add_score("BACKGROUND_WORKER", 4, "Product framing points to background execution.")
if has_keywords("migration", "schema evolution", "database migration"):
    add_score("DATABASE_MIGRATIONS", 4, "Product framing points to migration ownership.")
if has_keywords("desktop app", "desktop client", "linux desktop", "tray app", "tauri"):
    add_score("TAURI_DESKTOP", 4, "Product framing points to a desktop application.")
if has_keywords("android", "mobile client", "flutter app", "mobile app"):
    add_score("FLUTTER_ANDROID_CLIENT", 4, "Product framing points to an Android or Flutter client.")
if has_keywords("cli", "command line", "terminal", "shell tool"):
    add_score("PYTHON_CLI_TOOL", 3, "Product framing points to a command-line tool.")
    add_score("RUST_CLI_TOOL", 3, "Product framing points to a command-line tool.")
if has_keywords("python cli", "typer", "click"):
    add_score("PYTHON_CLI_TOOL", 3, "Product framing points specifically to a Python CLI.")
if has_keywords("rust cli", "cargo"):
    add_score("RUST_CLI_TOOL", 3, "Product framing points specifically to a Rust CLI.")

surface_terms = {
    "web": has_keywords("web", "browser", "frontend", "dashboard", "site", "portal"),
    "api": has_keywords("api", "backend", "service", "server"),
    "worker": has_keywords("worker", "background job", "scheduler", "queue"),
    "mobile": has_keywords("mobile", "android", "flutter"),
    "ai": has_keywords("ai", "agent", "assistant", "chatbot", "llm"),
    "packaging": has_keywords("installer", "installation", "packaging", "desktop linux", "distribution"),
}
surface_count = sum(1 for value in surface_terms.values() if value)
if surface_count >= 4 and surface_terms["web"] and surface_terms["api"]:
    add_score(
        "UNIVERSAL_APP_PLATFORM",
        10,
        "Product framing explicitly spans multiple surfaces including web and API concerns.",
    )
elif surface_count >= 3 and surface_terms["web"] and surface_terms["api"] and (surface_terms["worker"] or surface_terms["mobile"] or surface_terms["ai"]):
    add_score(
        "UNIVERSAL_APP_PLATFORM",
        7,
        "Product framing spans several coordinated surfaces beyond a single app shell.",
    )

if file_exists("apps/web") and file_exists("apps/api"):
    add_score("UNIVERSAL_APP_PLATFORM", 8, "Real multi-surface runtime roots exist under apps/.")
if file_exists("apps/worker") or file_exists("worker") or file_exists("workers"):
    add_score("UNIVERSAL_APP_PLATFORM", 3, "A worker surface exists alongside the primary app.")
if has_non_foundation_file("ai"):
    add_score("UNIVERSAL_APP_PLATFORM", 2, "Non-foundation AI runtime files exist.")
if has_non_foundation_file("mobile/flutter"):
    add_score("UNIVERSAL_APP_PLATFORM", 2, "Non-foundation mobile code exists.")

if has_keywords_in(flutter_frameworks, "flutter"):
    add_score("FLUTTER_ANDROID_CLIENT", 4, "Project profile names Flutter as a primary framework.")
if has_keywords_in(runtime_roots, "mobile/flutter", "main.dart") or has_keywords_in(build_entrypoints, "mobile/flutter", "main.dart"):
    add_score("FLUTTER_ANDROID_CLIENT", 3, "Project profile points at mobile/flutter runtime roots or entrypoints.")
if has_keywords_in(validation_blob, "flutter analyze", "flutter test", "flutter build apk", "flutter build appbundle", "flutter pub get"):
    add_score("FLUTTER_ANDROID_CLIENT", 3, "Project profile validation commands target a Flutter Android delivery flow.")
if has_keywords_in(mobile_delivery_blob, "android", "apk", "aab") and has_keywords_in(intent_blob, "android", "mobile", "flutter"):
    add_score("FLUTTER_ANDROID_CLIENT", 2, "Product framing and delivery fields both point to Android mobile release work.")

ranked = sorted(scores.items(), key=lambda item: (-item[1], item[0]))
top_id, top_score = ranked[0]
runner_up_score = ranked[1][1] if len(ranked) > 1 else 0
delta = top_score - runner_up_score

if top_score >= 8 and delta >= 3:
    confidence = "high"
elif top_score >= 5 and delta >= 2:
    confidence = "medium"
elif top_score >= 3:
    confidence = "low"
else:
    confidence = "low"

manual_review = top_score < 5 or confidence == "low"
recommended_value = "manual review required"
reported_id = "manual-review-required"
top_candidate = top_id if top_score > 0 else "none"

top_reasons = reasons.get(top_id, [])
if manual_review:
    rationale = (
        "No single starter blueprint is dominant yet. "
        + (
            f"Top candidate: {top_id} - {titles[top_id]}. "
            if top_score > 0
            else ""
        )
        + (
            f"Current signals: {'; '.join(top_reasons[:3])}. "
            if top_reasons
            else "Current signals are too weak or too generic. "
        )
        + "Refine PRODUCT_BRIEF.md or add real runtime signals, then review the recommendation again."
    )
else:
    recommended_value = f"{top_id} - {titles[top_id]}"
    reported_id = top_id
    alternatives = [f"{blueprint_id} ({score})" for blueprint_id, score in ranked[1:3] if score > 0]
    rationale = " ".join(
        filter(
            None,
            [
                f"Best fit: {top_id} - {titles[top_id]}.",
                "Signals: " + "; ".join(top_reasons[:3]) + "." if top_reasons else "",
                "Top alternatives: " + ", ".join(alternatives) + "." if alternatives else "",
            ],
        )
    )

ranked_output = ",".join(f"{blueprint_id}:{score}" for blueprint_id, score in ranked if score > 0)

if write_enabled:
    updated = ensure_build_shape_fields(brief_text)
    updated = replace_label(updated, "Recommended starter blueprint", recommended_value)
    updated = replace_label(updated, "Recommendation confidence", confidence)
    updated = replace_label(updated, "Recommendation rationale", rationale)
    product_brief_path.write_text(updated)
    print(f"Wrote starter blueprint recommendation to {product_brief_path}")

print("starter_blueprint_recommendation")
print(f"recommended_blueprint={reported_id}")
print(f"recommendation_confidence={confidence}")
print(f"top_candidate={top_candidate}")
print(f"ranked_blueprints={ranked_output}")
print(f"recommendation_rationale={rationale}")
PY
