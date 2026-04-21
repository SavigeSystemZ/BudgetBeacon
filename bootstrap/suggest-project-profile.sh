#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: suggest-project-profile.sh <target-repo> [--write] [--overwrite]
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

TARGET_REPO=""
WRITE=0
OVERWRITE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --write)
      WRITE=1
      shift
      ;;
    --overwrite)
      OVERWRITE=1
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

if [[ ! -f "${PROFILE}" ]]; then
  echo "Missing project profile: ${PROFILE}" >&2
  exit 1
fi

extract_selected_blueprint() {
  local target="$1"
  local brief="${target}/PRODUCT_BRIEF.md"
  if [[ ! -f "${brief}" ]]; then
    return 0
  fi

  sed -n 's/^- Selected starter blueprint:[[:space:]]*\([A-Z0-9_][A-Z0-9_]*\).*/\1/p' "${brief}" | head -n 1
}

SELECTED_BLUEPRINT="$(extract_selected_blueprint "${TARGET_REPO}")"

join_by() {
  local sep="$1"
  shift || true
  local first=1
  for value in "$@"; do
    [[ -z "${value}" ]] && continue
    if [[ ${first} -eq 1 ]]; then
      printf '%s' "${value}"
      first=0
    else
      printf '%s%s' "${sep}" "${value}"
    fi
  done
}

add_unique() {
  local name="$1"
  local value="$2"
  [[ -z "${value}" ]] && return 0
  eval "local current=(\"\${${name}[@]-}\")"
  local item
  for item in "${current[@]}"; do
    [[ "${item}" == "${value}" ]] && return 0
  done
  eval "${name}+=(\"\${value}\")"
}

detect_paths() {
  local target="$1"
  shift
  local found=()
  local rel
  for rel in "$@"; do
    if [[ -e "${target}/${rel}" ]]; then
      found+=("${rel}")
    fi
  done
  join_by ", " "${found[@]}"
}

contains_files() {
  local target="$1"
  shift
  local rel
  for rel in "$@"; do
    if [[ -e "${target}/${rel}" ]]; then
      return 0
    fi
  done
  return 1
}

contains_glob() {
  local target="$1"
  local pattern="$2"
  if find "${target}" \
    -type f \
    -path "${pattern}" \
    ! -path "${target}/_system/*" \
    ! -path "${target}/bootstrap/*" \
    ! -path "${target}/.cursor/*" \
    ! -path "${target}/node_modules/*" \
    ! -path "${target}/.venv/*" \
    ! -path "${target}/dist/*" \
    ! -path "${target}/build/*" \
    ! -path "${target}/target/*" \
    ! -path "${target}/ops/*" \
    ! -path "${target}/packaging/*" \
    ! -path "${target}/mobile/*" \
    ! -path "${target}/ai/*" \
    ! -path "${target}/.git/*" \
    | head -n 1 | grep -q .; then
    return 0
  fi
  return 1
}

has_runtime_file() {
  local target="$1"
  local pattern="$2"
  if find "${target}" \
    -type f \
    -name "${pattern}" \
    ! -path "${target}/_system/*" \
    ! -path "${target}/bootstrap/*" \
    ! -path "${target}/.cursor/*" \
    ! -path "${target}/node_modules/*" \
    ! -path "${target}/.venv/*" \
    ! -path "${target}/dist/*" \
    ! -path "${target}/build/*" \
    ! -path "${target}/target/*" \
    ! -path "${target}/ops/*" \
    ! -path "${target}/packaging/*" \
    ! -path "${target}/mobile/*" \
    ! -path "${target}/ai/*" \
    ! -path "${target}/.git/*" \
    | head -n 1 | grep -q .; then
    return 0
  fi
  return 1
}

