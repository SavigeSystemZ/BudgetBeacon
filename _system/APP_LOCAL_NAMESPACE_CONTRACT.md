# App-Local Namespace Contract

Every downstream AIAST install owns exactly one **app-local namespace record**
at `_system/app-local-namespace.json`. This record is the authoritative answer
to "which app is this?" for every cross-cutting boundary AIAST enforces: MCP
servers, agent leases, tool memory, port allocations, browser profiles, and
database / cache scoping.

This contract is part of the App Builder isolation finalization. See
`_META_AGENT_SYSTEM/AIAST_MCP_AGENT_ISOLATION_FINALIZATION_PLAN_V2.md` §6 for
design rationale, and `_META_AGENT_SYSTEM/ISOLATION_AUDIT_2026-05-11.md` §5 for
slice classification.

## Files

| Path | Purpose |
|---|---|
| `_system/.aiast-role.json` | Sentinel: `parent-template` vs `downstream-app`. Read first by every script that must distinguish. |
| `_system/app-local-namespace.json` | The record itself, present only in downstream apps. |
| `_system/app-local-namespace.template.json` | Render template used by `init-app-namespace.sh`. |
| `_system/schemas/app-local-namespace.schema.json` | JSON Schema (draft 2020-12) validated in `--strict`. |

## Identity model

```
app_id = "<app_slug>-<first 8 hex of app_uuid>"
```

- **`app_uuid`** — globally unique, UUIDv7 preferred (time-sortable), immutable.
- **`app_slug`** — lower-kebab handle. Renamable via `rename-app.sh`. Slug rename
  does **not** propagate into `app_id`; that requires an explicit operator-flagged
  reset.
- **`app_id`** — composite. The thing every namespace string is built from.

Rationale: pure slug collides across machines; pure UUID is unreadable in logs
and shells. The composite is both human-readable and unique. The 8-hex suffix
keeps collision probability below 1e-9 per million apps.

## Namespace fields

```json
"namespaces": {
  "mcp":                 "<app_id>:mcp",
  "agents":              "<app_id>:agents",
  "tool_memory":         "<app_id>:tool-memory",
  "ports":               "<app_id>:ports",
  "db":                  "<app_id_db>",
  "cache_keys":          "<app_id>:",
  "browser_profile_dir": "<repo_root_realpath>/.local/browser-profiles/<app_id>"
}
```

Where `<app_id_db>` is `<app_id>` with `-` replaced by `_` and a trailing `_`,
so that the string is valid as a SQL schema or table prefix.

Downstream MCP server configs, agent instance records, tool-memory entries,
allocated ports, browser profiles, and DB schemas / Redis prefixes MUST be
built from these fields. Validators in later slices (S5 MCP bleed, S6 tool
memory, etc.) enforce conformance.

## Immutability and rename

```
immutable_fields:    [app_uuid, app_id, created_at]
rename_allowed:      [app_name, app_slug]
reset_requires:      explicit-operator-flag
```

- Renaming the slug updates `app_slug` and appends a `renamed` event to
  `lifecycle.events[]`. `app_id` does **not** change. This preserves continuity
  for any lease, audit log, or cross-repo registry entry already keyed on the
  composite ID.
- A *reset* (regenerating `app_uuid` and `app_id`) is destructive to lineage
  and requires an explicit flag on `init-app-namespace.sh --reset`. The old
  identity is preserved in `lifecycle.events[]` as a `reset` event.

## Boundary fields

- **`repo_root`** — absolute path at generation time.
- **`repo_root_realpath`** — `realpath(repo_root)`. Defeats symlink-based
  bleed where a sibling app symlinks into this repo's tree.
- **`allowed_repo_root`** — canonical write boundary; equal to
  `repo_root_realpath` in v1.
- **`forbidden_roots`** — resolved-at-generation list of paths this app's MCP
  servers and agents MUST refuse to open for write. Includes the parent
  template path and any sibling app paths known at generation time.

Resolving forbidden roots *at generation* (not at validator time) means a
later filesystem change (new sibling app appearing) does not silently widen
or narrow this app's boundary. Re-run `init-app-namespace.sh --refresh` to
re-resolve.

## Sentinel: `_system/.aiast-role.json`

Every script that distinguishes "template repo" from "downstream app" MUST
read this sentinel first.

```json
{
  "schema_version": "1.0.0",
  "role": "parent-template" | "downstream-app"
}
```

Refusal matrix:

