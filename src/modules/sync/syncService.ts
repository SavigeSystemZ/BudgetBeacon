import * as Y from "yjs";
import { db } from "../../db/db";
import { encryptForSync, decrypt } from "../crypto/crypto";
import { WebsocketProvider } from "y-websocket";

const SYNCABLE_TABLES = [
  "households",
  "persons",
  "incomeSources",
  "bills",
  "debts",
  "savingsGoals",
  "creditSnapshots",
  "transactions",
  "debtTransactions",
  "taxRecords",
  "taxTransactions",
  "documents",
  "taxForms",
  "subscriptions",
  "insuranceRecords",
  "payeeRules",
];

export type SyncStatus =
  | "local-only"
  | "connecting"
  | "connected"
  | "disconnected"
  | "error";

type StatusListener = (status: SyncStatus) => void;

class SyncService {
  private householdKey: CryptoKey | null = null;
  private wsProvider: WebsocketProvider | null = null;
  public ydoc = new Y.Doc();
  private isApplyingYjsToDexie = false;
  private isBootstrapped = false;
  private status: SyncStatus = "local-only";
  private listeners = new Set<StatusListener>();

  constructor() {
    this.setupDexieHooks();
  }

  private getTableMap(tableName: string): Y.Map<unknown> {
    return this.ydoc.getMap(tableName);
  }

  public getStatus(): SyncStatus {
    return this.status;
  }

  public onStatusChange(listener: StatusListener): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }

  private setStatus(status: SyncStatus) {
    if (this.status === status) return;
    this.status = status;
    for (const l of this.listeners) {
      try { l(status); } catch (err) { console.error(err); }
    }
  }

  private setupDexieHooks() {
    for (const tableName of SYNCABLE_TABLES) {
      const table = db.table(tableName);

      table.hook("creating", (primKey, obj) => {
        if (this.isApplyingYjsToDexie || !this.isBootstrapped || !this.householdKey) return;
        const yMap = this.getTableMap(tableName);
        encryptForSync(obj, this.householdKey).then(encrypted => {
          this.ydoc.transact(() => {
            yMap.set(String(primKey), JSON.stringify(encrypted));
          }, "local");
        }).catch(console.error);
      });

      table.hook("updating", (modifications, primKey, obj) => {
        if (this.isApplyingYjsToDexie || !this.isBootstrapped || !this.householdKey) return;
        const yMap = this.getTableMap(tableName);
        const newObj = { ...obj, ...modifications };
        encryptForSync(newObj, this.householdKey).then(encrypted => {
          this.ydoc.transact(() => {
            yMap.set(String(primKey), JSON.stringify(encrypted));
          }, "local");
        }).catch(console.error);
      });

      table.hook("deleting", (primKey) => {
        if (this.isApplyingYjsToDexie || !this.isBootstrapped) return;
        const yMap = this.getTableMap(tableName);
        this.ydoc.transact(() => {
          yMap.delete(String(primKey));
        }, "local");
      });
    }
  }

  private async wireTable(tableName: string) {
    const table = db.table(tableName);
    const records = await table.toArray();
    const yMap = this.getTableMap(tableName);

    const encryptedRecords = await Promise.all(records.map(async r => {
      const enc = await encryptForSync(r, this.householdKey!);
      return { id: String(r.id), enc: JSON.stringify(enc) };
    }));
    this.ydoc.transact(() => {
      for (const er of encryptedRecords) {
        yMap.set(er.id, er.enc);
      }
    }, "bootstrap");

    yMap.observe(async (event) => {
      if (event.transaction.origin === "bootstrap" || event.transaction.origin === "local") {
        return;
      }

      this.isApplyingYjsToDexie = true;
      try {
        const keysChanged = event.changes.keys;
        const createsOrUpdates: unknown[] = [];
        const deletes: string[] = [];

        for (const key of Array.from(keysChanged.keys())) {
          const change = keysChanged.get(key)!;
          if (change.action === "add" || change.action === "update") {
            const valStr = yMap.get(key);
            if (valStr && this.householdKey) {
              try {
                const encrypted = JSON.parse(valStr as string);
                const decrypted = await decrypt(encrypted.ciphertext, encrypted.iv, this.householdKey);
                createsOrUpdates.push(decrypted);
              } catch (err) {
                console.error("Failed to decrypt incoming sync record", err);
              }
            }
          } else if (change.action === "delete") {
            deletes.push(key);
          }
        }

        await db.transaction("rw", table, async () => {
          if (createsOrUpdates.length > 0) {
            await table.bulkPut(createsOrUpdates);
          }
          if (deletes.length > 0) {
            await table.bulkDelete(deletes);
          }
        });
      } finally {
        this.isApplyingYjsToDexie = false;
      }
    });
  }

  /**
   * Bootstrap the sync service. If `wsUrl` is empty/null/undefined, the service
   * mirrors locally (Dexie ↔ Yjs) without opening any network connection —
   * useful when the user has not green-lit a relay.
   */
  public async bootstrap(
    householdId: string,
    key: CryptoKey,
    wsUrl?: string | null,
  ) {
    this.householdKey = key;
    if (this.isBootstrapped) return;

    for (const tableName of SYNCABLE_TABLES) {
      await this.wireTable(tableName);
    }

    this.isBootstrapped = true;

    if (!wsUrl) {
      this.setStatus("local-only");
      return;
    }

    try {
      this.setStatus("connecting");
      this.wsProvider = new WebsocketProvider(wsUrl, householdId, this.ydoc);
      this.wsProvider.on("status", (event: { status: string }) => {
        if (event.status === "connected") this.setStatus("connected");
        else if (event.status === "connecting") this.setStatus("connecting");
        else if (event.status === "disconnected") this.setStatus("disconnected");
      });
      this.wsProvider.connect();
    } catch (err) {
      console.error("Sync relay connect failed", err);
      this.setStatus("error");
    }
  }

  public disconnect() {
    if (this.wsProvider) {
      try { this.wsProvider.disconnect(); } catch { /* ignore */ }
      this.wsProvider = null;
    }
    this.setStatus("local-only");
  }
}

export const syncService = new SyncService();