repo_has_text() {
  local target="$1"
  local pattern="$2"
  if rg -n \
    -g '!ops/**' \
    -g '!packaging/**' \
    -g '!mobile/**' \
    -g '!ai/**' \
    -g '*.py' \
    -g '*.ts' \
    -g '*.tsx' \
    -g '*.js' \
    -g '*.jsx' \
    -g '*.go' \
    -g '*.rs' \
    -g '*.rb' \
    -g '*.java' \
    -g '*.kt' \
    -g '*.proto' \
    -g '*.graphql' \
    -g '*.gql' \
    -g 'package.json' \
    -g 'pyproject.toml' \
    -g 'Cargo.toml' \
    -g 'go.mod' \
    -g 'Gemfile' \
    -g 'build.gradle' \
    -g 'build.gradle.kts' \
    -g 'pom.xml' \
    "${pattern}" "${target}" >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

package_json_value() {
  local target="$1"
  local expression="$2"
  if [[ ! -f "${target}/package.json" ]]; then
    return 1
  fi

  python3 - <<'PY' "${target}/package.json" "${expression}"
import json
import sys
from pathlib import Path

pkg_path = Path(sys.argv[1])
expression = sys.argv[2]
pkg = json.loads(pkg_path.read_text())

def deps():
    merged = {}
    for key in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
        merged.update(pkg.get(key) or {})
    return merged

def has_script(name: str) -> bool:
    return bool((pkg.get("scripts") or {}).get(name))

def has_dependency(name: str) -> bool:
    return name in deps()

value = ""

if expression.startswith("hasScript:"):
    value = "yes" if has_script(expression.split(":", 1)[1]) else ""
elif expression.startswith("hasDependency:"):
    value = "yes" if has_dependency(expression.split(":", 1)[1]) else ""
elif expression == "bin":
    value = "yes" if pkg.get("bin") else ""
elif expression == "engines.node":
    value = (pkg.get("engines") or {}).get("node", "")

if value:
    print(value, end="")
PY
}

declare -a languages
declare -a package_managers
declare -a build_tools
declare -a runtime_envs
declare -a frameworks
declare -a supported_envs
declare -a deployment_targets
declare -a packaging_targets
declare -a native_package_targets
declare -a universal_package_targets
declare -a system_dependencies
declare -a release_artifacts
declare -a components

format_cmd=""
lint_cmd=""
typecheck_cmd=""
unit_tests_cmd=""
integration_tests_cmd=""
e2e_cmd=""
build_cmd=""
launch_cmd=""
packaging_cmd=""
default_ports=""
bind_model=""
service_model=""
migration_model=""
minimum_runtime_versions=""

if contains_files "${TARGET_REPO}" "package.json"; then
  add_unique runtime_envs "Node.js"
fi
if contains_files "${TARGET_REPO}" "pyproject.toml" "requirements.txt" "uv.lock"; then
  add_unique runtime_envs "Python"
fi
if contains_files "${TARGET_REPO}" "Cargo.toml"; then
  add_unique runtime_envs "Rust"
fi
if contains_files "${TARGET_REPO}" "go.mod"; then
  add_unique runtime_envs "Go"
fi
if contains_files "${TARGET_REPO}" "build.gradle" "build.gradle.kts" "pom.xml"; then
  add_unique runtime_envs "JVM"
fi
if contains_files "${TARGET_REPO}" "pubspec.yaml"; then
  add_unique runtime_envs "Flutter"
fi
if contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj"; then
  add_unique runtime_envs ".NET"
fi
if contains_files "${TARGET_REPO}" "Gemfile"; then
  add_unique runtime_envs "Ruby"
fi
if contains_files "${TARGET_REPO}" "index.html" && ! contains_files "${TARGET_REPO}" "package.json" "pyproject.toml" "requirements.txt" "uv.lock"; then
  add_unique runtime_envs "Browser / static site"
fi
if contains_files "${TARGET_REPO}" "Dockerfile" "docker-compose.yml" "compose.yml"; then
  add_unique runtime_envs "Container"
fi

if contains_files "${TARGET_REPO}" "package-lock.json"; then
  add_unique package_managers "npm"
elif contains_files "${TARGET_REPO}" "pnpm-lock.yaml"; then
  add_unique package_managers "pnpm"
elif contains_files "${TARGET_REPO}" "yarn.lock"; then
  add_unique package_managers "yarn"
elif contains_files "${TARGET_REPO}" "bun.lockb" "bun.lock"; then
  add_unique package_managers "bun"
elif contains_files "${TARGET_REPO}" "package.json"; then
  add_unique package_managers "npm (lockfile not yet committed)"
fi

if contains_files "${TARGET_REPO}" "uv.lock"; then
  add_unique package_managers "uv"
elif contains_files "${TARGET_REPO}" "poetry.lock"; then
  add_unique package_managers "poetry"
elif contains_files "${TARGET_REPO}" "requirements.txt"; then
  add_unique package_managers "pip"
elif contains_files "${TARGET_REPO}" "pyproject.toml"; then
  add_unique package_managers "pyproject-based Python packaging"
fi

contains_files "${TARGET_REPO}" "Cargo.lock" "Cargo.toml" && add_unique package_managers "cargo"
contains_files "${TARGET_REPO}" "go.mod" && add_unique package_managers "go modules"
contains_files "${TARGET_REPO}" "Gemfile.lock" "Gemfile" && add_unique package_managers "bundler"
contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj" && add_unique package_managers "dotnet"
contains_files "${TARGET_REPO}" "gradlew" "build.gradle" "build.gradle.kts" && add_unique package_managers "gradle"
contains_files "${TARGET_REPO}" "pom.xml" && add_unique package_managers "maven"
contains_files "${TARGET_REPO}" "pubspec.yaml" && add_unique package_managers "flutter pub"

has_runtime_file "${TARGET_REPO}" '*.ts' || has_runtime_file "${TARGET_REPO}" '*.tsx' && add_unique languages "TypeScript"
has_runtime_file "${TARGET_REPO}" '*.js' || has_runtime_file "${TARGET_REPO}" '*.jsx' && add_unique languages "JavaScript"
has_runtime_file "${TARGET_REPO}" '*.py' && add_unique languages "Python"
has_runtime_file "${TARGET_REPO}" '*.rs' && add_unique languages "Rust"
has_runtime_file "${TARGET_REPO}" '*.go' && add_unique languages "Go"
has_runtime_file "${TARGET_REPO}" '*.java' && add_unique languages "Java"
has_runtime_file "${TARGET_REPO}" '*.kt' && add_unique languages "Kotlin"
has_runtime_file "${TARGET_REPO}" '*.cs' && add_unique languages "C#"
has_runtime_file "${TARGET_REPO}" '*.rb' && add_unique languages "Ruby"
has_runtime_file "${TARGET_REPO}" '*.html' && add_unique languages "HTML"
has_runtime_file "${TARGET_REPO}" '*.css' && add_unique languages "CSS"

contains_files "${TARGET_REPO}" "vite.config.ts" "vite.config.js" "vite.config.mjs" && add_unique build_tools "Vite"
contains_files "${TARGET_REPO}" "tsconfig.json" && add_unique build_tools "TypeScript compiler"
contains_files "${TARGET_REPO}" "pyproject.toml" && add_unique build_tools "Python project tooling"
contains_files "${TARGET_REPO}" "Cargo.toml" && add_unique build_tools "Cargo"
contains_files "${TARGET_REPO}" "go.mod" && add_unique build_tools "Go toolchain"
contains_files "${TARGET_REPO}" "build.gradle" "build.gradle.kts" && add_unique build_tools "Gradle"
contains_files "${TARGET_REPO}" "pom.xml" && add_unique build_tools "Maven"
(contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj") && add_unique build_tools ".NET SDK"
contains_files "${TARGET_REPO}" "Gemfile" && add_unique build_tools "Bundler"
contains_files "${TARGET_REPO}" "Dockerfile" && add_unique build_tools "Docker"
contains_files "${TARGET_REPO}" "pubspec.yaml" && add_unique build_tools "Flutter"
if contains_files "${TARGET_REPO}" "index.html" && ! contains_files "${TARGET_REPO}" "package.json"; then
  add_unique build_tools "Static assets"
fi

[[ "$(package_json_value "${TARGET_REPO}" "hasDependency:react" || true)" == "yes" ]] && add_unique frameworks "React"
[[ "$(package_json_value "${TARGET_REPO}" "hasDependency:vue" || true)" == "yes" ]] && add_unique frameworks "Vue"
[[ "$(package_json_value "${TARGET_REPO}" "hasDependency:next" || true)" == "yes" ]] && add_unique frameworks "Next.js"
[[ "$(package_json_value "${TARGET_REPO}" "hasDependency:electron" || true)" == "yes" ]] && add_unique frameworks "Electron"
[[ "$(package_json_value "${TARGET_REPO}" "hasDependency:@tauri-apps/api" || true)" == "yes" ]] && add_unique frameworks "Tauri"
contains_files "${TARGET_REPO}" "pubspec.yaml" && add_unique frameworks "Flutter"
repo_has_text "${TARGET_REPO}" 'from fastapi import|import fastapi' && add_unique frameworks "FastAPI"
repo_has_text "${TARGET_REPO}" 'graphene|graphql|apollo-server|@apollo/server|async-graphql|juniper' && add_unique frameworks "GraphQL"
repo_has_text "${TARGET_REPO}" 'grpc|tonic|grpcio|@grpc/grpc-js' && add_unique frameworks "gRPC"
repo_has_text "${TARGET_REPO}" 'celery|rq|sidekiq' && add_unique frameworks "Background worker"
if contains_files "${TARGET_REPO}" "index.html" && [[ -z "$(join_by ", " "${frameworks[@]-}")" ]]; then
  add_unique frameworks "No framework / static site"
fi

contains_files "${TARGET_REPO}" "frontend/" "web/" && add_unique components "frontend"
contains_files "${TARGET_REPO}" "backend/" "api/" "server/" && add_unique components "backend"
contains_files "${TARGET_REPO}" "workers/" "worker/" && add_unique components "workers"
contains_files "${TARGET_REPO}" "packages/" "libs/" && add_unique components "packages"
contains_files "${TARGET_REPO}" "services/" && add_unique components "services"
contains_files "${TARGET_REPO}" "apps/" && add_unique components "apps"
contains_files "${TARGET_REPO}" "android/" && add_unique components "mobile"
if [[ -z "$(join_by ", " "${components[@]-}")" ]]; then
  if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Next.js"* ]]; then
    add_unique components "fullstack app"
  elif [[ "$(join_by ", " "${frameworks[@]-}")" == *"React"* || "$(join_by ", " "${frameworks[@]-}")" == *"Vue"* ]]; then
    add_unique components "frontend app"
  elif [[ "$(join_by ", " "${frameworks[@]-}")" == *"FastAPI"* || "$(join_by ", " "${frameworks[@]-}")" == *"GraphQL"* || "$(join_by ", " "${frameworks[@]-}")" == *"gRPC"* ]]; then
    add_unique components "backend service"
  elif [[ "$(package_json_value "${TARGET_REPO}" "bin" || true)" == "yes" || -f "${TARGET_REPO}/src/__main__.py" || -f "${TARGET_REPO}/src/main.rs" || -d "${TARGET_REPO}/cmd" ]]; then
    add_unique components "CLI"
  fi
fi

case "${SELECTED_BLUEPRINT}" in
  NEXT_JS_FULLSTACK)
    add_unique languages "TypeScript"
    add_unique runtime_envs "Node.js"
    add_unique package_managers "npm"
    add_unique build_tools "TypeScript compiler"
    add_unique frameworks "Next.js"
    add_unique frameworks "React"
    add_unique components "fullstack app"
    [[ -z "${default_ports}" ]] && default_ports="3000"
    ;;
  REACT_VITE_TYPESCRIPT)
    add_unique languages "TypeScript"
    add_unique runtime_envs "Node.js"
    add_unique package_managers "npm"
    add_unique build_tools "Vite"
    add_unique build_tools "TypeScript compiler"
    add_unique frameworks "React"
    add_unique components "frontend app"
    [[ -z "${default_ports}" ]] && default_ports="5173"
    ;;
  STATIC_FRONTEND)
    add_unique languages "HTML"
    add_unique languages "CSS"
    add_unique runtime_envs "Browser / static site"
    add_unique components "frontend app"
    ;;
  FASTAPI_API)
    add_unique languages "Python"
    add_unique runtime_envs "Python"
    add_unique package_managers "pyproject-based Python packaging"
    add_unique build_tools "Python project tooling"
    add_unique frameworks "FastAPI"
    add_unique components "backend service"
    [[ -z "${default_ports}" ]] && default_ports="8000"
    ;;
  PYTHON_CLI_TOOL)
    add_unique languages "Python"
    add_unique runtime_envs "Python"
    add_unique package_managers "pyproject-based Python packaging"
    add_unique build_tools "Python project tooling"
    add_unique components "CLI"
    ;;
  FLUTTER_ANDROID_CLIENT)
    add_unique runtime_envs "Flutter"
    add_unique package_managers "flutter pub"
    add_unique build_tools "Flutter"
    add_unique frameworks "Flutter"
    add_unique components "mobile"
    ;;
  UNIVERSAL_APP_PLATFORM)
    add_unique languages "TypeScript"
    add_unique languages "Python"
    add_unique runtime_envs "Node.js"
    add_unique runtime_envs "Python"
    add_unique package_managers "npm"
    add_unique package_managers "pyproject-based Python packaging"
    add_unique build_tools "TypeScript compiler"
    add_unique build_tools "Python project tooling"
    add_unique components "frontend"
    add_unique components "backend"
    add_unique components "workers"
    add_unique components "mobile"
    [[ -z "${default_ports}" ]] && default_ports="3000"
    ;;
