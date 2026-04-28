# Sync & Dual-Account Architecture

> Created 2026-04-28 alongside M6 close. Inserts two new milestones — **M10 (Auth + Cross-Device Sync)** and **M11 (Joint Household / Linked Accounts)** — into the roadmap. Replaces the older "Beacon Bridge" sketch in `INTEGRATIONS_STRATEGY.md` Domain 5; that section is retained for the legacy `BeaconBridgeRoute` shape but the real plan lives here.

## Why now

The user asked for: same login syncing data across phone ↔ web ↔ phone, and the ability to link two accounts (one household, two operators) with merge. The current app is 100 % local-first Dexie/IndexedDB with no auth, no users, no server. None of that is wrong — local-first is a feature — but multi-device + multi-operator requires identity, transport, conflict policy, and a sharing model.

This document picks an architecture and sequences the work so each step is shippable on its own. It does **not** approve a recurring cloud bill or a privacy regression: the chosen path keeps user budget data end-to-end encrypted on any server we use.

## Tradeoff space (the three options I weighed)

| Option | UX | Privacy | Effort | Cost |
|---|---|---|---|---|
| **A. Cloud-backed (Supabase / Firebase / custom Node+Postgres)** | Best — log in anywhere, instant sync | Server holds plaintext budget data unless we also do E2EE on top, which then negates most of the framework's features | Medium | Recurring hosting + per-user costs |
| **B. E2EE CRDT + thin relay** (Yjs / Automerge over a relay we control) | Strong — log in anywhere, server only sees ciphertext | Best — server can be hostile and still leak nothing | High (CRDT ergonomics, key management, relay) | Low — small relay, no DB |
| **C. Pure peer / LAN / WebRTC** | Weak — both devices must be online together; no "log in from anywhere" | Best — no server | Medium | Free |

**Recommendation: B (E2EE CRDT + thin relay).** It's the only path that delivers the full UX the user asked for (cross-platform login, joint household merge) without storing readable household financial records on any server. Yjs is mature, has IndexedDB persistence, conflict-free merge for joint households, and works fine in a Capacitor WebView. Cost stays near zero (one tiny relay, no per-user DB).

**Fallback if B is too heavy:** ship **A with a client-side encryption envelope** (Supabase storing only AES-GCM ciphertext keyed by a passphrase the user chooses). Less elegant than CRDT merge, but ~3× faster to deliver and the envelope keeps the privacy property.

This decision is not final until the user signs off; if the user prefers A or C, the milestones below restructure accordingly.

## Identity model

- **Account.** One person. Has email + passphrase. Passphrase derives a key (Argon2id) that wraps a long-lived per-account keypair. Server never sees the passphrase.
- **Device.** A specific browser/phone install of Budget Beacon, registered to an Account. Holds the unwrapped account key in OS keystore where available (Capacitor Keychain / SecureStorage), in-memory otherwise.
- **Household.** A logical container for budget data. One Household can be owned solo, or shared between two linked Accounts (M11). Each Household has its own data-encryption key, sealed to each member Account's public key.
- **Document IDs are stable across devices** so CRDT merge converges. M5/M6 already use `createId()` UUIDs which is good.

## Milestone insertion

Existing M0–M9 keep their numbering. New milestones:

### M10 — Auth + Cross-Device Sync (single account, multi-device)

**Outcome.** A user can create an account, log in on web and phone, and see the same budget data on both. No joint accounts yet — that's M11.

**Slices (each commit-sized):**

1. **M10.1 Auth scaffolding.** New `src/modules/auth/` with `signup`, `login`, `logout`. Argon2id passphrase → key derivation. Account record + keypair generated client-side. Local-only at first — no server. Adds a Login screen the user can dismiss to keep the existing local-only flow working (back-compat).
2. **M10.2 Encryption envelope.** New `src/modules/crypto/` wrapping `crypto.subtle` AES-GCM. Adds `encryptForSync(record, householdKey)` and `decrypt(envelope, householdKey)`. Round-trip test in the existing vitest harness. No network yet.
3. **M10.3 CRDT layer.** Add Yjs as a dep. Mirror the 18 Dexie tables into a Yjs document. Local-only — every Dexie write also updates the Y.Doc and vice versa. Two-way sync test that doesn't touch the network.
4. **M10.4 Relay + transport.** Tiny Node+ws relay (~150 LOC) deployed to a cheap VPS or Cloudflare Worker. Client connects via `y-websocket`. Server only sees ciphertext (the Y.Doc updates are wrapped with the household key before send). Add a "Sync status" indicator in the bottom nav.
5. **M10.5 Onboarding integration.** Existing `OnboardingWizard` learns to either continue local-only or sign up for sync. The local-only Dexie data migrates into the user's Household on first sync.
6. **M10.6 Mobile parity smoke.** Real-device APK install, log in, verify data appears.

