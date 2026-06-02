# Repository Identity — read before doing anything

This file resolves a single question every agent must answer on entry:
**what is this repo, and what is my job here?**

The answer is in `_system/.aiast-role.json` (`role` field).

---

## If `role` = `downstream-app`  →  THIS IS A BLANK APP-BUILDING REPO

**This repository is NOT the meta-system template. It is a blank
application-building repo that carries a local copy of the meta-system so an
agent can build a specific app inside it.**

Do **not**:
- treat this as the AIAST meta-system template to be developed or
  re-scaffolded,
- edit/extend `_system/` or `bootstrap/` as if improving the meta-system,
- start writing application code before the app is defined.

Your job, in order:

1. **Determine if the app is defined yet.** It is *undefined* if
   `PRODUCT_BRIEF.md` is still the empty template form and `app/` has no
   real source. Check `bootstrap/check-app-definition-state.sh` (or read
   `PRODUCT_BRIEF.md` + `app/src/`).
2. **If undefined → define it first.** Interview the operator: what is the
   app, who is it for, what does success look like? Capture answers in
   `PRODUCT_BRIEF.md`. Do not guess a product into existence silently.
3. **Then build it with the local meta-system.** Use `_system/` (planning,
   `VALIDATION_GATES.md`, `DELIVERY_GATES.md`, golden examples, host
   adapters) to design and grow the application **into `app/`** (see
   `app/README.md`). The meta-system is the tool; the app in `app/` is the
   product.
4. **Forge the app's persona and fill its context.** Once the app is
   defined and dev has started, run the cross-agent `forge-app-persona`
   command (a tailored world-class persona at
   `_system/personas/APP_PERSONA.md`, see `_system/APP_PERSONA_CONTRACT.md`)
   and the `fill-app-context` command (app-specific context files under
   `_system/app-context/`, see `_system/APP_CONTEXT_FILE_MATRIX.md`). Both
   bolt onto the meta-system; re-run them as the app evolves.
5. **Keep the boundary.** Application code stays in `app/`, independent of
   `_system/` and `bootstrap/` (see `AGENTS.md`).

The blank state is not an error — it is the expected starting point. The
correct first move is to establish the app, not to build the meta-system.

---

## If `role` = `parent-template`  →  THIS IS THE META-SYSTEM TEMPLATE ITSELF

This tree is the canonical AIAST installable template (the operating-layer
master copy, not an application sandbox). Work here improves the
meta-system that downstream app repos inherit. Follow the normal template
contracts in `AGENTS.md` and the git-side mirror model in
`GIT_SIDE_MIRROR_POLICY.md`.

---

## If the role file is missing or unreadable

Treat the repo as `downstream-app` (the safe default — a blank app repo
awaiting its app definition) and tell the operator the role file is
missing so it can be restored via `bootstrap/init-project.sh --role`.