esac

if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Electron"* || "$(join_by ", " "${frameworks[@]-}")" == *"Tauri"* ]]; then
  add_unique supported_envs "desktop"
fi
if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Flutter"* || "$(join_by ", " "${components[@]-}")" == *"mobile"* ]]; then
  add_unique supported_envs "Android"
fi
if [[ "$(join_by ", " "${components[@]-}")" == *"backend"* || "$(join_by ", " "${components[@]-}")" == *"service"* || "$(join_by ", " "${frameworks[@]-}")" == *"FastAPI"* || "$(join_by ", " "${frameworks[@]-}")" == *"GraphQL"* || "$(join_by ", " "${frameworks[@]-}")" == *"gRPC"* ]]; then
  add_unique supported_envs "server"
fi
if [[ "$(join_by ", " "${components[@]-}")" == *"CLI"* ]]; then
  add_unique supported_envs "CLI"
fi
if contains_files "${TARGET_REPO}" "Dockerfile" "docker-compose.yml" "compose.yml"; then
  add_unique supported_envs "container"
  add_unique deployment_targets "container"
fi
if contains_files "${TARGET_REPO}" "k8s/" "helm/" "infra/k8s/" "terraform/" "ansible/"; then
  add_unique deployment_targets "infrastructure-managed"
fi
if [[ "$(join_by ", " "${supported_envs[@]-}")" == *"server"* ]]; then
  add_unique deployment_targets "Linux host"
