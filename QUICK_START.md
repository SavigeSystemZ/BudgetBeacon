# Quick Start: New Agent in Downstream Repo

You've been launched in a downstream app repository. Here's what you need to know in 2 minutes.

## What Just Happened

1. You're in `~/.MyAppZ/<ProjectName>/` — your **working directory**
2. You have local copies of `AGENTS.md` and `_system/` — **your authority**
3. You should **NOT** read context from parent directories (e.g., `~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/`)

## The First 30 Seconds

```bash
# 1. Check you're in the right place
pwd  # Should be ~/.MyAppZ/<ProjectName>/

# 2. Load your local authority
cat AGENTS.md                                # Your repo's rules
cat _system/AGENT_CONTEXT_CONTAINMENT_CONTRACT.md  # Context isolation rules
cat AGENT_BEHAVIOR_GUIDE.md                  # How to behave (this repo)

# 3. Validate your environment
bash bootstrap/check-context-isolation.sh .  # Should output: context_isolation_ok
bash bootstrap/check-git-discipline.sh .     # Should output: git_discipline_ok
```

## Core Rules (Cannot Be Broken)

| Rule | Why | Cost of Breaking |
| --- | --- | --- |
| **Use local `AGENTS.md`** | Each repo has its own authority | Context bleeding to other projects |
| **Don't read parent directories** | Isolation violation | Other projects inherit your context |
| **Use main branch only** | Single source of truth | Stale branches polluting fleet |
| **Commit → Validate → Push** | Ensures quality | Broken code in GitHub |
| **Run validation before commit** | Safety gate | Violations go undetected |

## Your Workflow

### 1. Start Session

```bash
# Verify local authority
test -f AGENTS.md && test -d _system/ && echo "✓ Ready"

# Check git status
git status  # Should show: "On branch main" and "nothing to commit"
```

### 2. Make Changes

```bash
# Work on your feature
echo "new code" >> src/feature.js

# Keep context local
mkdir -p .cursor/plans
echo "My session plan" > .cursor/plans/session-plan.md
```

### 3. Validate

```bash
# Run your test suite
npm test  # or equivalent for your language

# Check context isolation
bash bootstrap/check-context-isolation.sh .
# Expected: ✓ context_isolation_ok

# Check git discipline
bash bootstrap/check-git-discipline.sh .
# Expected: ✓ git_discipline_ok
```

### 4. Commit & Push

```bash
# Stage your changes
git add -A

# Commit with clear message
git commit -m "feat: implement new feature

- What you did
- Why you did it
- Any relevant details

Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>"

# Push to GitHub
git push origin main
```

### 5. End Session

```bash
# Verify everything is clean
git status  # Should show: "nothing to commit"
git branch  # Should show: "* main" only

# Verify validation passes
bash bootstrap/check-context-isolation.sh .
bash bootstrap/check-git-discipline.sh .

# Document what you did (for next agent)
# Update WHERE_LEFT_OFF.md with handoff notes
```

## Context Location Reference

### Your Context (Read From These)

```
~/.MyAppZ/<ProjectName>/
├── AGENTS.md                           ← START HERE
├── _system/AGENT_CONTEXT_CONTAINMENT_CONTRACT.md
├── _system/GIT_REMOTE_AND_SYNC_PROTOCOL.md
├── _system/DEPLOYMENT_BOUNDARY_PROTOCOL.md
├── AGENT_BEHAVIOR_GUIDE.md
├── WHERE_LEFT_OFF.md                   ← Handoff from previous agent
├── TODO.md
├── PRODUCT_BRIEF.md
└── .cursor/plans/                      ← Your session plans
    └── <your-session-plan>.md
```

### NOT Your Context (Don't Read These)

```
~/.MyAppZ/_AI_AGENT_SYSTEM_TEMPLATE/    ← TEMPLATE REPO (not authority)
├── AGENTS.md                           ← NOT your authority
├── _system/                            ← NOT your authority
├── .cursor/                            ← NOT your context
└── ...                                 ← All redirect shims only
```

## Quick Answers

**Q: Should I read `.cursorrules` in the parent directory?**  
A: Read it to understand it's a redirect shim. Then read your local `AGENTS.md` instead.

**Q: Can I create a feature branch?**  
A: Only with operator approval. Default is main-only.

**Q: Where do I store my session plans?**  
A: `./.cursor/plans/` in YOUR repo (not parent directory).

**Q: What if validation fails?**  
A: Read the error message. It tells you what's wrong. Fix it and re-run.

**Q: Should I use PRs?**  
A: No. This is solo work. Commit → Validate → Push to main.

**Q: Can other agents see my context?**  
A: Only if they work in the same repo. Each repo is isolated.

## Still Confused?

Read these files in order:

1. **AGENT_BEHAVIOR_GUIDE.md** — Detailed behavior rules
2. **_system/AGENT_CONTEXT_CONTAINMENT_CONTRACT.md** — Context isolation rules
3. **_system/GIT_REMOTE_AND_SYNC_PROTOCOL.md** — Git workflow rules
4. **_system/DEPLOYMENT_BOUNDARY_PROTOCOL.md** — What deploys vs what stays

## Final Checklist

- [ ] I'm reading `./AGENTS.md` (not parent-directory AGENTS.md)
- [ ] I'm using `./_system/` (not parent-directory _system/)
- [ ] I'm storing context in `./.cursor/plans/` (this repo only)
- [ ] I'm on `main` branch
- [ ] My working tree is clean
- [ ] Validation checks pass
- [ ] I understand context isolation rules

**Ready?** Start with `AGENTS.md`.

---
**Session:** 2026-05-28  
**Context Isolation:** Enforced ✓  
**Git Discipline:** Enforced ✓
