/**
 * HMAC join token for the sync relay.
 *
 * The relay is deployed by the operator with a shared `RELAY_SECRET`; the same
 * secret is stored in the app's sync settings. A token authorizes joining a
 * room (householdId) for a limited time and prevents anonymous room squatting
 * / abuse on the relay.
 *
 * This is purely a relay-access control. It is unrelated to the household
 * encryption key — the relay only ever sees end-to-end-encrypted ciphertext,
 * so a leaked join token never exposes data.
 *
 * Token format:  base64url(HMAC_SHA256(secret, `${room}.${exp}`)) + "." + exp
 * where `exp` is a unix-seconds expiry. The relay recomputes and compares.
 */

function bytesToBase64Url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/**
 * Mint a join token for `room`, valid for `ttlSeconds`. Returns null if no
 * secret is configured (the relay is then expected to run in open/dev mode).
 */
export async function mintJoinToken(
  secret: string | null | undefined,
  room: string,
  ttlSeconds = 3600,
): Promise<string | null> {
  if (!secret) return null;
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`${room}.${exp}`)),
  );
  return `${bytesToBase64Url(sig)}.${exp}`;
}
