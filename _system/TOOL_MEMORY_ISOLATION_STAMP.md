# Tool Memory Isolation Stamp Contract

Per-host adapter tool-memory files under `_system/tool-memory/` MUST carry
an isolation stamp when they hold non-trivial content in a downstream-app
repo. The stamp binds the memory to a specific `app_id` and at least one
`agent_id`, preventing silent cross-app reuse when a memory file is copied
or symlinked across repos.

This is V2 §21.2's adapter-level enforcement: agents stamp their writes so
audits can attribute every memory entry to a registered instance in a
known app.

## When the stamp is required

| Repo role | File state | Stamp required? |
|---|---|---|
| parent-template | empty / `# <Tool> Memory` stub only | NO |
| parent-template | non-trivial content | NO (template surface — content should never live here) |
| downstream-app | empty / `# <Tool> Memory` stub only | NO |
| downstream-app | non-trivial content (≥1 non-comment line beyond the title) | YES |

"Non-trivial content" is defined as: any line outside the stamp block that
is not blank, not a markdown comment (`<!-- ... -->`), and not the first
H1 title line.

## Stamp shape

The stamp is an HTML comment block at the top of the file, immediately
after the H1 title. It is parsed line-by-line — order is fixed.

```
# Cursor Memory

<!-- tool-memory-isolation-stamp v1
app_id: <slug>:<uuidv7>
agent_id: <agent_type>-NN
set_at: 2026-05-13T18:42:00Z
set_by: <writing-agent-host>     # e.g. cursor, claude-code, codex, aider, copilot, antigravity
-->

... actual memory content ...
```

Field rules:
- `app_id` — must equal `_system/app-local-namespace.json#/app_id`.
- `agent_id` — must match the agent-instance naming grammar from
  `AGENT_INSTANCE_ISOLATION_POLICY.md` (`^[a-z][a-z0-9-]*-[0-9]{2,3}$`).
- `set_at` — ISO-8601 UTC with `Z` suffix.
- `set_by` — basename of the adapter that performed the write.

Additional fields are allowed (forward-compatible) but must appear after
the four required keys and before the closing `-->`.

## Multi-agent files

When more than one agent writes to the same memory file, the stamp may
contain an `agents:` list instead of a single `agent_id`:

```
<!-- tool-memory-isolation-stamp v1
app_id: gatesmoke:01900000-...
agents:
  - cursor-01
  - claude-code-01
set_at: 2026-05-13T18:42:00Z
set_by: cursor
-->
```

The validator accepts either form.

## Writer-side helper

`bootstrap/stamp-tool-memory.sh --adapter <name> --file <path> --agent-id <id>`
prepends (or augments) a valid stamp before the adapter writes non-trivial
content. Behaviour summary:

- Refuses parent-template repos (`parent_template_refusal`).
- Requires `_system/app-local-namespace.json` to be present and to expose a
  non-empty `app_id`, else `namespace_missing`.
- `agent_id` must match the agent-instance grammar, else `agent_id_invalid`.
- `<file>` must resolve under `_system/tool-memory/` of the target,
  else `file_outside_tool_memory`.
- Idempotent on the same `(adapter, agent_id)` — emits `action=unchanged`.
- Adding a second `agent_id` rewrites the stamp into the `agents:` list form
  — emits `action=augmented`.
- If a pre-existing stamp's `app_id` does not equal the active namespace, the
  helper refuses with `app_id_mismatch` (it never silently rewrites a stamp
  from another app).

Adapters SHOULD invoke this helper before appending memory content; the
validator below remains the post-write safety net.

## Validator

`bootstrap/check-tool-memory-isolation.sh` enforces this contract. In
downstream-app mode it walks every `_system/tool-memory/*.md`, classifies
each as trivial/non-trivial, and asserts the stamp on the non-trivial set.
In parent-template mode it asserts every file is trivial — the template
must ship empty stubs only.

Failure codes:
- `parent_template_has_content` — template-mode file holds non-trivial content
- `stamp_missing` — downstream-mode non-trivial file with no stamp block
- `stamp_malformed` — stamp present but a required field is missing/invalid
- `app_id_mismatch` — stamp `app_id` does not equal the active namespace
- `agent_id_invalid` — stamp `agent_id` violates the naming grammar

## Anti-policy

- Do NOT add stamps to empty stub files in the template. Empty stubs are
  the only legal template-side state.
- Do NOT symlink a tool-memory file across two downstream apps — even
  with a matching stamp, the `app_id` will diverge from the symlink
  target's namespace.
- Do NOT use a stamp from a different app as a starting template; the
  writing agent must mint a fresh stamp with its own `app_id`.
