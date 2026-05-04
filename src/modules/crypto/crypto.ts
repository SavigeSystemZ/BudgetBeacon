export const SALT_PREFIX = "beacon-salt-v1-";

export async function hashEmailForSalt(email: string): Promise<Uint8Array> {
  const encoder = new TextEncoder();
  const data = encoder.encode(SALT_PREFIX + email.trim().toLowerCase());
  const hash = await crypto.subtle.digest("SHA-256", data);
  return new Uint8Array(hash);
}


export async function derivePassphraseGcmKey(email: string, passphrase: string): Promise<CryptoKey> {
  const salt = await hashEmailForSalt(email);
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(passphrase),
    { name: "PBKDF2" },
    false,
    ["deriveBits", "deriveKey"]
  );

  return crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt as BufferSource,
      iterations: 600000,
      hash: "SHA-256",
    },
    keyMaterial,
    { name: "AES-GCM", length: 256 },
    true,
    ["encrypt", "decrypt"]
  );
}

export async function derivePassphraseKey(email: string, passphrase: string): Promise<CryptoKey> {
  const salt = await hashEmailForSalt(email);
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(passphrase),
    { name: "PBKDF2" },
    false,
    ["deriveBits", "deriveKey"]
  );

  return crypto.subtle.deriveKey(
    {
      name: "PBKDF2",
      salt: salt as BufferSource,
      iterations: 600000,
      hash: "SHA-256",
    },
    keyMaterial,
    { name: "AES-KW", length: 256 },
    true,
    ["wrapKey", "unwrapKey"]
  );
}

export async function generateHouseholdKey(): Promise<CryptoKey> {
  return crypto.subtle.generateKey(
    {
      name: "AES-GCM",
      length: 256,
    },
    true,
    ["encrypt", "decrypt"]
  );
}

export async function wrapKey(keyToWrap: CryptoKey, wrappingKey: CryptoKey, format: KeyFormat = "raw"): Promise<string> {
  const wrapped = await crypto.subtle.wrapKey(format, keyToWrap, wrappingKey, { name: "AES-KW" });
  return btoa(String.fromCharCode(...new Uint8Array(wrapped)));
}

export async function unwrapKey(wrappedKeyBase64: string, unwrappingKey: CryptoKey, unwrappedKeyAlgo: AlgorithmIdentifier | RsaHashedImportParams | EcKeyImportParams | HmacImportParams | AesKeyAlgorithm = { name: "AES-GCM", length: 256 }, keyUsages: KeyUsage[] = ["encrypt", "decrypt"], format: KeyFormat = "raw"): Promise<CryptoKey> {
  const binaryString = atob(wrappedKeyBase64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return crypto.subtle.unwrapKey(
    format,
    bytes,
    unwrappingKey,
    { name: "AES-KW" },
    unwrappedKeyAlgo,
    true,
    keyUsages
  );
}

export async function generateSyncKeypair(): Promise<CryptoKeyPair> {
  return crypto.subtle.generateKey(
    {
      name: "ECDH",
      namedCurve: "P-256",
    },
    true,
    ["deriveKey"]
  );
}

export async function exportPublicKey(key: CryptoKey): Promise<string> {
  const exported = await crypto.subtle.exportKey("spki", key);
  return btoa(String.fromCharCode(...new Uint8Array(exported)));
}

export async function importPublicKey(base64Key: string): Promise<CryptoKey> {
  const binaryString = atob(base64Key);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return crypto.subtle.importKey(
    "spki",
    bytes,
    { name: "ECDH", namedCurve: "P-256" },
    true,
    []
  );
}

export async function exportPrivateKeyJwk(key: CryptoKey): Promise<JsonWebKey> {
  return crypto.subtle.exportKey("jwk", key);
}

export async function exportPrivateKey(key: CryptoKey): Promise<string> {
  const exported = await crypto.subtle.exportKey("pkcs8", key);
  return btoa(String.fromCharCode(...new Uint8Array(exported)));
}

export async function importPrivateKeyJwk(jwk: JsonWebKey): Promise<CryptoKey> {
  return crypto.subtle.importKey("jwk", jwk, { name: "ECDH", namedCurve: "P-256" }, true, ["deriveKey"]);
}

export async function importPrivateKey(base64Key: string): Promise<CryptoKey> {
  const binaryString = atob(base64Key);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return crypto.subtle.importKey(
    "pkcs8",
    bytes,
    { name: "ECDH", namedCurve: "P-256" },
    true,
    ["deriveKey"]
  );
}

export async function deriveSharedSecret(privateKey: CryptoKey, publicKey: CryptoKey): Promise<CryptoKey> {
  return crypto.subtle.deriveKey(
    {
      name: "ECDH",
      public: publicKey,
    },
    privateKey,
    { name: "AES-KW", length: 256 },
    true,
    ["wrapKey", "unwrapKey"]
  );
}

export async function encryptForSync(data: unknown, key: CryptoKey): Promise<{ ciphertext: string; iv: string }> {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const encoder = new TextEncoder();
  const encoded = encoder.encode(JSON.stringify(data));
  const encrypted = await crypto.subtle.encrypt(
    {
      name: "AES-GCM",
      iv: iv,
    },
    key,
    encoded
  );
  return {
    ciphertext: btoa(String.fromCharCode(...new Uint8Array(encrypted))),
    iv: btoa(String.fromCharCode(...iv)),
  };
}

export async function decrypt(ciphertextBase64: string, ivBase64: string, key: CryptoKey): Promise<unknown> {
  const ctStr = atob(ciphertextBase64);
  const ctBytes = new Uint8Array(ctStr.length);
  for (let i = 0; i < ctStr.length; i++) ctBytes[i] = ctStr.charCodeAt(i);

  const ivStr = atob(ivBase64);
  const ivBytes = new Uint8Array(ivStr.length);
  for (let i = 0; i < ivStr.length; i++) ivBytes[i] = ivStr.charCodeAt(i);

  const decrypted = await crypto.subtle.decrypt(
    {
      name: "AES-GCM",
      iv: ivBytes,
    },
    key,
    ctBytes
  );

  const decoder = new TextDecoder();
  return JSON.parse(decoder.decode(decrypted));
}