fi
if [[ "$(join_by ", " "${supported_envs[@]-}")" == *"desktop"* ]]; then
  add_unique deployment_targets "desktop Linux"
fi
if [[ "$(join_by ", " "${supported_envs[@]-}")" == *"Android"* ]]; then
  add_unique deployment_targets "Android"
fi

if contains_files "${TARGET_REPO}" "pyproject.toml" "requirements.txt" "uv.lock"; then
  add_unique packaging_targets "wheel"
  add_unique packaging_targets "sdist"
  add_unique native_package_targets ".deb"
  add_unique native_package_targets ".rpm"
  add_unique release_artifacts "python distributions"
fi
if contains_files "${TARGET_REPO}" "Cargo.toml"; then
  add_unique packaging_targets "native binary"
  add_unique native_package_targets ".deb"
  add_unique native_package_targets ".rpm"
  add_unique release_artifacts "release binary"
fi
if contains_files "${TARGET_REPO}" "go.mod"; then
  add_unique packaging_targets "native binary"
  add_unique native_package_targets ".deb"
  add_unique native_package_targets ".rpm"
  add_unique release_artifacts "release binary"
fi
if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Electron"* || "$(join_by ", " "${frameworks[@]-}")" == *"Tauri"* ]]; then
  add_unique universal_package_targets "AppImage"
  add_unique universal_package_targets "Snap"
  add_unique universal_package_targets "Flatpak"
  add_unique release_artifacts "desktop bundle"
