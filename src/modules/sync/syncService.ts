import * as Y from "yjs";
import { db } from "../../db/db";
import { encryptForSync, decrypt } from "../crypto/crypto";
import { WebsocketProvider } from "y-websocket";

// The tables that should be synced across devices
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

class SyncService {
  private householdKey: CryptoKey | null = null;
  private wsProvider: WebsocketProvider | null = null;
  public ydoc = new Y.Doc();
  private isApplyingYjsToDexie = false;
  private isBootstrapped = false;

  constructor() {
    this.setupDexieHooks();
  }

  private getTableMap(tableName: string): Y.Map<unknown> {
    return this.ydoc.getMap(tableName);
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

  public async bootstrap(householdId: string, key: CryptoKey, wsUrl: string = "wss://sync.budgetbeacon.app") {
    this.householdKey = key;
    if (this.isBootstrapped) return;
    
    // Load local Dexie data into Yjs on initial startup
    for (const tableName of SYNCABLE_TABLES) {
      const table = db.table(tableName);
      const records = await table.toArray();
      const yMap = this.getTableMap(tableName);
      
      // We must encrypt bootstrap records
      const encryptedRecords = await Promise.all(records.map(async r => {
        const enc = await encryptForSync(r, this.householdKey!);
        return { id: String(r.id), enc: JSON.stringify(enc) };
      }));
      this.ydoc.transact(() => {
        for (const er of encryptedRecords) {
          yMap.set(er.id, er.enc);
        }
      }, "bootstrap");

      // Setup incoming Yjs listener
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
    
    this.isBootstrapped = true;
    this.wsProvider = new WebsocketProvider(wsUrl, householdId, this.ydoc);
    this.wsProvider.connect();
  }
}

export const syncService = new SyncService();
