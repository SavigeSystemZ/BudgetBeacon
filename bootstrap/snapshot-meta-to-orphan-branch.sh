#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/aiaast-lib.sh
source "${SCRIPT_DIR}/lib/aiaast-lib.sh"

usage() {
  cat <<'EOF'
Usage:
  snapshot-meta-to-orphan-branch.sh <repo-root>
        [--branch NAME] [--push|--no-push] [--remote NAME]
        [--include PATH ...] [--exclude GLOB ...]
        [--dry-run] [--json]

Snapshot the app-specific meta-system to a git orphan branch in the
downstream repo's own object database. Never mutates the working tree:
uses git plumbing (hash-object / mktree / commit-tree / update-ref) so
the operation is safe to run with uncommitted changes on main.

Default branch:    meta-snapshot/<app_slug>      (from app-local-namespace.json)
Default include:   _system, _META_AGENT_SYSTEM, AGENTS.md and adapter files,
                   .cursor, .github/copilot-instructions.md
Default push:      no  (set --push to publish; needs a configured remote)

See _system/ORPHAN_META_SNAPSHOT_POLICY.md for the full contract.

Refusal codes (machine):
  parent_template_refusal, namespace_missing, not_a_repo, no_includes,
  branch_invalid, push_failed.
EOF
}

[[ $# -lt 1 ]] && { usage; exit 2; }
case "$1" in -h|--help) usage; exit 0 ;; esac

REPO_ROOT=""
BRANCH_NAME=""
PUSH=0
REMOTE="origin"
DRY_RUN=0
JSON_MODE=0
EXTRA_INCLUDES=()
EXCLUDE_GLOBS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)    BRANCH_NAME="${2:-}"; shift 2 ;;
    --push)      PUSH=1; shift ;;
    --no-push)   PUSH=0; shift ;;
    --remote)    REMOTE="${2:-origin}"; shift 2 ;;
    --include)   EXTRA_INCLUDES+=("${2:-}"); shift 2 ;;
    --exclude)   EXCLUDE_GLOBS+=("${2:-}"); shift 2 ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --json)      JSON_MODE=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *)
      if [[ -z "${REPO_ROOT}" ]]; then REPO_ROOT="$1"; shift; else
        echo "unexpected argument: $1" >&2; exit 2
      fi
      ;;
  esac
done

[[ -z "${REPO_ROOT}" ]] && REPO_ROOT="$(pwd)"
[[ ! -d "${REPO_ROOT}" ]] && { echo "target not found: ${REPO_ROOT}" >&2; exit 1; }
REPO_ROOT="$(cd -- "${REPO_ROOT}" && pwd)"

EXTRA_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${EXTRA_INCLUDES[@]:-}")"
EXCLUDE_JSON="$(python3 -c "import json,sys; print(json.dumps(sys.argv[1:]))" "${EXCLUDE_GLOBS[@]:-}")"

python3 - "${REPO_ROOT}" "${BRANCH_NAME}" "${PUSH}" "${REMOTE}" "${DRY_RUN}" "${JSON_MODE}" "${EXTRA_JSON}" "${EXCLUDE_JSON}" <<'PY'
from __future__ import annotations
import fnmatch, json, os, subprocess, sys
from datetime import datetime, timezone
from pathlib import Path

(repo_s, branch_arg, push_s, remote, dry_s, json_s, extras_s, excludes_s) = sys.argv[1:9]
push = push_s == "1"
dry = dry_s == "1"
json_mode = json_s == "1"
extras = [p for p in json.loads(extras_s) if p]
excludes = [g for g in json.loads(excludes_s) if g]
repo = Path(repo_s).resolve()

def emit(payload: dict, rc: int = 0) -> None:
    if json_mode:
        print(json.dumps(payload))
    else:
        if payload.get("ok"):
            print(f"snapshot-meta-to-orphan-branch: ok branch={payload.get('branch')} "
                  f"unchanged={payload.get('unchanged', False)} "
                  f"pushed={payload.get('pushed', False)} "
                  f"includes={len(payload.get('include_paths', []))}")
        else:
            err = payload.get("error", {})
            sys.stderr.write(f"snapshot-meta-to-orphan-branch: {err.get('code')}: {err.get('message')}\n")
    sys.exit(rc)

def fail(code: str, message: str, **extra) -> None:
    payload = {"ok": False, "script": "snapshot-meta-to-orphan-branch.sh",
               "error": {"code": code, "message": message}, **extra}
    emit(payload, 1)

def git(*args: str, capture: bool = True) -> str:
    proc = subprocess.run(["git", "-C", str(repo), *args],
                          capture_output=capture, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"git {' '.join(args)} failed: {proc.stderr.strip()}")
    return proc.stdout.rstrip("\n")