**Done when:** A second device logging in with the same email + passphrase shows the same income, bills, transactions, and documents within ~5 seconds.

**Feature flags introduced:**
- `authEnabled` — gates the login screen. Default off until M10.5.
- `syncRelay` — gates the websocket connection. Default off until M10.4 ships.
- The existing `featureFlags.syncBundleExport` / `syncLocalNetwork` / `syncWebRTC` from the old Beacon Bridge plan remain false; they're a different transport class and can be revisited post-M11 if useful.

**Risks.**
- Yjs + Dexie bidirectional bridge has edge cases on document blobs (vault). Mitigation: encode blobs with the existing base64 helper and store as Y.Map values, not Y.Doc binary fragments.
- Argon2id is slow on low-end Android. Mitigation: cache the derived key in memory for the session; only re-derive on app cold start.
- A bad relay disconnect must not corrupt local Dexie. Mitigation: Y.Doc is the source of truth; Dexie is a materialized view rebuilt from Y.Doc on conflict.

### M11 — Joint Household / Linked Accounts (two accounts, one household)

**Outcome.** Two Accounts can be linked to the same Household. Both see the same budget. Edits from either side merge automatically (CRDT handles concurrency). Either can leave the household (data stays with whoever owned it first; the other gets an export).

**Slices:**

1. **M11.1 Invite flow.** Account A → Settings → "Invite partner." Generates a one-time code containing the household-key wrapped to the invitee's public key (after they sign up). Code is short enough to type or share via QR.
2. **M11.2 Accept flow.** Account B enters the code, gets the household key, joins. From this point both accounts have the household key and can decrypt updates.
3. **M11.3 Per-record ownership UX.** Income, bills, debts, etc. already have `personId`. Surface "owned by Person A / Person B / Joint" labels. Add a per-record visibility toggle (private to one Account vs shared) — record-level encryption with two keys (private records sealed only to one account's pubkey).
4. **M11.4 Activity log.** New `householdActivity` Dexie table. CRDT merge produces an audit trail: "Person B added income $1450 from SSDI on 2026-05-02." Visible in Settings → Household.
5. **M11.5 Leave / unlink.** Either account can leave. The leaving account's local data snapshot is exported as a v3 backup. The remaining account keeps the household. Re-keying the household after a leave is required (rotate key, re-seal to remaining members).
6. **M11.6 Permissions polish.** A "view-only" mode for the second account if the first wants to share visibility but not edit (M11 stretch — can defer).

**Done when:** Two devices with two different accounts both showing the same household budget, each making edits that converge.

**Risks.**
- Conflict on the same field (e.g. both edit `incomeSources[x].amount`). Yjs handles last-write-wins per field with deterministic merge; UI should show recent edits via the activity log.
- Invite code leakage. Mitigation: codes expire in 24 h, single-use, and don't carry the household key directly — they carry an ephemeral key that the relay swaps for the wrapped household key only on accept.

## Where this lands in the existing roadmap

Reading order in `ROADMAP.md` becomes:

```
M6 — Vault + OCR  (DONE 2026-04-28)
M7 — AI Assistant
M8 — Tax/Credit/Debt deepening
M9 — Android/Web final polish + RC
M10 — Auth + Cross-Device Sync          ← NEW
M11 — Joint Household / Linked Accounts ← NEW
M12 — Public release / install docs polish (was M9 release-candidate concerns split)
```

Why not earlier? Sync requires a stable data model. M6 just changed it again (extraction provenance pointers). Waiting until after M7 (AI may also touch records) and M8 (tax/credit/debt deepening) keeps us from re-keying / re-mirroring records mid-flight.

## What needs the user's sign-off before code starts

- Pick A vs B vs C. (Recommendation: B.)
- If B: green-light a small relay (free Cloudflare Worker is fine; estimate $0–$5/mo at low scale).
- Comfort with passphrase model — losing the passphrase means losing access (since server only stores ciphertext). Mitigation: a one-time recovery code printed at signup that the user is told to store in a password manager.

## Out of scope (intentionally not in M10 / M11)

- Multi-household per account (e.g. me + spouse household, plus me + roommate household). Possible later; not needed for the stated use case.
- More than two members per household. The data model supports N members but the UX is designed around two. Three+ is a polish item.
- Web-only "shareable read-only link." Different transport, different threat model.
