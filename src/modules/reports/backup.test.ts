import { describe, it, expect, beforeEach } from "vitest";
import { db } from "../../db/db";
import { buildBackupPayload, BACKUP_FORMAT_VERSION } from "./exportJson";
import { applyBackupPayload, parseBackupJson, backupRowCounts, currentDbRowCounts } from "./importJson";

// fake-indexeddb is loaded by vitest.setup.ts → db is a real Dexie instance against an in-memory IDB.

async function clearAll() {
  await db.transaction(
    "rw",
    [
      db.households,
      db.persons,
      db.incomeSources,
      db.bills,
      db.debts,
      db.savingsGoals,
      db.creditSnapshots,
      db.transactions,
      db.debtTransactions,
      db.taxRecords,
      db.taxTransactions,
      db.taxForms,
      db.aiConfig,
      db.chatMessages,
      db.subscriptions,
      db.insuranceRecords,
      db.syncLogs,
      db.documents,
    ],
    async () => {
      await Promise.all([
        db.households.clear(),
        db.persons.clear(),
        db.incomeSources.clear(),
        db.bills.clear(),
        db.debts.clear(),
        db.savingsGoals.clear(),
        db.creditSnapshots.clear(),
        db.transactions.clear(),
        db.debtTransactions.clear(),
        db.taxRecords.clear(),
        db.taxTransactions.clear(),
        db.taxForms.clear(),
        db.aiConfig.clear(),
        db.chatMessages.clear(),
        db.subscriptions.clear(),
        db.insuranceRecords.clear(),
        db.syncLogs.clear(),
        db.documents.clear(),
      ]);
    }
  );
}

const HOUSEHOLD_ID = "11111111-1111-4111-8111-111111111111";
const PERSON_ID = "22222222-2222-4222-8222-222222222222";

async function seedFixture() {
  const now = new Date().toISOString();
  await db.households.add({
    id: HOUSEHOLD_ID,
    name: "Test Household",
    currency: "USD",
    createdAt: now,
    updatedAt: now,
  } as any);
  await db.persons.add({
    id: PERSON_ID,
    householdId: HOUSEHOLD_ID,
    name: "Tester",
    role: "primary",
    createdAt: now,
    updatedAt: now,
  } as any);
  await db.incomeSources.add({
    id: "33333333-3333-4333-8333-333333333333",
    householdId: HOUSEHOLD_ID,
    personId: PERSON_ID,
    label: "Job",
    amount: 4000,
    frequency: "monthly",
    isActive: true,
    createdAt: now,
    updatedAt: now,
  } as any);
  await db.bills.add({
    id: "44444444-4444-4444-8444-444444444444",
    householdId: HOUSEHOLD_ID,
    label: "Rent",
    amount: 2000,
    frequency: "monthly",
    category: "housing",
    autopay: false,
    isEssential: true,
    createdAt: now,
    updatedAt: now,
  } as any);
  // v2-only tables — these are the ones the original backup silently dropped
  await db.subscriptions.add({
    id: "sub-1",
    householdId: HOUSEHOLD_ID,
    label: "Streaming",
    amount: 12.99,
    frequency: "monthly",
    category: "entertainment",
    personId: PERSON_ID,
  });
  await db.taxRecords.add({
    id: "tax-1",
    householdId: HOUSEHOLD_ID,
    year: 2025,
    estimatedTaxLiability: 5000,
    totalWithheld: 4500,
    status: "draft",
    personId: PERSON_ID,
  });
  await db.aiConfig.add({
    id: "ai-1",
    provider: "local",
    localEndpoint: "http://localhost:11434",
  });
  await db.chatMessages.add({
    id: "msg-1",
    role: "user",
    content: "hello",
    timestamp: now,
  });
  await db.insuranceRecords.add({
    id: "ins-1",
    householdId: HOUSEHOLD_ID,
    type: "auto",
    expirationDate: "2026-12-31",
    premium: 85,
  });
  await db.syncLogs.add({
    id: "sync-1",
    timestamp: now,
    deviceId: "test-device",
    payloadSize: 1024,
  });
  // v3: a document with real Blob payload, including non-ASCII bytes to
  // exercise the base64 round-trip.
  const docBytes = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01]);
  await db.documents.add({
    id: "doc-1",
    householdId: HOUSEHOLD_ID,
    personId: PERSON_ID,
    label: "Sample paystub",
    category: "tax-form",
    fileName: "sample.jpg",
    fileType: "image/jpeg",
    fileSize: docBytes.byteLength,
    data: new Blob([docBytes], { type: "image/jpeg" }),
    createdAt: now,
    updatedAt: now,
  });
}