fi
if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Flutter"* || "$(join_by ", " "${supported_envs[@]-}")" == *"Android"* ]]; then
  add_unique packaging_targets "APK"
  add_unique packaging_targets "AAB"
  add_unique release_artifacts "Android package"
fi
if contains_files "${TARGET_REPO}" "Dockerfile"; then
  add_unique packaging_targets "container image"
  add_unique release_artifacts "container image"
fi

if contains_files "${TARGET_REPO}" "pyproject.toml" "requirements.txt" "uv.lock"; then
  minimum_runtime_versions="Python 3.10+"
fi
if contains_files "${TARGET_REPO}" "pubspec.yaml"; then
  minimum_runtime_versions="$(join_by ", " "${minimum_runtime_versions}" "Flutter stable")"
fi
if contains_files "${TARGET_REPO}" "Cargo.toml"; then
  minimum_runtime_versions="$(join_by ", " "${minimum_runtime_versions}" "Rust stable")"
fi
if contains_files "${TARGET_REPO}" "go.mod"; then
  minimum_runtime_versions="$(join_by ", " "${minimum_runtime_versions}" "Go 1.22+")"
fi
node_engine="$(package_json_value "${TARGET_REPO}" "engines.node" || true)"
if [[ -n "${node_engine}" ]]; then
  minimum_runtime_versions="$(join_by ", " "${minimum_runtime_versions}" "Node.js ${node_engine}")"
elif contains_files "${TARGET_REPO}" "package.json"; then
  minimum_runtime_versions="$(join_by ", " "${minimum_runtime_versions}" "Node.js current LTS")"
fi

if contains_files "${TARGET_REPO}" "Dockerfile" "docker-compose.yml" "compose.yml"; then
  add_unique system_dependencies "Docker"
fi
repo_has_text "${TARGET_REPO}" 'postgres|psycopg|asyncpg|prisma' && add_unique system_dependencies "PostgreSQL"
repo_has_text "${TARGET_REPO}" 'redis|sidekiq|celery|rq' && add_unique system_dependencies "Redis"

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:format" || true)" == "yes" ]]; then
  format_cmd="npm run format"
elif contains_files "${TARGET_REPO}" "pyproject.toml"; then
  format_cmd="ruff format --check ."
elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
  format_cmd="cargo fmt --check"
elif contains_files "${TARGET_REPO}" "go.mod"; then
  format_cmd="gofmt -w ."
fi

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:lint" || true)" == "yes" ]]; then
  lint_cmd="npm run lint"
elif contains_files "${TARGET_REPO}" "pyproject.toml"; then
  lint_cmd="ruff check ."
elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
  lint_cmd="cargo clippy --all-targets --all-features -- -D warnings"
elif contains_files "${TARGET_REPO}" "go.mod"; then
  lint_cmd="go test ./..."
elif contains_files "${TARGET_REPO}" "Gemfile"; then
  lint_cmd="bundle exec rubocop"
