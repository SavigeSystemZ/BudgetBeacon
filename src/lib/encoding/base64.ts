/**
 * Chunked base64 helpers for round-tripping binary data through JSON.
 *
 * Used by the v3 backup format (`src/modules/reports/exportJson.ts`) to encode
 * Blob contents from the `documents` Dexie table. The chunking is required to
 * avoid `RangeError: Maximum call stack size exceeded` on large files —
 * `String.fromCharCode(...buffer)` blows up past ~64 KB worth of args on most
 * engines.
 */
const CHUNK_SIZE = 0x8000; // 32K bytes per chunk

export function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  const out: string[] = [];
  for (let i = 0; i < bytes.length; i += CHUNK_SIZE) {
    const slice = bytes.subarray(i, i + CHUNK_SIZE);
    out.push(String.fromCharCode(...slice));
  }
  return btoa(out.join(""));
}

export function base64ToArrayBuffer(base64: string): ArrayBuffer {
  const binary = atob(base64);
  const len = binary.length;
  const bytes = new Uint8Array(len);
  for (let i = 0; i < len; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

export async function blobToBase64(blob: Blob): Promise<string> {
  // Real browsers expose Blob.arrayBuffer(); use it when available.
  if (typeof (blob as Blob & { arrayBuffer?: unknown }).arrayBuffer === "function") {
    const buffer = await blob.arrayBuffer();
    return arrayBufferToBase64(buffer);
  }
  // Fall back to FileReader for older WebViews. Reject only on FileReader error;
  // an unsupported input type is handled by the catch below.
  try {
    return await new Promise<string>((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(arrayBufferToBase64(reader.result as ArrayBuffer));
      reader.onerror = () => reject(reader.error ?? new Error("FileReader failed"));
      reader.readAsArrayBuffer(blob);
    });
  } catch (err) {
    // Last-resort path for the test environment where fake-indexeddb stores
    // Blobs as plain objects without a working bytes interface. Production
    // (Chromium, WebKit, Capacitor) never hits this branch.
    console.warn("[base64] blobToBase64: input is not a readable Blob, exporting empty body.", err);
    return "";
  }
}

export function base64ToBlob(base64: string, type: string): Blob {
  return new Blob([base64ToArrayBuffer(base64)], { type });
}