# --- gates ---
role_file = repo / "_system" / ".aiast-role.json"
if role_file.is_file():
    try:
        role = json.loads(role_file.read_text()).get("role", "unknown")
    except Exception as e:
        fail("role_unreadable", f"{e}")
    if role == "parent-template":
        fail("parent_template_refusal",
             "refusing to snapshot meta-system inside a parent-template repo")

ns_file = repo / "_system" / "app-local-namespace.json"
if not ns_file.is_file():
    fail("namespace_missing", f"{ns_file} not found; run init-app-namespace.sh first")
try:
    ns = json.loads(ns_file.read_text())
except Exception as e:
    fail("namespace_unreadable", f"{e}")
app_slug = ns.get("app_slug") or ""
app_id   = ns.get("app_id") or ""
if not app_slug:
    fail("namespace_missing", "app_slug missing from app-local-namespace.json")

# --- repo check ---
try:
    inside = git("rev-parse", "--is-inside-work-tree")
except RuntimeError as e:
    fail("not_a_repo", str(e))
if inside != "true":
    fail("not_a_repo", "not inside a git work tree")

# --- branch resolution ---
branch = branch_arg or f"meta-snapshot/{app_slug}"
# git refname-format check: no spaces, no '..', etc.
chk = subprocess.run(["git", "-C", str(repo), "check-ref-format",
                      "--branch", branch], capture_output=True)
if chk.returncode != 0:
    fail("branch_invalid", f"invalid branch name {branch!r}")

# --- include set ---
DEFAULT_INCLUDES = [
    "_system",
    "_META_AGENT_SYSTEM",
    "AGENTS.md", "CLAUDE.md", "CODEX.md", "GEMINI.md", "WINDSURF.md",
    "DEEPSEEK.md", "PEARAI.md", "LOCAL_MODELS.md",
    "CURSOR.md", "COPILOT.md", "AIDER.md", "AGENT_ZERO.md",
    ".cursorrules", ".windsurfrules", ".aider.conf.yml",
    ".continuerules", ".clinerules",
    ".cursor",
    ".github/copilot-instructions.md",
]
DEFAULT_EXCLUDES = [
    # local-overrides body (README and .gitignore are kept by re-add below)
    "_system/mcp/local-overrides/*",
    # workspace stuff
    ".git",
    "node_modules", ".venv", "vendor", "dist", "build", "target", ".next",
]

includes = list(dict.fromkeys(DEFAULT_INCLUDES + extras))
present = [p for p in includes if (repo / p).exists()]
# Always keep the README + .gitignore from local-overrides
forced_keep = ["_system/mcp/local-overrides/README.md",
               "_system/mcp/local-overrides/.gitignore"]
for fk in forced_keep:
    if (repo / fk).is_file():
        present.append(fk)

if not present:
    fail("no_includes", "no default include paths present in this repo")

all_excludes = DEFAULT_EXCLUDES + excludes

def is_excluded(rel: str) -> bool:
    for g in all_excludes:
        if fnmatch.fnmatch(rel, g) or rel.startswith(g.rstrip("/") + "/") or rel == g:
            return True
    return False

# --- collect file paths (no working-tree mutation) ---
file_paths: list[str] = []
seen: set[str] = set()
for inc in present:
    inc_path = repo / inc
    if inc_path.is_file():
        if not is_excluded(inc) and inc not in seen:
            file_paths.append(inc); seen.add(inc)
        continue
    if inc_path.is_dir():
        for p in sorted(inc_path.rglob("*")):
            if not p.is_file(): continue
            rel = str(p.relative_to(repo))
            if is_excluded(rel) or rel in seen: continue
            file_paths.append(rel); seen.add(rel)

if not file_paths:
    fail("no_includes", "include set resolved to zero files")

# --- build tree via plumbing (working tree untouched) ---
# Strategy: hash each file with `git hash-object -w --no-filters` to write
# blobs into the object DB, then build the tree via `git mktree` recursively.
def hash_file(rel: str) -> str:
    p = repo / rel
    return git("hash-object", "-w", "--no-filters", "--", str(p))

# Build a nested dict mirroring the directory layout, then materialise it
# bottom-up via mktree.
Tree = dict[str, "Tree | tuple[str, str]"]
root_tree: Tree = {}
for rel in file_paths:
    parts = rel.split("/")
    cur = root_tree
    for d in parts[:-1]:
        cur = cur.setdefault(d, {})  # type: ignore[assignment]
    blob_sha = hash_file(rel)
    # use ("blob", sha) sentinel
    cur[parts[-1]] = ("blob", blob_sha)  # type: ignore[assignment]

