# Agent Installer And Host Validation Protocol

Binding guidance for agents building **applications** with AIAST: when and how to
scaffold installers, perform **production-like** host installs (including
desktop integration), govern ports and dependencies safely, and **re-verify**
that the app **launches and renders** after large changes.

This applies to **shipped-app** delivery. AIAST template lifecycle (copy/update
into a repo) remains under `INSTALLER_AND_UPGRADE_CONTRACT.md`.

## Canonical references (read before implementing)

| Topic | Document / surface |
|-------|------------------|
| Cross-platform installers, operator menu, early scaffold milestone | `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md` |
| Port allocation, collision checks, loopback-first | `ports/PORT_POLICY.md`, `registry/port_*.yaml`, `ops/install/lib/port_allocator.py`, `tools/preflight_port_scan.py`, `tools/check-port-collisions.py` |
| Security baseline for services and networks | `SECURITY_HARDENING_CONTRACT.md`, `PROMPT_DOCKER_NETWORK_POLICY.md` |
| Validation tiers | `VALIDATION_GATES.md` |
| Handoff evidence | `HANDOFF_PROTOCOL.md` |
| Runtime scaffold checks | `bootstrap/check-runtime-foundations.sh`, `bootstrap/check-network-bindings.sh`, `bootstrap/system-doctor.sh` |

## 1. Early development: installers and setup are not optional

- As soon as the app is **first launchable and renderable** on a dev machine
  (dev server, binary, or container), **create or refresh** install and
  distribution scaffolds per `CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`
  (minimum launch milestone). Do **not** wait for feature-complete “release polish.”
- Ensure **`ops/install/`** (or platform equivalent), **`ops/compose/`** when
  applicable, and **`distribution/platforms/*`** are coherent with
  `bootstrap/generate-runtime-foundations.sh` outputs and project docs.
- Dependencies (language runtimes, system packages, DB engines) must be
  **declared** (lockfiles, compose images, package lists)—not silently assumed
  on the host.

## 2. Production-like host testing (dogfood the real path)

Agents must plan for operators (and developers) to install to a **real host**
for live testing:

- **Install** path exercises first-time placement, dependency satisfaction, and
  config generation where the product supports it.
- **Desktop integration** (Linux `.desktop`, Windows Start menu / shortcuts,
  macOS app bundle or documented launcher) must be **documented and scripted**
  where the product targets desktop; stub or TODO only when the surface is
  explicitly out of scope (e.g. headless API only).
- After install, the user must be able to **start the app** from the documented
  entrypoint—not only from a developer-only CLI.

Use **`repair`**, **`uninstall`**, and **`purge`** flows from the operator menu
(`CROSS_PLATFORM_DISTRIBUTION_AND_INSTALLER_STANDARD.md`) so broken or partial
installs are recoverable without manual archaeology.

## 3. Robust installer behavior (required direction)

Install and lifecycle scripts should be **explicit, idempotent where possible,
and failure-aware**:

| Capability | Expectation |
|------------|-------------|
| **Errors** | Actionable messages; documented exit codes; no silent partial state. |
| **Logging** | App-owned paths; never log secrets. |
| **Dry-run** | Where feasible for filesystem and service mutations. |
| **Repair** | Restore missing files, units, permissions without destroying user data. |
| **Uninstall** | Remove binaries, services, desktop entries; optional data retention prompt. |
| **Dependencies** | Satisfy or fail with clear install instructions. |
| **Databases** | If provisioned: version-pinned images or packages, migrations documented, credentials not committed. |
| **Health** | `status` / `doctor` surfaces report versions and listeners. |

## 4. Ports: free, non-default, governed, secure

- **Never** hardcode common dev ports (`3000`, `8080`, `5432` on host, etc.)
  without governance. Follow `ports/PORT_POLICY.md`.
- **Allocate** before binding: use `port_allocator.py` and persist assignments
  in `registry/port_assignments.yaml` / `ops/env/.env` in the **same change set**
  as compose or systemd updates.
- **Preflight:** run `tools/preflight_port_scan.py` and
  `tools/check-port-collisions.py` before claiming install or compose work complete.
- Prefer **loopback** (`127.0.0.1`) for local services unless the threat model
  requires LAN exposure; document overrides.

## 5. After large workloads: launch and render checks

When a session (or series of commits) materially changes runtime, UI, routing,
build, or install surfaces:

1. Run **project-appropriate** smoke: start the app via the **same path an
   operator would use** (or documented dev equivalent if install is not yet wired).
2. Confirm **critical UI renders** (main window/page loads without blank or
   error screen) for GUI or web apps; for APIs, confirm a **health** or **root**
   response.
3. If full UI automation is unavailable, **state the gap** in the handoff and
   lower confidence; do not imply “verified” without evidence.
4. Re-run **`bootstrap/check-runtime-foundations.sh`** and
   **`bootstrap/check-network-bindings.sh`** when install, compose, or packaging
   files changed.

Treat this as part of **`VALIDATION_GATES.md`** Tier 4 when install/launch
surfaces are touched, and as a **discipline checkpoint** after large refactors
even when tier would otherwise be lower.

## 6. Questions to resolve when unclear

Ask the user (or record in `OPEN_QUESTIONS.md`) when:

- Target platforms for install (desktop vs server-only vs mobile-only) are ambiguous.
- Whether production DB should be embedded, container-only, or external.
- Elevation model (sudo, installer UAC, flatpak permissions) is undefined.
- Port exposure beyond loopback is required for the product.

## 7. Anti-patterns

- Shipping only `npm run dev` with no path toward installable delivery when the
  product is meant for end users.
- Duplicating port numbers across services or repos without registry updates.
- Claiming “installed and tested” without running install or equivalent smoke.
- Leaving uninstall/repair as “manual steps in README” when scripts are expected
  for the platform.