fi

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:typecheck" || true)" == "yes" ]]; then
  typecheck_cmd="npm run typecheck"
elif contains_files "${TARGET_REPO}" "tsconfig.json" && contains_files "${TARGET_REPO}" "package.json"; then
  typecheck_cmd="npx tsc --noEmit"
elif contains_files "${TARGET_REPO}" "pyproject.toml"; then
  typecheck_cmd="mypy src/"
elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
  typecheck_cmd="cargo check"
elif contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj"; then
  typecheck_cmd="dotnet build --no-restore"
fi

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:test" || true)" == "yes" ]]; then
  unit_tests_cmd="npm run test"
elif contains_files "${TARGET_REPO}" "tests/" "test/" "__tests__/"; then
  if contains_files "${TARGET_REPO}" "pyproject.toml" "requirements.txt" "uv.lock"; then
    unit_tests_cmd="PYTHONPATH=. pytest -q"
  elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
    unit_tests_cmd="cargo test"
  elif contains_files "${TARGET_REPO}" "go.mod"; then
    unit_tests_cmd="go test ./..."
  elif contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj"; then
    unit_tests_cmd="dotnet test"
  elif contains_files "${TARGET_REPO}" "Gemfile"; then
    unit_tests_cmd="bundle exec rspec"
  fi
fi

if [[ -z "${integration_tests_cmd}" ]]; then
  if contains_files "${TARGET_REPO}" "docker-compose.yml" "compose.yml"; then
    integration_tests_cmd="docker compose up -d && ${unit_tests_cmd:-run integration suite} && docker compose down"
  elif contains_files "${TARGET_REPO}" "prisma/" "alembic/" "migrations/"; then
    integration_tests_cmd="${unit_tests_cmd}"
  fi
fi

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:build" || true)" == "yes" ]]; then
  build_cmd="npm run build"
elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
  build_cmd="cargo build --release"
elif contains_files "${TARGET_REPO}" "go.mod"; then
  build_cmd="go build ./..."
elif contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj"; then
  build_cmd="dotnet build"
elif contains_files "${TARGET_REPO}" "pyproject.toml" "requirements.txt" "uv.lock"; then
  if [[ -d "${TARGET_REPO}/app" ]]; then
    build_cmd="python3 -m compileall app"
  elif [[ -d "${TARGET_REPO}/src" ]]; then
    build_cmd="python3 -m compileall src"
  else
    build_cmd="python -m build"
  fi
fi

if [[ "$(package_json_value "${TARGET_REPO}" "hasScript:dev" || true)" == "yes" ]]; then
  launch_cmd="npm run dev"
elif [[ "$(package_json_value "${TARGET_REPO}" "hasScript:start" || true)" == "yes" ]]; then
  launch_cmd="npm run start"
elif [[ "$(package_json_value "${TARGET_REPO}" "hasScript:preview" || true)" == "yes" ]]; then
  launch_cmd="npm run preview"
elif repo_has_text "${TARGET_REPO}" 'from fastapi import|import fastapi'; then
  launch_cmd='uvicorn app.main:app --host ${APP_BIND_ADDRESS:-127.0.0.1} --port ${APP_PORT:-8000}'
elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
  launch_cmd="cargo run"
elif contains_files "${TARGET_REPO}" "go.mod"; then
  launch_cmd="go run ./..."
elif contains_glob "${TARGET_REPO}" "${TARGET_REPO}/*.csproj" || contains_glob "${TARGET_REPO}" "${TARGET_REPO}/**/*.csproj"; then
  launch_cmd="dotnet run"
fi

if contains_files "${TARGET_REPO}" "index.html" && ! contains_files "${TARGET_REPO}" "package.json" "pyproject.toml" "requirements.txt" "uv.lock"; then
  [[ -z "${build_cmd}" ]] && build_cmd="not required for static site"
  [[ -z "${launch_cmd}" ]] && launch_cmd='python3 -m http.server ${APP_PORT:-8000} --bind ${APP_BIND_ADDRESS:-127.0.0.1}'
  [[ -z "${e2e_cmd}" ]] && e2e_cmd="curl -fsS http://127.0.0.1:8000/"
fi

if [[ -z "${packaging_cmd}" ]]; then
  if contains_files "${TARGET_REPO}" "pyproject.toml"; then
    packaging_cmd="python -m build"
  elif contains_files "${TARGET_REPO}" "Cargo.toml"; then
    packaging_cmd="cargo build --release"
  elif contains_files "${TARGET_REPO}" "go.mod"; then
    packaging_cmd="go build ./..."
  elif contains_files "${TARGET_REPO}" "Dockerfile"; then
    packaging_cmd="docker build ."
  fi
fi

