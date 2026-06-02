# Sync Relay — Deploy Guide (M10)

Budget Beacon syncs devices with end-to-end-encrypted CRDTs (Yjs). The relay
only forwards **ciphertext** between your devices — it never holds the
household key and cannot read your data. Sync is **opt-in**; local-only is the
default.

You have two interchangeable relays in `relay/`:

| Path | Use | Status |
|------|-----|--------|
| `relay/node/server.mjs` | Run on any box / VPS / localhost | **Validated** — runs today, no account needed |
| `relay/src/worker.ts` | Cloudflare Worker + Durable Objects (edge, free tier) | Code-complete — validate on your first `wrangler deploy` |

Both speak the same `y-websocket` protocol and the same HMAC join-token scheme,
so the app connects to either with the same settings.

## 1. Pick a shared relay secret

The relay is gated by an HMAC join token signed with a shared `RELAY_SECRET`.
This stops strangers from opening rooms on your relay; it is **not** your
encryption key. Generate one:

```bash
openssl rand -base64 32
```

Use the same value in the relay env **and** in the app (Settings → Sync →
relay secret). Leave it empty everywhere to run open (localhost/dev only).

## 2a. Node relay (simplest)

```bash
cd relay
npm install
RELAY_SECRET="<your-secret>" PORT=1234 npm start
```

Point the app at `ws://localhost:1234` (or `wss://your-host` behind TLS).
Put it behind a reverse proxy (Caddy/Nginx) for `wss://` in production.

## 2b. Cloudflare Worker relay (edge, ~free)

```bash
cd relay
npm install
npx wrangler login                 # opens browser; needs your Cloudflare account
npx wrangler secret put RELAY_SECRET   # paste the secret from step 1
npx wrangler deploy
```

Wrangler prints a URL like `https://budget-beacon-relay.<subdomain>.workers.dev`.
Use it in the app as `wss://budget-beacon-relay.<subdomain>.workers.dev`.

Notes:
- Durable Objects are SQLite-backed (`new_sqlite_classes` in `wrangler.toml`),
  available on the Workers free plan.
- One Durable Object instance per household room holds a server-side Y.Doc, so a
  device receives changes made while it was offline.

## 3. Connect the app

1. Settings → **Sync & Account** → create an account (this also issues recovery
   codes — save them).
2. Enter the **Relay URL** (`wss://…`) and the **relay secret**.
3. **Start sync.** The status badge shows `connected`.
4. On a second device: sign in with the same email + passphrase (or add the
   device with a recovery code), enter the same relay URL + secret, Start sync.

## Threat model (short)

- The relay sees: room id (your household id), connection timing, ciphertext
  size. It does **not** see plaintext, the household key, or your passphrase.
- A leaked join token lets someone connect to a room and see ciphertext only.
- Losing your passphrase: recover with a recovery code (`RECOVERY.md`).

See `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md` for the full design.