| Script | Refuse if role is | Reason |
|---|---|---|
| `init-project.sh` | `parent-template` | Would scaffold downstream artifacts into the template |
| `init-app-namespace.sh` | `parent-template` | App-local namespace only exists in downstream apps |
| `check-app-local-namespace.sh` | (no refusal; behavior differs) | In template: verifies template + schema + role sentinel. In downstream: verifies live record. |
| `scaffold-system.sh --downstream` | `parent-template` | Same as `init-project.sh` |
| `_TEMPLATE_FACTORY/*.sh` | `downstream-app` | Maintainer-only flows |

The sentinel is read-only at runtime; it is written exactly once per repo
during scaffold (or, for the parent template, ships in the repo).

## Generation flow (`init-app-namespace.sh`)

1. Read `_system/.aiast-role.json`. Refuse if `parent-template`.
2. Refuse if `_system/app-local-namespace.json` already exists, unless
   `--refresh` or `--reset` is passed.
3. Resolve `repo_root_realpath`.
4. Mint `app_uuid` (UUIDv7 if available; v4 fallback).
5. Derive `app_id` from operator-supplied `--slug` and the UUID prefix.
6. Read `aiast_template_version` from `AIAST_VERSION.md`.
7. Read `aiast_install_id` from `_system/.template-install.json` if present.
8. Resolve `forbidden_roots`: parent template path (if known via
   `--parent-template-path`), plus any sibling apps found by scanning the
   common parent directory if `--scan-siblings` is set.
9. Render `_system/app-local-namespace.template.json` with the resolved
   values; write to `_system/app-local-namespace.json`.
10. Validate the freshly written record against the schema. Refuse on any
    schema violation.
11. Emit a JSON envelope: `{ "ok": true, "app_id": "...", "path": "..." }`.

Operator flags:
- `--slug <slug>` (required for create)
- `--name <human-name>` (defaults to slug)
- `--parent-template-path <abs-path>` (optional)
- `--scan-siblings` (off by default)
- `--refresh` (regenerates derived fields, preserves identity)
- `--reset` (regenerates identity; requires explicit confirmation)

## Validation invariants (`check-app-local-namespace.sh`)

The validator runs in two modes based on `_system/.aiast-role.json`:

### Parent-template mode

- `_system/.aiast-role.json` exists and parses; `role == "parent-template"`.
- `_system/app-local-namespace.template.json` exists, parses, validates the
  schema as a placeholder pattern (i.e. every `__FIELD__` token resolves to
  a known field).
- `_system/schemas/app-local-namespace.schema.json` exists and is a valid
  JSON Schema (draft 2020-12).
- No live `_system/app-local-namespace.json` present (would indicate the
  template repo has been mistakenly scaffolded as a downstream app).

### Downstream-app mode

- `_system/.aiast-role.json` exists; `role == "downstream-app"`.
- `_system/app-local-namespace.json` exists and validates against the schema.
- `app_id` matches the documented pattern.
- `repo_root_realpath` equals `realpath(<repo-root-arg>)`.
- `allowed_repo_root == repo_root_realpath`.
- No entry in `forbidden_roots` equals `repo_root_realpath`.
- `namespaces.browser_profile_dir` lives under `repo_root_realpath`.
- `app_uuid` is a valid UUID; `app_id` ends in the first 8 hex of `app_uuid`.
- All `lifecycle.immutable_fields` are present.

Both modes exit non-zero with a structured JSON envelope on any failure.

## Cross-references

- `MCP_PROJECT_ISOLATION_POLICY.md` (S4 extends to consume `namespaces.mcp`).
- `AGENT_INSTANCE_ISOLATION_POLICY.md` (S2 will consume `namespaces.agents`).
- `TOOL_MEMORY_REDIRECTION_PROTOCOL.md` (S6 extends with `namespaces.tool_memory`).
- `TEMPLATE_MOS_AND_BUILDER_APP_BOUNDARY.md` (this contract is the canonical
  identity layer that boundary doc references).
- `_META_AGENT_SYSTEM/AIAST_MCP_AGENT_ISOLATION_FINALIZATION_PLAN_V2.md` §6.

## Acceptance (S1 milestone gate)

This slice is complete when:

1. Schema validates as draft 2020-12 (jsonschema validator green).
2. Template file renders with `init-app-namespace.sh` into a record that
   validates against the schema.
3. `check-app-local-namespace.sh` exits zero in parent-template mode against
   this repo.
4. Re-running `init-app-namespace.sh` without `--refresh` / `--reset` refuses
   to overwrite an existing record (F-02 case).
5. Fuzzed namespace records (random key drop, type swap) are rejected by the
   validator (F-13 case).