if [[ -z "${default_ports}" ]]; then
  if [[ "$(join_by ", " "${frameworks[@]-}")" == *"Next.js"* ]]; then
    default_ports="3000"
  elif repo_has_text "${TARGET_REPO}" 'from fastapi import|import fastapi'; then
    default_ports="8000"
  fi
fi

if [[ -z "${bind_model}" ]] && [[ -n "${default_ports}" ]]; then
  bind_model="bind to 127.0.0.1 by default"
fi

if [[ -z "${service_model}" ]]; then
  if [[ "$(join_by ", " "${components[@]-}")" == *"CLI"* ]]; then
    service_model="CLI process"
  elif [[ "$(join_by ", " "${frameworks[@]-}")" == *"Background worker"* || "$(join_by ", " "${components[@]-}")" == *"workers"* ]]; then
    service_model="background worker plus optional scheduler"
  elif [[ -n "${default_ports}" ]]; then
    service_model="HTTP service"
  elif [[ "$(join_by ", " "${supported_envs[@]-}")" == *"desktop"* ]]; then
    service_model="desktop application"
  fi
fi

if contains_files "${TARGET_REPO}" "alembic/" "alembic.ini"; then
  migration_model="Alembic"
elif contains_files "${TARGET_REPO}" "prisma/" "schema.prisma"; then
  migration_model="Prisma"
elif contains_files "${TARGET_REPO}" "diesel.toml" "migrations/"; then
  migration_model="Diesel or file-based migrations"
elif contains_files "${TARGET_REPO}" "migrations/"; then
  migration_model="file-based migrations"
fi

runtime_code_roots="$(detect_paths "${TARGET_REPO}" "src/" "app/" "frontend/" "backend/" "server/" "api/" "services/" "workers/" "worker/" "cmd/" "internal/" "packages/" "apps/" "lib/" "assets/" "public/" "index.html")"
test_roots="$(detect_paths "${TARGET_REPO}" "tests/" "test/" "__tests__/")"
scripts_roots="$(detect_paths "${TARGET_REPO}" "scripts/" "tools/" "cmd/" "tasks/")"
packaging_roots="$(detect_paths "${TARGET_REPO}" ".github/workflows/" ".github/actions/" ".gitlab-ci.yml" "deploy/" "docker/" "ops/" "packaging/" "release/" "dist/" "mobile/" "ai/")"
infrastructure_roots="$(detect_paths "${TARGET_REPO}" "infra/" "terraform/" "ansible/" "k8s/" "helm/")"

primary_languages="$(join_by ", " "${languages[@]-}")"
framework_value="$(join_by ", " "${frameworks[@]-}")"
component_value="$(join_by ", " "${components[@]-}")"
package_manager_value="$(join_by ", " "${package_managers[@]-}")"
build_tool_value="$(join_by ", " "${build_tools[@]-}")"
runtime_env_value="$(join_by ", " "${runtime_envs[@]-}")"
supported_env_value="$(join_by ", " "${supported_envs[@]-}")"
deployment_targets_value="$(join_by ", " "${deployment_targets[@]-}")"
packaging_targets_value="$(join_by ", " "${packaging_targets[@]-}")"
native_targets_value="$(join_by ", " "${native_package_targets[@]-}")"
universal_targets_value="$(join_by ", " "${universal_package_targets[@]-}")"
system_dependencies_value="$(join_by ", " "${system_dependencies[@]-}")"
release_artifacts_value="$(join_by ", " "${release_artifacts[@]-}")"

security_checks_cmd="bootstrap/scan-security.sh ${TARGET_REPO}"

