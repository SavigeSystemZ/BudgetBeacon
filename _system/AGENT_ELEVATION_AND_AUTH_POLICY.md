# Agent Elevation and Authentication Policy

Project-specific agents working inside a downstream AIAST app are
**authorized to run every command needed to accomplish the task at
hand** — including commands that require operating-system privilege
escalation or interactive authentication — provided the elevation is
*operator-aware*. This rule explicitly removes the ambiguity from
`SAFE_PERMISSION_AND_SETUP_REPAIR_PROTOCOL.md`, which only covers
*automatic, bounded* repairs.

This policy applies to downstream apps. The AIAST parent template
itself (`_system/.aiast-role.json#/role == "parent-template"`) is
governed by stricter rules — see `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md`
and the no-global-writes default in `bootstrap/init-project.sh`.

## When elevation is authorized

If a task genuinely needs one of the following, the agent MUST attempt
it (rather than abort) — using the right operator-prompted mechanism
for the host OS:

| Need | Allowed mechanism | Example |
|------|-------------------|---------|
| Fix file ownership / permissions outside the repo | `sudo`, `chown`, `chmod` | `sudo chown -R "${USER}:" /opt/myapp` for an installed bundle the user owns |
| Install a missing system package required to run the project's tests | `sudo apt`, `sudo dnf`, `brew`, `pacman`, `pkexec` | `sudo apt-get install -y libpq-dev` |
| Read or write a credential that the user keeps in a keyring | `secret-tool`, `kwallet-query`, `security` (macOS Keychain), KDE Wallet, GNOME Keyring | `secret-tool lookup service x account y` |
| Re-authenticate to a host or cloud the user has configured | `gcloud auth login`, `gh auth login`, `aws configure sso`, `op signin`, fingerprint / smartcard | `! gcloud auth login` (interactive — see "Operator hand-off" below) |
| Talk to systemd / launchd to start a local service | `systemctl --user`, `loginctl`, `pkexec systemctl` | `systemctl --user restart myapp.service` |
| Mount, unmount, or change a removable device | `udisksctl`, `mount`, `umount` | `udisksctl mount -b /dev/sdb1` |
| Sign commits / packages | `gpg --sign`, `ssh-add`, hardware key | `git commit -S -m '…'` |
| Read polkit-protected sysinfo | `pkexec`, `polkit-agent-helper-1` | `pkexec journalctl -u svc` |

The list is illustrative, not exhaustive. The rule is:

> If accomplishing the user's task requires a command that prompts for
> elevation, run it — and surface the prompt rather than work around it.

## Operator hand-off (when the agent cannot run the prompt itself)

Some prompts are interactive in ways the agent's tool harness cannot
satisfy directly — fingerprint scanners, hardware-key touches, GPG
passphrase prompts that need a TTY, vendor login pages in a browser.
In those cases the agent MUST:

1. **Stop work and tell the operator exactly what's needed**, in
   plain language. Example: "I need to run `gcloud auth login` — it
   opens a browser. Please run this in your terminal: `! gcloud auth
   login`. I'll resume once you're authenticated."
2. **Prefer the `! <command>` prompt-prefix form** when the host
   harness supports it (Claude Code does). That runs the command in
   the operator's terminal, so the auth prompt lands where the
   operator can answer it, and the output is captured back in the
   session.
3. **If the harness has no `!` form**, give a fully-runnable copy-
   paste block in a fenced ``` shell ``` block, plus a one-sentence
   explanation of what the operator should see when it succeeds.
4. **Never silently retry** a command that just failed for an auth
   reason — diagnose, then ask.

## Asking a question vs. providing instructions

Pick by *who has the answer*:

- The agent has the answer → run the command (with `sudo`, etc.) and
  let the OS prompt the operator.
- The operator has the answer (which AWS account? which keyring?) →
  **ask a single, specific question** with a default. Never ask a
  yes/no when the real question is "which one."
- The operator has the credential and the harness can't relay it →
  **provide instructions** the operator can paste, then wait.

## Bounded auto-elevation (does NOT need a prompt)

These are pre-authorized for any project-specific agent and need no
operator prompt, because they are repo-local and reversible:

- `chmod +x` on a script in `bootstrap/` or `ops/`.
- `chmod` on a file the running user already owns inside the active
  repo.
- `git config --local`.
- `mkdir -p` inside the active repo.
- Creating, reading, or rotating files under `_system/agent-state/`
  including audit, quarantine, and lease state.

This list is intentionally narrow — anything broader requires the
operator-prompted path above.

## Forbidden, even with elevation

Elevation does not unlock these. They require a *separate, explicit*
operator authorization captured in `WHERE_LEFT_OFF.md` or a PR
description:

- Writes outside the active repo, except when fixing a path the
  operator explicitly named in the same conversation.
- Mutating sibling AIAST app repos.
- Modifying global git config, global tool config, or `$HOME/.ssh`.
- Disabling MFA, deleting recovery codes, or rotating credentials
  shared with other users.
- Force-pushing to a remote branch that other people may have based
  work on.
- Anything in the parent AIAST template repo (always forbidden from
  downstream-app context).

## Per-session disclosure

When an agent runs the first elevation-requiring command in a
session, it MUST include a one-line disclosure in its visible output:

```
[elevation] running: sudo apt-get install -y libpq-dev
            reason:  postgres dev headers needed for pip install psycopg2
```

After that, subsequent uses don't need to repeat the disclosure
unless the elevation mechanism changes.

## Cross-references

- `_system/SAFE_PERMISSION_AND_SETUP_REPAIR_PROTOCOL.md` — narrower
  policy for *automatic* repairs (no operator prompt).
- `_system/INSTRUCTION_PRECEDENCE_CONTRACT.md` — overall instruction
  layering.
- `_system/EXECUTION_PROTOCOL.md` — how agents execute tasks generally.
- `_system/AUTONOMOUS_GUARDRAILS_PROTOCOL.md` — what an agent may do
  on its own initiative.
- `_system/WORKSPACE_AUTHORITY_AND_CONTAINMENT_PROTOCOL.md` — repo
  boundary that elevation does not dissolve.