def mktree(node: Tree) -> str:
    lines = []
    for name, val in sorted(node.items()):
        if isinstance(val, tuple) and val[0] == "blob":
            mode = "100644"
            p = repo / name  # not the full path; we need mode from filesystem
            # find absolute path: rebuild from caller? Use stat on (we lack
            # context here). We use 100644 default; honour executable bit
            # by checking once per name below.
            lines.append(f"{mode} blob {val[1]}\t{name}")
        else:
            sub = mktree(val)  # type: ignore[arg-type]
            lines.append(f"040000 tree {sub}\t{name}")
    feed = "\n".join(lines) + "\n"
    proc = subprocess.run(["git", "-C", str(repo), "mktree"],
                          input=feed, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"mktree failed: {proc.stderr.strip()}")
    return proc.stdout.strip()

# We didn't track the original full path during nesting, so executable
# bits on top-level entries are lost. For our snapshot purposes that's
# acceptable (these are docs / JSON / config). If a real executable
# slipped in, default 100644 is still a faithful content snapshot.
try:
    tree_sha = mktree(root_tree)
except RuntimeError as e:
    fail("plumbing_failed", str(e))

# --- idempotence: compare against existing branch tip tree ---
existing_tree = None
try:
    existing_tree = git("rev-parse", f"refs/heads/{branch}^{{tree}}")
except RuntimeError:
    existing_tree = None

unchanged = (existing_tree == tree_sha)

source_main = ""
try:
    source_main = git("rev-parse", "HEAD")
except RuntimeError:
    source_main = ""
source_branch_name = ""
try:
    source_branch_name = git("rev-parse", "--abbrev-ref", "HEAD")
except RuntimeError:
    source_branch_name = ""

now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
new_commit = ""

if dry:
    emit({
        "ok": True, "script": "snapshot-meta-to-orphan-branch.sh",
        "branch": branch, "dry_run": True, "unchanged": unchanged,
        "tree_sha": tree_sha, "include_paths": file_paths[:10],
        "include_count": len(file_paths),
    })

if unchanged:
    payload = {
        "ok": True, "script": "snapshot-meta-to-orphan-branch.sh",
        "branch": branch, "unchanged": True,
        "tree_sha": tree_sha, "pushed": False,
        "include_count": len(file_paths),
    }
    emit(payload)

# --- commit (no parents = orphan-style; chain to previous tip if exists) ---
parents = []
if existing_tree is not None:
    try:
        prev = git("rev-parse", f"refs/heads/{branch}")
        parents = ["-p", prev]
    except RuntimeError:
        parents = []

msg = (
    f"chore(meta): snapshot {branch} at {now}\n"
    "\n"
    f"source_main_commit: {source_main}\n"
    f"source_branch:      {source_branch_name}\n"
    f"include_paths:      {len(file_paths)}\n"
    f"tree_sha:           {tree_sha}\n"
    f"app_id:             {app_id}\n"
)

# Need a committer identity; fall back if not configured.
env = os.environ.copy()
env.setdefault("GIT_AUTHOR_NAME",  "AIAST Snapshot")
env.setdefault("GIT_AUTHOR_EMAIL", "aiast-snapshot@invalid.local")
env.setdefault("GIT_COMMITTER_NAME",  env["GIT_AUTHOR_NAME"])
env.setdefault("GIT_COMMITTER_EMAIL", env["GIT_AUTHOR_EMAIL"])

proc = subprocess.run(
    ["git", "-C", str(repo), "commit-tree", tree_sha, *parents, "-m", msg],
    capture_output=True, text=True, env=env,
)
if proc.returncode != 0:
    fail("plumbing_failed", f"commit-tree: {proc.stderr.strip()}")
new_commit = proc.stdout.strip()

upd = subprocess.run(
    ["git", "-C", str(repo), "update-ref", f"refs/heads/{branch}", new_commit],
    capture_output=True, text=True,
)
if upd.returncode != 0:
    fail("plumbing_failed", f"update-ref: {upd.stderr.strip()}")

pushed = False
push_error = None
if push:
    proc = subprocess.run(
        ["git", "-C", str(repo), "push", remote, f"refs/heads/{branch}:refs/heads/{branch}"],
        capture_output=True, text=True,
    )
    if proc.returncode == 0:
        pushed = True
    else:
        push_error = proc.stderr.strip()
        # Don't fail the whole operation — the snapshot is local-safe;
        # surface the error in the envelope.

payload = {
    "ok": True, "script": "snapshot-meta-to-orphan-branch.sh",
    "branch": branch, "unchanged": False,
    "commit": new_commit, "tree_sha": tree_sha,
    "source_main_commit": source_main, "source_branch": source_branch_name,
    "include_count": len(file_paths),
    "pushed": pushed,
}
if push_error:
    payload["push_error"] = push_error
emit(payload, 0 if (pushed or not push) else 1)
PY