printf 'Suggested PROJECT_PROFILE updates for %s\n' "${TARGET_REPO}"
printf '%s\n' "- Runtime code roots: ${runtime_code_roots}"
printf '%s\n' "- Test roots: ${test_roots}"
printf '%s\n' "- Scripts / tooling roots: ${scripts_roots}"
printf '%s\n' "- Packaging / deploy roots: ${packaging_roots}"
printf '%s\n' "- Infrastructure roots: ${infrastructure_roots}"
printf '%s\n' "- Primary languages: ${primary_languages}"
printf '%s\n' "- Primary frameworks: ${framework_value}"
printf '%s\n' "- Components: ${component_value}"
printf '%s\n' "- Package managers: ${package_manager_value}"
printf '%s\n' "- Build tools: ${build_tool_value}"
printf '%s\n' "- Runtime environments: ${runtime_env_value}"
printf '%s\n' "- Supported environments: ${supported_env_value}"
printf '%s\n' "- Deployment targets: ${deployment_targets_value}"
printf '%s\n' "- Packaging targets: ${packaging_targets_value}"
printf '%s\n' "- Native package targets: ${native_targets_value}"
printf '%s\n' "- Universal package targets: ${universal_targets_value}"
printf '%s\n' "- Minimum runtime versions: ${minimum_runtime_versions}"
printf '%s\n' "- System dependencies: ${system_dependencies_value}"
printf '%s\n' "- Release artifacts: ${release_artifacts_value}"
printf '%s\n' "- Format: ${format_cmd}"
printf '%s\n' "- Lint: ${lint_cmd}"
printf '%s\n' "- Typecheck: ${typecheck_cmd}"
printf '%s\n' "- Unit tests: ${unit_tests_cmd}"
printf '%s\n' "- Integration tests: ${integration_tests_cmd}"
printf '%s\n' "- End-to-end or smoke: ${e2e_cmd}"
printf '%s\n' "- Build: ${build_cmd}"
printf '%s\n' "- Install / launch verification: ${launch_cmd}"
printf '%s\n' "- Packaging verification: ${packaging_cmd}"
printf '%s\n' "- Security or policy checks: ${security_checks_cmd}"
printf '%s\n' "- Default ports: ${default_ports}"
printf '%s\n' "- Bind model: ${bind_model}"
printf '%s\n' "- Service model: ${service_model}"
printf '%s\n' "- Migration model: ${migration_model}"

if [[ ${WRITE} -eq 1 ]]; then
  python3 - <<'PY' \
    "${PROFILE}" \
    "${OVERWRITE}" \
    "${runtime_code_roots}" \
    "${test_roots}" \
    "${scripts_roots}" \
    "${packaging_roots}" \
    "${infrastructure_roots}" \
    "${primary_languages}" \
    "${framework_value}" \
    "${component_value}" \
    "${package_manager_value}" \
    "${build_tool_value}" \
    "${runtime_env_value}" \
    "${supported_env_value}" \
    "${deployment_targets_value}" \
    "${packaging_targets_value}" \
    "${native_targets_value}" \
    "${universal_targets_value}" \
    "${minimum_runtime_versions}" \
    "${system_dependencies_value}" \
    "${build_cmd}" \
    "${release_artifacts_value}" \
    "${format_cmd}" \
    "${lint_cmd}" \
    "${typecheck_cmd}" \
    "${unit_tests_cmd}" \
    "${integration_tests_cmd}" \
    "${e2e_cmd}" \
    "${build_cmd}" \
    "${launch_cmd}" \
    "${packaging_cmd}" \
    "${security_checks_cmd}" \
    "${default_ports}" \
    "${bind_model}" \
    "${service_model}" \
    "${migration_model}"
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
overwrite = sys.argv[2] == "1"
values = {
    "Runtime code roots": sys.argv[3],
    "Test roots": sys.argv[4],
    "Scripts / tooling roots": sys.argv[5],
    "Packaging / deploy roots": sys.argv[6],
    "Infrastructure roots": sys.argv[7],
    "Primary languages": sys.argv[8],
    "Primary frameworks": sys.argv[9],
    "Components": sys.argv[10],
    "Package managers": sys.argv[11],
    "Build tools": sys.argv[12],
    "Runtime environments": sys.argv[13],
    "Supported environments": sys.argv[14],
    "Deployment targets": sys.argv[15],
    "Packaging targets": sys.argv[16],
    "Native package targets": sys.argv[17],
    "Universal package targets": sys.argv[18],
    "Minimum runtime versions": sys.argv[19],
    "System dependencies": sys.argv[20],
    "Build entrypoints": sys.argv[21],
    "Release artifacts": sys.argv[22],
    "Format": sys.argv[23],
    "Lint": sys.argv[24],
    "Typecheck": sys.argv[25],
    "Unit tests": sys.argv[26],
    "Integration tests": sys.argv[27],
    "End-to-end or smoke": sys.argv[28],
    "Build": sys.argv[29],
    "Install / launch verification": sys.argv[30],
    "Packaging verification": sys.argv[31],
    "Security or policy checks": sys.argv[32],
    "Default ports": sys.argv[33],
    "Bind model": sys.argv[34],
    "Service model": sys.argv[35],
    "Migration model": sys.argv[36],
}

text = path.read_text()
for key, value in values.items():
    if not value:
        continue
    pattern = rf"^(- {re.escape(key)}:)([ \t]*)(.*)$"
    match = re.search(pattern, text, flags=re.MULTILINE)
    if not match:
        continue
    current = match.group(3).strip()
    if current and not overwrite:
      continue
    text = re.sub(
        pattern,
        lambda m, replacement=value: f"{m.group(1)} {replacement}",
        text,
        count=1,
        flags=re.MULTILINE,
    )
path.write_text(text)
PY
  echo "Wrote inferred basics into ${PROFILE}"
fi
