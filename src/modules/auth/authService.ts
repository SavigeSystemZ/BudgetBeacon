import { db, type Account } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import {
  derivePassphraseKey,
  derivePassphraseGcmKey,
  generateHouseholdKey,
  generateSyncKeypair,
  wrapKey,
  unwrapKey,
  exportPublicKey,
  exportPrivateKeyJwk,
  importPrivateKeyJwk,
  encryptForSync,
  decrypt,
} from "../crypto/crypto";

// In-memory session state
let currentAccount: Account | null = null;
let currentHouseholdKey: CryptoKey | null = null;
let currentSyncKeypair: CryptoKeyPair | null = null;

export function getSession() {
  return { currentAccount, currentHouseholdKey, currentSyncKeypair };
}

export async function signUp(email: string, passphrase: string): Promise<Account> {
  const existing = await db.accounts.where("email").equals(email.toLowerCase()).first();
  if (existing) {
    throw new Error("Account already exists with this email.");
  }

  const kek = await derivePassphraseKey(email, passphrase);
  const gcmKek = await derivePassphraseGcmKey(email, passphrase);

  const syncKeypair = await generateSyncKeypair();
  const publicKeyStr = await exportPublicKey(syncKeypair.publicKey);
  
  const jwk = await exportPrivateKeyJwk(syncKeypair.privateKey);
  const { ciphertext, iv } = await encryptForSync(jwk, gcmKek);
  const wrappedPrivateKey = JSON.stringify({ ciphertext, iv });

  const householdKey = await generateHouseholdKey();
  const wrappedHouseholdKey = await wrapKey(householdKey, kek);

  const account: Account = {
    id: createId(),
    email: email.toLowerCase(),
    publicKey: publicKeyStr,
    privateKeyWrapped: wrappedPrivateKey,
    householdKeyWrapped: wrappedHouseholdKey,
    createdAt: new Date().toISOString(),
  };

  await db.accounts.add(account);

  currentAccount = account;
  currentHouseholdKey = householdKey;
  currentSyncKeypair = syncKeypair;

  localStorage.setItem("beacon_active_account", account.id);

  return account;
}

export async function login(email: string, passphrase: string): Promise<Account> {
  const account = await db.accounts.where("email").equals(email.toLowerCase()).first();
  if (!account) {
    throw new Error("Invalid email or passphrase.");
  }

  try {
    const kek = await derivePassphraseKey(email, passphrase);
  const gcmKek = await derivePassphraseGcmKey(email, passphrase);

    const { ciphertext, iv } = JSON.parse(account.privateKeyWrapped);
    const jwk = await decrypt(ciphertext, iv, gcmKek);
    const privateKey = await importPrivateKeyJwk(jwk as JsonWebKey);
    
    const householdKey = await unwrapKey(
      account.householdKeyWrapped, 
      kek, 
      { name: "AES-GCM", length: 256 }, 
      ["encrypt", "decrypt"]
    );

    currentAccount = account;
    currentHouseholdKey = householdKey;
    // @ts-expect-error - we only strictly need the private key for derivation
    currentSyncKeypair = { privateKey, publicKey: null };

    localStorage.setItem("beacon_active_account", account.id);

    return account;
  } catch {
    throw new Error("Invalid email or passphrase.");
  }
}

export function logout() {
  currentAccount = null;
  currentHouseholdKey = null;
  currentSyncKeypair = null;
  localStorage.removeItem("beacon_active_account");
}

export async function restoreSessionPromptIfNeeded(): Promise<Account | null> {
  const activeId = localStorage.getItem("beacon_active_account");
  if (!activeId) return null;
  
  const account = await db.accounts.get(activeId);
  if (!account) {
    localStorage.removeItem("beacon_active_account");
    return null;
  }
  
  return account;
}
