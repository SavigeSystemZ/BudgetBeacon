import { describe, it, expect, beforeEach } from "vitest";
import { signUp, login, logout, getSession } from "./authService";
import { db } from "../../db/db";

describe("authService M10.1", () => {
  beforeEach(async () => {
    await db.accounts.clear();
    logout();
  });

  it("signs up a user and wraps keys correctly", async () => {
    const account = await signUp("test@example.com", "password123");
    expect(account.email).toBe("test@example.com");
    expect(account.publicKey).toBeDefined();
    
    const session = getSession();
    expect(session.currentAccount?.id).toBe(account.id);
    expect(session.currentHouseholdKey).toBeDefined();
    expect(session.currentSyncKeypair).toBeDefined();
  });

  it("fails to login with wrong passphrase", async () => {
    await signUp("test@example.com", "password123");
    logout();
    
    await expect(login("test@example.com", "wrongpass")).rejects.toThrow("Invalid email or passphrase.");
  });

  it("logs in successfully and unwraps keys", async () => {
    await signUp("test@example.com", "password123");
    logout();
    
    const sessionBefore = getSession();
    expect(sessionBefore.currentAccount).toBeNull();
    
    const account = await login("test@example.com", "password123");
    expect(account.email).toBe("test@example.com");
    
    const sessionAfter = getSession();
    expect(sessionAfter.currentHouseholdKey).toBeDefined();
  });
});
