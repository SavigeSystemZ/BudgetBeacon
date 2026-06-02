import { db, type RecoveryCode } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import { derivePassphraseKey, wrapKey, unwrapKey } from "../crypto/crypto";

/**
 * Single-use account recovery codes.
 *
 * Each code wraps the household key (AES-KW) under a KEK derived from the code
 * itself via the existing PBKDF2 `derivePassphraseKey` (600k iterations, email
 * as salt context). The plaintext code is shown to the user exactly once and
 * never persisted — only its SHA-256 hash, used to look up the wrapped blob on
 * redemption. This lets a user who lost their passphrase regain their data
 * without any server-side secret, preserving the zero-knowledge model.
 */

export const RECOVERY_CODE_COUNT = 10;

// Crockford-style alphabet with visually ambiguous characters removed
// (no I, L, O, U, 0, 1). 30 symbols -> ~4.9 bits each; a 20-char code is ~98 bits.
const ALPHABET = "ABCDEFGHJKMNPQRSTVWXYZ23456789";
const CODE_LENGTH = 20;

/** Normalize for hashing/derivation: uppercase, strip everything non-alphanumeric. */
export function normalizeRecoveryCode(code: string): string {
  return code.toUpperCase().replace(/[^A-Z0-9]/g, "");
}

/** Human-friendly display: 4 groups of 5, e.g. ABCDE-FGHJK-MNPQR-STVWX. */
export function formatRecoveryCode(raw: string): string {
  const n = normalizeRecoveryCode(raw);
  return n.match(/.{1,5}/g)?.join("-") ?? n;
}

/** Cryptographically random code using rejection sampling (no modulo bias). */
function randomCode(): string {
  const maxUnbiased = Math.floor(256 / ALPHABET.length) * ALPHABET.length;
  let out = "";
  while (out.length < CODE_LENGTH) {
    const buf = crypto.getRandomValues(new Uint8Array(CODE_LENGTH));
    for (let i = 0; i < buf.length && out.length < CODE_LENGTH; i++) {
      if (buf[i] < maxUnbiased) out += ALPHABET[buf[i] % ALPHABET.length];
    }
  }
  return out;
}

/** Stable, domain-separated hash of a normalized code (lookup key only). */
export async function hashRecoveryCode(normalized: string): Promise<string> {
  const data = new TextEncoder().encode("beacon-recovery-v1-" + normalized);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(digest))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Generate a fresh set of recovery codes for an account, wrapping the given
 * household key under each. Invalidates (deletes) any previous set for the
 * same email, so "show new recovery codes" always supersedes the old ones.
 * Returns the formatted plaintext codes to display once.
 */
export async function generateRecoveryCodes(
  email: string,
  householdKey: CryptoKey,
  count = RECOVERY_CODE_COUNT,
): Promise<string[]> {
  const normalizedEmail = email.trim().toLowerCase();
  await db.recoveryCodes.where("email").equals(normalizedEmail).delete();

  const now = new Date().toISOString();
  const display: string[] = [];
  const rows: RecoveryCode[] = [];

  for (let i = 0; i < count; i++) {
    const raw = randomCode();
    const kek = await derivePassphraseKey(normalizedEmail, raw);
    const wrappedKey = await wrapKey(householdKey, kek);
    rows.push({
      id: createId(),
      email: normalizedEmail,
      codeHash: await hashRecoveryCode(raw),
      wrappedKey,
      used: false,
      createdAt: now,
    });
    display.push(formatRecoveryCode(raw));
  }

  await db.recoveryCodes.bulkAdd(rows);
  return display;
}

/**
 * Redeem a recovery code: unwrap and return the household key, then mark the
 * code used (single-use). Throws on unknown/already-used codes.
 */
export async function redeemRecoveryCode(email: string, code: string): Promise<CryptoKey> {
  const normalizedEmail = email.trim().toLowerCase();
  const normalized = normalizeRecoveryCode(code);
  if (!normalized) throw new Error("Enter a recovery code.");

  const codeHash = await hashRecoveryCode(normalized);
  const row = await db.recoveryCodes
    .where("[email+codeHash]")
    .equals([normalizedEmail, codeHash])
    .first();

  if (!row) throw new Error("Invalid or unrecognized recovery code.");
  if (row.used) throw new Error("This recovery code has already been used.");

  let householdKey: CryptoKey;
  try {
    const kek = await derivePassphraseKey(normalizedEmail, normalized);
    householdKey = await unwrapKey(
      row.wrappedKey,
      kek,
      { name: "AES-GCM", length: 256 },
      ["encrypt", "decrypt"],
    );
  } catch {
    throw new Error("Recovery code could not unwrap the household key.");
  }

  await db.recoveryCodes.update(row.id, { used: true, usedAt: new Date().toISOString() });
  return householdKey;
}

/** How many unused recovery codes remain for an account (for Settings display). */
export async function countUnusedRecoveryCodes(email: string): Promise<number> {
  const normalizedEmail = email.trim().toLowerCase();
  const rows = await db.recoveryCodes.where("email").equals(normalizedEmail).toArray();
  return rows.filter((r) => !r.used).length;
}