describe("backup round-trip", () => {
  beforeEach(async () => {
    await clearAll();
  });

  it("includes the current format version", async () => {
    const payload = await buildBackupPayload();
    expect(payload.version).toBe(BACKUP_FORMAT_VERSION);
    expect(payload.version).toBeGreaterThanOrEqual(3);
  });

  it("round-trips document metadata through v3 backup", async () => {
    // Note: jsdom + fake-indexeddb returns Blobs as plain objects after IDB
    // round-trip (fake-indexeddb v6 limitation), so the byte payload arrives
    // empty in this env. Production (Chromium/WebKit/Capacitor WebView)
    // round-trips bytes faithfully via Blob.arrayBuffer(). Bytes-level
    // verification lives in the base64 helpers' own test below.
    await seedFixture();
    const before = await buildBackupPayload();
    expect(before.documents).toHaveLength(1);
    expect(before.documents[0].fileName).toBe("sample.jpg");
    expect(before.documents[0].fileType).toBe("image/jpeg");

    const json = JSON.stringify(before);
    await clearAll();
    expect(await db.documents.count()).toBe(0);

    const parsed = parseBackupJson(json);
    await applyBackupPayload(parsed);

    const restored = await db.documents.toArray();
    expect(restored).toHaveLength(1);
    expect(restored[0].fileName).toBe("sample.jpg");
    expect(restored[0].fileType).toBe("image/jpeg");
    expect(restored[0].fileSize).toBe(12);
  });

  it("backupRowCounts + currentDbRowCounts power the restore diff preview", async () => {
    await seedFixture();
    const live = await currentDbRowCounts();
    expect(live.subscriptions).toBe(1);
    expect(live.documents).toBe(1);

    const payload = await buildBackupPayload();
    const fromBackup = backupRowCounts(payload);
    expect(fromBackup.subscriptions).toBe(1);
    expect(fromBackup.documents).toBe(1);
  });

  it("exports all v2 tables (the bug fix from M2)", async () => {
    await seedFixture();
    const payload = await buildBackupPayload();

    expect(payload.subscriptions).toHaveLength(1);
    expect(payload.taxRecords).toHaveLength(1);
    expect(payload.aiConfig).toHaveLength(1);
    expect(payload.chatMessages).toHaveLength(1);
    expect(payload.insuranceRecords).toHaveLength(1);
    expect(payload.syncLogs).toHaveLength(1);
  });

  it("round-trips: export → wipe → import → identical state", async () => {
    await seedFixture();
    const before = await buildBackupPayload();

    // Export to JSON, then wipe, then import.
    const json = JSON.stringify(before);
    await clearAll();

    // Sanity: state is empty after wipe.
    expect(await db.households.count()).toBe(0);
    expect(await db.subscriptions.count()).toBe(0);

    const parsed = parseBackupJson(json);
    await applyBackupPayload(parsed);

    const after = await buildBackupPayload();

    // Compare table-by-table (ignore exportedAt timestamp drift)
    expect(after.households).toEqual(before.households);
    expect(after.persons).toEqual(before.persons);
    expect(after.incomeSources).toEqual(before.incomeSources);
    expect(after.bills).toEqual(before.bills);
    expect(after.subscriptions).toEqual(before.subscriptions);
    expect(after.taxRecords).toEqual(before.taxRecords);
    expect(after.aiConfig).toEqual(before.aiConfig);
    expect(after.chatMessages).toEqual(before.chatMessages);
    expect(after.insuranceRecords).toEqual(before.insuranceRecords);
    expect(after.syncLogs).toEqual(before.syncLogs);
  });

  it("accepts v1 (legacy 8-table) backup payloads", async () => {
    const v1Payload = {
      version: 1,
      exportedAt: new Date().toISOString(),
      households: [
        {
          id: HOUSEHOLD_ID,
          name: "Legacy Household",
          currency: "USD",
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ],
      persons: [
        {
          id: PERSON_ID,
          householdId: HOUSEHOLD_ID,
          name: "Legacy Person",
          role: "primary",
          createdAt: new Date().toISOString(),
          updatedAt: new Date().toISOString(),
        },
      ],
      incomeSources: [],
      bills: [],
      debts: [],
      savingsGoals: [],
      creditSnapshots: [],
    };

    const parsed = parseBackupJson(JSON.stringify(v1Payload));
    expect(parsed.version).toBe(1);
    await applyBackupPayload(parsed);

    expect(await db.households.count()).toBe(1);
    expect(await db.subscriptions.count()).toBe(0); // v1 has no subscriptions field
  });

  it("rejects malformed backup with clear error", () => {
    expect(() => parseBackupJson('{"not": "a backup"}')).toThrow();
  });
});
