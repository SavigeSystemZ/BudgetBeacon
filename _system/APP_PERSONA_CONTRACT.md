# App-Specific World-Class Persona — Contract

The meta-system ships **template-safe, reusable** routing personas
(`APP_ARCHETYPE_PERSONA_CATALOG.md`). This contract defines the **next
layer**: a single **app-specific world-class persona**, *generated inside a
downstream app repo for that one app*, that bolts onto the meta-system so
every agent launched there builds that specific app at a world-class bar.

It is **modular and additive**: the generic meta-system is unchanged; the
app persona is an optional overlay loaded *if present*.

## Where it lives (the bolt-on slot)

- `_system/personas/APP_PERSONA.md` — the generated app persona.
- The parent template repo ships `_system/personas/` with **only**
  `README.md` + `.gitkeep`. It MUST NOT contain `APP_PERSONA.md`
  (template neutrality: no app-specific truth in the template — see
  `TEMPLATE_NEUTRALITY_POLICY.md`). The file exists only in downstream
  app repos, generated there.

## When it is forged (trigger)

Not at blank state. Forge (or refresh) the persona once the app is
**defined and development has started** — i.e.
`bootstrap/check-app-definition-state.sh` reports `app_defined`
(`PRODUCT_BRIEF.md` filled and real source under `app/src/`). Use the
cross-agent command **`forge-app-persona`** (see
`.cursor/commands/forge-app-persona.md`; per `HOST_ADAPTER_POLICY.md` it is
authoritative for every agent regardless of host namespace).

Re-run it whenever the app's domain, stack, or quality bar materially
changes — the persona is living, not one-shot.

## Required sections of `_system/personas/APP_PERSONA.md`

1. **App identity** — name, one-line purpose, primary users (from
   `PRODUCT_BRIEF.md`); selected archetype id (via
   `APP_ARCHETYPE_ROUTING_MATRIX.md`).
2. **Domain mastery** — the expert lens this app demands (the domain
   knowledge, regulations, edge cases a world-class engineer of *this*
   product would carry).
3. **Stack mastery** — the chosen stack/runtime and the idiomatic,
   high-craft patterns and pitfalls specific to it for this app.
4. **Quality bar** — what "world-class" means concretely for this app
   (performance, UX, reliability, security/privacy posture from the
   archetype), as checkable standards.
5. **App-specific review lenses** — the extra things to scrutinize in
   review beyond the generic gates, unique to this product.
6. **Anti-patterns** — failure modes and shortcuts that would betray this
   specific app; explicit "never do" list.
7. **Definition of done** — app-specific completion criteria layered on
   `DELIVERY_GATES.md`.

## How it attaches (load model)

- It is referenced as an **optional overlay** in `LOAD_ORDER.md` and
  `READ_BUNDLES.md`, loaded **only when the file exists**, *after* the
  generic archetype catalog — it refines/extends the reusable routing
  lens with app truth; it never replaces meta-system contracts.
- Precedence: it sharpens craft and domain judgment. It cannot override
  `INSTRUCTION_PRECEDENCE_CONTRACT.md`, security, or validation gates.

## Authoring rules

- App-specific and concrete — no generic filler; if a section would be
  generic, the persona is not yet doing its job.
- Derived from this repo's own `PRODUCT_BRIEF.md`, `app/`, chosen
  archetype — never from another app's truth.
- Plain agent-neutral markdown; usable by every agent.
