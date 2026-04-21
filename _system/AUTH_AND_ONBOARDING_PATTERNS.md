# Authentication And Onboarding Patterns

Use this when designing **login**, **registration**, **guest access**, and **local/dev testing** for
apps generated from or aligned with AIAST.

## Non-negotiable security rules

1. **Never commit real credentials** — no default passwords, no “root admin” emails, and no seed
   secrets in source control, templates, fixtures, screenshots, or docs. Use **environment
   variables** (e.g. `SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD`) loaded from a **gitignored** file
   such as `.env.local` or deployment secrets.
2. **Never paste production passwords into chats or tickets** — treat them as compromised and
   **rotate** them wherever they were used.
3. **Production** must not silently create privileged accounts from env unless an operator
   explicitly enables that path; prefer **one-time setup wizards**, **invite links**, or **identity
   provider** flows.
4. Hash passwords with a **slow, memory-hard** password hash (e.g. bcrypt, argon2) appropriate to
   your stack; never store plaintext passwords in the database.

## Dev / QA bootstrap admin (optional)

For **local** or **staging** live testing without registering through the UI:

- Define **empty** placeholders in `ops/env/.env.example` (see runtime template) and document the
  variables in `README` or `QUICKSTART`.
- Read values only from the environment at **seed** or **migrate** time (e.g. Prisma seed, Django
  `createsuperuser` script, SQL migration guarded by `APP_ENV=development`).
- Gate execution with an explicit flag, e.g. `SEED_DEV_ADMIN=true`, default **false**.
- After first successful login, **disable** the seed path or force password change.
- CI should run with **no** seed admin unless a dedicated test job injects ephemeral credentials.

This replaces the anti-pattern of a “built-in” admin account checked into the repo.

## Product pattern A — Optional registration (progressive trust)

**Best for:** dashboards, tools, and exploratory products where discovery matters.

- The app **launches** into a useful surface (demo data, read-only views, or local-only mode).
- **Persisted** data, **multi-user** workspaces, **billing**, or **sensitive** operations require
  sign-in or account creation.
- Make the upgrade path obvious: “Sign in to save” / “Create workspace to continue.”

**Pros:** Faster evaluation, fewer abandoned sign-up walls.  
**Cons:** More careful **authorization** design (guest vs member); ensure guests cannot hit
privileged APIs.

## Product pattern B — Auth before shell (gate the app)

**Best for:** HR, finance, health, admin consoles, or any app where **every** screen is sensitive.

- User hits **login** (or SSO) before the main layout.
- No anonymous “inside” routes except public marketing/legal pages.

**Pros:** Simpler auth matrix; smaller attack surface for anonymous users.  
**Cons:** Harder to “try before you buy”; still use **staging** credentials via env for QA, not
hardcoded users in git.

## Choosing a pattern

| Signal | Prefer |
|--------|--------|
| Public marketing + private app | Pattern B for app; Pattern A for landing/marketing only |
| B2B SaaS with trials | Often Pattern A with clear save/sync gates |
| Mobile consumer with optional account | Pattern A common |
| Compliance-heavy data | Pattern B |

If a hybrid feels right, document the rules in `PRODUCT_BRIEF.md` and enforce them in middleware /
route guards consistently.

## Testing without registering (operators)

- Use **seed scripts** + env vars for staging.
- Use **test users** created in fixture data for automated tests (random passwords, never reused
  across environments).
- Prefer **magic-link** or **OTP** dev tools only in non-production with explicit flags.

## Related contracts

- `_system/SECURITY_HARDENING_CONTRACT.md` — session, cookies, logging.
- `_system/MODERN_UI_PATTERNS.md` — navigation deduplication and IA.
- `_system/API_DESIGN_STANDARDS.md` — authenticated vs public endpoints.
