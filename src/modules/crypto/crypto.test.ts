import { describe, it, expect } from "vitest";
import {
  derivePassphraseKey,
  generateHouseholdKey,
  wrapKey,
  unwrapKey,
  encryptForSync,
  decrypt,
  generateSyncKeypair,
  exportPublicKey,
  importPublicKey,
  exportPrivateKey,
  importPrivateKey,
  deriveSharedSecret,
} from "./crypto";

describe("crypto M10.2", () => {
  it("wraps and unwraps a household key with a passphrase key", async () => {
    const kek = await derivePassphraseKey("test@example.com", "supersecret");
    const hk = await generateHouseholdKey();
    const wrapped = await wrapKey(hk, kek);
    expect(typeof wrapped).toBe("string");
    expect(wrapped.length).toBeGreaterThan(0);

    const unwrapped = await unwrapKey(wrapped, kek);
    // Encrypt and decrypt to prove it's the same key
    const payload = { test: 123 };
    const encrypted = await encryptForSync(payload, hk);
    const decrypted = await decrypt(encrypted.ciphertext, encrypted.iv, unwrapped);
    expect(decrypted).toEqual(payload);
  });

  it("wraps and unwraps using ECDH shared secret", async () => {
    const userA = await generateSyncKeypair();
    const userB = await generateSyncKeypair();

    // User A derives shared secret to wrap the key for User B
    const secretForB = await deriveSharedSecret(userA.privateKey, userB.publicKey);
    const hk = await generateHouseholdKey();
    const wrapped = await wrapKey(hk, secretForB);

    // User B derives the same shared secret using their private key and User A's public key
    const secretForA = await deriveSharedSecret(userB.privateKey, userA.publicKey);
    const unwrapped = await unwrapKey(wrapped, secretForA);

    const payload = { message: "hello joint household" };
    const encrypted = await encryptForSync(payload, hk);
    const decrypted = await decrypt(encrypted.ciphertext, encrypted.iv, unwrapped);
    expect(decrypted).toEqual(payload);
  });

  it("exports and imports ECDH keys", async () => {
    const pair = await generateSyncKeypair();
    const pub = await exportPublicKey(pair.publicKey);
    const priv = await exportPrivateKey(pair.privateKey);

    const impPub = await importPublicKey(pub);
    const impPriv = await importPrivateKey(priv);

    expect(impPub.type).toBe("public");
    expect(impPriv.type).toBe("private");
  });
});
