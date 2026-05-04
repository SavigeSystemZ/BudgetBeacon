import { describe, it, expect, beforeEach } from "vitest";
import { db } from "../../db/db";
import { generateHouseholdKey, encryptForSync } from "../crypto/crypto";
import { syncService } from "./syncService";

describe("syncService M10.3", () => {
  beforeEach(async () => {
    await db.households.clear();
    await db.persons.clear();
    const hk = await generateHouseholdKey();
    await syncService.bootstrap("hh-test", hk);
  });

  it("mirrors Dexie creates to Yjs", async () => {
    const hh = { id: "hh-1", name: "My House", currency: "USD", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    
    // Write to Dexie
    await db.households.add(hh);

    // Verify it's in Yjs
    const yMap = syncService.ydoc.getMap("households");
    // We have to wait for async encryption in the hook
    await new Promise(r => setTimeout(r, 100));
    const enc = JSON.parse(yMap.get("hh-1") as string);
    expect(enc.ciphertext).toBeDefined();
  });

  it("mirrors Dexie updates to Yjs", async () => {
    const hh = { id: "hh-1", name: "My House", currency: "USD", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    await db.households.add(hh);
    
    await db.households.update("hh-1", { name: "New Name" });

    const yMap = syncService.ydoc.getMap("households");
    await new Promise(r => setTimeout(r, 100));
    const enc = JSON.parse(yMap.get("hh-1") as string);
    expect(enc.ciphertext).toBeDefined();
  });

  it("mirrors Dexie deletes to Yjs", async () => {
    const hh = { id: "hh-1", name: "My House", currency: "USD", createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() };
    await db.households.add(hh);
    await db.households.delete("hh-1");

    const yMap = syncService.ydoc.getMap("households");
    expect(yMap.has("hh-1")).toBe(false);
  });

  it("mirrors Yjs updates to Dexie", async () => {
    const yMap = syncService.ydoc.getMap("persons");
    const person = { id: "p-1", householdId: "hh-1", name: "Alice" };
    
    // Simulate remote Yjs insertion (must not be 'local' or 'bootstrap' origin)
    const enc = await encryptForSync(person, (syncService as unknown as { householdKey: CryptoKey }).householdKey);
    syncService.ydoc.transact(() => {
      yMap.set("p-1", JSON.stringify(enc));
    }, "remote-peer-123");

    // Give Dexie a moment to process the transaction (async)
    await new Promise(resolve => setTimeout(resolve, 50));

    const dexiePerson = await db.persons.get("p-1");
    expect(dexiePerson).toEqual(person);
  });
});
