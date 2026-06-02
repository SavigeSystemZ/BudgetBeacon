import { describe, it, expect, beforeEach } from "vitest";
import {
  generateRecoveryCodes,
  redeemRecoveryCode,
  countUnusedRecoveryCodes,
  formatRecoveryCode,
  normalizeRecoveryCode,
} from "./recoveryCodes";
import { signUp, login, logout, recoverAccount, getSession } from "./authService";
import { encryptForSync, decrypt } from "../crypto/crypto";
import { db } from "../../db/db";

const EMAIL = "recover@example.com";
const PASS = "original-pass-123";

describe("recoveryCodes M10", () => {
  beforeEach(async () => {
    await db.accounts.clear();
    await db.recoveryCodes.clear();
    logout();
  });

  it("formats and normalizes codes symmetrically", () => {
    const formatted = formatRecoveryCode("ABCDEFGHJKMNPQRSTVWX");
    expect(formatted).toBe("ABCDE-FGHJK-MNPQR-STVWX");
    expect(normalizeRecoveryCode("abcde-fghjk")).toBe("ABCDEFGHJK");
    expect(normalizeRecoveryCode(formatted)).toBe("ABCDEFGHJKMNPQRSTVWX");
  });

  it("generates 10 unique codes and stores hashed rows (no plaintext)", async () => {
    await signUp(EMAIL, PASS);
    const key = getSession().currentHouseholdKey!;
    const codes = await generateRecoveryCodes(EMAIL, key);

    expect(codes).toHaveLength(10);
    expect(new Set(codes).size).toBe(10);
    expect(codes.every((c) => /^[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}-[A-Z0-9]{5}$/.test(c))).toBe(true);

    const rows = await db.recoveryCodes.where("email").equals(EMAIL).toArray();
    expect(rows).toHaveLength(10);
    // Stored rows must not contain any plaintext code.
    for (const r of rows) {
      expect(codes).not.toContain(r.codeHash);
      expect(r.used).toBe(false);
    }
    expect(await countUnusedRecoveryCodes(EMAIL)).toBe(10);
  });

  it("redeems a code to recover a household key that decrypts original data", async () => {
    await signUp(EMAIL, PASS);
    const originalKey = getSession().currentHouseholdKey!;
    const secret = { kind: "transaction", amount: 4242 };
    const blob = await encryptForSync(secret, originalKey);

    const codes = await generateRecoveryCodes(EMAIL, originalKey);
    const recoveredKey = await redeemRecoveryCode(EMAIL, codes[0]);

    const out = await decrypt(blob.ciphertext, blob.iv, recoveredKey);
    expect(out).toEqual(secret);
  });

  it("enforces single use", async () => {
    await signUp(EMAIL, PASS);
    const codes = await generateRecoveryCodes(EMAIL, getSession().currentHouseholdKey!);

    await redeemRecoveryCode(EMAIL, codes[0]);
    await expect(redeemRecoveryCode(EMAIL, codes[0])).rejects.toThrow(/already been used/);
    expect(await countUnusedRecoveryCodes(EMAIL)).toBe(9);
  });

  it("rejects unknown codes", async () => {
    await signUp(EMAIL, PASS);
    await generateRecoveryCodes(EMAIL, getSession().currentHouseholdKey!);
    await expect(redeemRecoveryCode(EMAIL, "ZZZZZ-ZZZZZ-ZZZZZ-ZZZZZ")).rejects.toThrow(/Invalid or unrecognized/);
  });

  it("regenerating invalidates the prior set", async () => {
    await signUp(EMAIL, PASS);
    const key = getSession().currentHouseholdKey!;
    const oldCodes = await generateRecoveryCodes(EMAIL, key);
    await generateRecoveryCodes(EMAIL, key); // supersede

    expect(await countUnusedRecoveryCodes(EMAIL)).toBe(10);
    await expect(redeemRecoveryCode(EMAIL, oldCodes[0])).rejects.toThrow(/Invalid or unrecognized/);
  });

  it("recoverAccount sets a new passphrase that can log in", async () => {
    await signUp(EMAIL, PASS);
    const originalKey = getSession().currentHouseholdKey!;
    const codes = await generateRecoveryCodes(EMAIL, originalKey);
    logout();

    const recoveredKey = await redeemRecoveryCode(EMAIL, codes[0]);
    await recoverAccount(EMAIL, "brand-new-pass-456", recoveredKey);
    logout();

    // Old passphrase no longer works; new one does.
    await expect(login(EMAIL, PASS)).rejects.toThrow();
    const account = await login(EMAIL, "brand-new-pass-456");
    expect(account.email).toBe(EMAIL);
    expect(getSession().currentHouseholdKey).toBeDefined();
  });
});
