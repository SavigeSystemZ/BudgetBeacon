# Agent Behavior Guide: Context Isolation & Git Discipline

This guide explains how agents should behave in AIAST downstream repositories, particularly regarding context isolation and Git workflows.

## Quick Start (TL;DR)

1. **Load local authority:** Always read `./AGENTS.md` and `./_system/` from your working directory
2. **Ignore parent directories:** Never load context from `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/`
3. **Use main branch:** Commit directly to `main` after local validation
4. **Keep context local:** Store all plans and context in `.cursor/`, `.claude/`, etc. in your repo only
5. **Validate before commit:** Run `bootstrap/check-context-isolation.sh` and `bootstrap/check-git-discipline.sh`

## Context Authority

### What is "Local Authority"?

When you start working in a downstream repo, **that repo's own files are the only authority**:

- `./AGENTS.md` — Your repo's agent rules (not parent-directory AGENTS.md)
- `./_system/` — Your repo's operating layer (not parent-directory _system/)
- `./.cursor/`, `./.claude/`, `./.gemini/` — Your repo's tool-specific context (not parent-directory adapters)

### The Golden Rule: Never Read Parent Directories

❌ **WRONG:**
```
I'm in ~/.MyAppZ/my-app/
I find ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursorrules
I load rules from the parent template
Result: Context bleeding, isolation violated
```

✅ **CORRECT:**
```
I'm in ~/.MyAppZ/my-app/
I find ./AGENTS.md (local)
I read ./_system/AGENT_CONTEXT_CONTAINMENT_CONTRACT.md
Result: Local authority, isolation maintained
```

### Checking If You're Loading Correctly

When you start work in a repo:

```bash
# ✓ You should read these
ls -la ./AGENTS.md          # Local AGENTS.md
ls -la ./_system/           # Local _system/ directory
ls -la ./.cursor/           # Local .cursor/ folder

# ✗ You should NOT read these (they're parent-directory shims)
# ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/AGENTS.md
# ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/_system/
# ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/
```

If you find yourself reading parent-directory files, **STOP** and ask:

> "Are these files in my working directory, or in a parent directory?"

If parent directory: **Reset to working directory only.**

## Context Storage Rules

### What Context Can I Store?

**YES - Store these locally:**
- `.cursor/plans/` — Session plans and work tracking
- `.cursor/rules/` — Session-specific rules and overlays
- `.claude/settings.json` — Tool-specific configuration
- `WHERE_LEFT_OFF.md` — Handoff notes for this project
- `TODO.md` — Project-specific work items
- Any other project-specific context

**NO - Never store these anywhere but locally:**
- Secrets or credentials (use `.env`, not .cursor/)
- Code or implementation (use `src/`, not .cursor/)
- Parent-directory references (use relative paths instead)

### Example: Correct Context Structure

```
~/.MyAppZ/my-app/
├── AGENTS.md                      ← Local authority
├── _system/                        ← Local authority
├── .cursor/
│   ├── plans/                      ← Session plans (isolated to this repo)
│   ├── rules/                      ← Session rules (isolated to this repo)
│   └── settings.json
├── .claude/
│   └── settings.json               ← Tool-specific (isolated to this repo)
├── WHERE_LEFT_OFF.md              ← Handoff notes for THIS project only
├── TODO.md                         ← Work items for THIS project only
├── app/
│   └── src/                        ← Application code
└── ...

❌ DO NOT CREATE:
- ~/.MyAppZ/my-app/.cursor/plans/Universal-Plan.md (shared across repos)
- ~/.MyAppZ/my-app/.cursor/rules/All-Repos-Rules.mdc (shared across repos)
- Links/symlinks to parent-directory folders
```

## Git Discipline: Main Branch Only

### The Rules

**Default:** Single `main` branch. Period.

```
✓ Allowed workflow:
  1. Work on a feature locally (uncommitted)
  2. Validate locally (tests, lints, etc.)
  3. Commit to main with clear message
  4. Push to GitHub (GitHub mirrors the result)
  5. Done

✗ Forbidden workflow:
  1. Create feature/my-feature branch
  2. Push to GitHub
  3. Create PR
  4. Request review from other developers
  5. Merge when approved
  Result: This is a multi-developer workflow; we're solo
```

### When Can I Use Feature Branches?

**Only in exceptional cases:**

- **Operator explicitly approves:** You ask and get explicit permission
- **Emergency recovery:** Local repo corruption, need to recover from remote
- **Temporary experiment:** Branch must be merged or deleted **before session ends**

Example of exception approval:
```
"I want to experiment with a new approach on branch experiment/new-cache-system"
Operator: "OK, but merge or delete before you finish the session"
→ You create branch
→ You work and validate
→ Before session ends: merge to main or delete
→ Never leave standing branches
```

### How to Commit & Push Correctly

```bash
# Make changes
echo "new feature" >> src/feature.js

# Stage changes
git add src/feature.js

# Commit to main with clear message
git commit -m "feat: add new cache system

- Implements Redis-backed caching for API responses
- Reduces DB queries by 60% per benchmarks
- Includes cache invalidation on mutations
- Adds integration tests for cache layer

Closes #42

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

# Validate before pushing (run tests, lints, checks)
npm test
bash bootstrap/check-context-isolation.sh .
bash bootstrap/check-git-discipline.sh .

# Push to GitHub
git push origin main
```

