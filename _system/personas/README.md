# `_system/personas/` — App persona bolt-on slot

This directory is the **modular attach point** for the app-specific
world-class persona.

- **In the parent template repo:** empty (only this `README.md` +
  `.gitkeep`). Shipping an `APP_PERSONA.md` here would embed app-specific
  truth in the template and violate `TEMPLATE_NEUTRALITY_POLICY.md`.
- **In a downstream app repo:** once the app is defined and dev has
  started (`bootstrap/check-app-definition-state.sh` → `app_defined`), an
  agent runs the cross-agent command **`forge-app-persona`** to generate
  `_system/personas/APP_PERSONA.md` for *this* app, per
  `_system/APP_PERSONA_CONTRACT.md`.

`APP_PERSONA.md` is loaded as an **optional overlay** (see `LOAD_ORDER.md`
"Targeted optional load" and `READ_BUNDLES.md`): present → every agent in
this repo inherits the app's world-class persona on top of the generic
meta-system; absent → the meta-system runs exactly as before. Bolt-on,
never a hard dependency.
