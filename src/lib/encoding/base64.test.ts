import { describe, it, expect } from "vitest";
import { arrayBufferToBase64, base64ToArrayBuffer, base64ToBlob } from "./base64";

describe("base64 helpers", () => {
  it("round-trips an ArrayBuffer byte-for-byte", () => {
    const original = new Uint8Array([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10, 0x4a, 0x46, 0x49, 0x46, 0x00, 0x01]);
    const encoded = arrayBufferToBase64(original.buffer);
    const decoded = new Uint8Array(base64ToArrayBuffer(encoded));
    expect(Array.from(decoded)).toEqual(Array.from(original));
  });

  it("handles empty buffer", () => {
    const encoded = arrayBufferToBase64(new ArrayBuffer(0));
    expect(encoded).toBe("");
    expect(base64ToArrayBuffer(encoded).byteLength).toBe(0);
  });

  it("handles buffers larger than the chunking boundary (32K)", () => {
    const size = 100_000; // > CHUNK_SIZE in base64.ts (0x8000 = 32768)
    const original = new Uint8Array(size);
    for (let i = 0; i < size; i++) original[i] = i & 0xff;
    const encoded = arrayBufferToBase64(original.buffer);
    const decoded = new Uint8Array(base64ToArrayBuffer(encoded));
    expect(decoded.length).toBe(size);
    expect(decoded[0]).toBe(0);
    expect(decoded[255]).toBe(255);
    expect(decoded[size - 1]).toBe((size - 1) & 0xff);
  });

  it("base64ToBlob preserves type", () => {
    const blob = base64ToBlob("AAEC", "application/pdf");
    expect(blob.type).toBe("application/pdf");
    expect(blob.size).toBe(3);
  });
});