### Branch Cleanup Checklist

Before ending your work session:

- [ ] All changes are committed to `main`
- [ ] `git status` shows clean working tree
- [ ] No standing feature/fix/chore branches (`git branch -a`)
- [ ] Validation checks pass:
  - [ ] `bash bootstrap/check-git-discipline.sh .` → `git_discipline_ok`
  - [ ] `bash bootstrap/check-context-isolation.sh .` → `context_isolation_ok`
- [ ] GitHub push succeeded (`git push origin main`)

If you created an experimental branch:
```bash
# Merge it to main
git checkout main
git merge <branch> -m "Merge <branch> into main"

# Delete local branch
git branch -d <branch>

# Delete remote branch
git push origin --delete <branch>

# Verify it's gone
git branch -a  # Should show only main
```

## Validation Scripts: Use Before Committing

### Context Isolation Check

```bash
bash bootstrap/check-context-isolation.sh .
```

This checks:
- ✓ Local `AGENTS.md` exists
- ✓ Local `_system/` exists
- ✓ No symlinks to parent directories
- ✓ No hardcoded parent-directory paths
- ✓ Runtime code doesn't reference `_system/`

**Expected output:** `context_isolation_ok`

### Git Discipline Check

```bash
bash bootstrap/check-git-discipline.sh .
```

This checks:
- ✓ `main` is the current branch
- ✓ No standing feature branches
- ✓ Clean working tree
- ✓ Remote is configured correctly

**Expected output:** `git_discipline_ok`

### Before You Commit

**Always run this:**
```bash
bash bootstrap/check-context-isolation.sh . && \
bash bootstrap/check-git-discipline.sh . && \
git push origin main
```

## Common Mistakes (and How to Avoid Them)

### Mistake 1: Loading Parent-Directory Rules

❌ **Wrong:**
```
"I see .cursorrules in the parent directory,
let me load that for my rules"
```

✅ **Correct:**
```
"I see .cursorrules in the parent directory,
but that's just a redirect shim.
My actual rules are in ./AGENTS.md and ./_system/"
```

### Mistake 2: Storing Context in Parent Directory

❌ **Wrong:**
```
cd ~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/plans/
echo "My project plan" > my-project-plan.md
# This pollutes the parent directory and affects all projects
```

✅ **Correct:**
```
cd ~/.MyAppZ/my-project/.cursor/plans/
echo "My project plan" > my-project-plan.md
# This stays isolated in my project's context
```

### Mistake 3: Creating Feature Branches Without Approval

❌ **Wrong:**
```
git checkout -b feature/my-feature
git commit -m "WIP"
git push origin feature/my-feature
# Session ends, branch is left hanging
# Next agent starts on a different temp branch
# Branches accumulate; git discipline fails
```

✅ **Correct:**
```
# Ask operator first: "Can I create a feature/my-feature branch?"
# If approved:
git checkout -b feature/my-feature
# ... work ...
# BEFORE SESSION ENDS:
git checkout main
git merge feature/my-feature -m "Merge feature/my-feature"
git branch -d feature/my-feature
git push origin main
git push origin --delete feature/my-feature
```

### Mistake 4: Leaving Uncommitted Work

❌ **Wrong:**
```
git status
# Shows uncommitted changes
# Session ends
# Next agent starts with dirty working tree
```

✅ **Correct:**
```
# Before ending session:
git add -A
git commit -m "..."
git push origin main
git status  # Shows "working tree clean"
```

## Troubleshooting

### "I see a redirect shim at `.cursorrules` — what should I do?"

Read it, understand it points to local authority, then load from local:

```bash
cat .cursorrules
# Output: "Load your local AGENTS.md and _system/"

cat AGENTS.md
# This is MY project's authority, not the parent template's
```

### "My validation check is failing — what do I do?"

Read the error message carefully:

```bash
bash bootstrap/check-context-isolation.sh .
# ✗ VIOLATION: Found parent-directory references in .cursor/plans/
```

Fix the violation:

```bash
# Find and remove the parent-directory reference
grep -r "~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE" .cursor/
rm -f <file-with-reference>

# Validate again
bash bootstrap/check-context-isolation.sh .
# ✓ context_isolation_ok
```

### "I accidentally created a feature branch — how do I undo it?"

```bash
# If not pushed yet (easy):
git branch -D <branch>

# If already pushed (need to clean remote):
git push origin --delete <branch>
git branch -D <branch>

# Ask operator: "Should this be merged to main or abandoned?"
```

## Summary

| Concept | Do This | Not This |
| --- | --- | --- |
| Load rules | `./AGENTS.md` | `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/AGENTS.md` |
| Load operating layer | `./_system/` | `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/_system/` |
| Store context | `./.cursor/plans/` | `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/.cursor/plans/` |
| Create branches | Ask operator first | Assume you can create branches |
| End session | Main branch clean, all pushed | Leave feature branches hanging |
| Validate | Run checks before commit | Skip validation checks |
| Git workflow | Commit → Validate → Push to main | Create PR, request review, merge |

---

**Effective:** Immediately for all downstream repos  
**Testing:** Validated on fresh scaffold repo  
**Questions:** See AGENT_CONTEXT_CONTAINMENT_CONTRACT.md or GIT_REMOTE_AND_SYNC_PROTOCOL.md
