/**
 * Budget Beacon sync relay — Cloudflare Worker + Durable Object.
 *
 * A y-websocket–compatible relay. One Durable Object instance per room
 * (householdId) holds a server-side Y.Doc so a device can sync even when the
 * other device is offline (the DO replays accumulated state to late joiners).
 *
 * Zero-knowledge: every value inside the Yjs document is already AES-GCM
 * ciphertext produced on-device. The relay never has the household key and
 * cannot read user data.
 *
 * Access control: connections must present a valid HMAC join token
 * (?token=...) signed with RELAY_SECRET. If RELAY_SECRET is unset the relay
 * runs in open mode (development only) and logs a warning.
 *
 * Protocol: y-protocols sync (messageSync=0) + awareness (messageAwareness=1),
 * matching the `y-websocket` client used by the app.
 */
import * as Y from "yjs";
import * as syncProtocol from "y-protocols/sync";
import * as awarenessProtocol from "y-protocols/awareness";
import * as encoding from "lib0/encoding";
import * as decoding from "lib0/decoding";

export interface Env {
  YJS_ROOM: DurableObjectNamespace;
  RELAY_SECRET?: string;
}

const MESSAGE_SYNC = 0;
const MESSAGE_AWARENESS = 1;

const DOC_KEY = "ydoc-state";

function base64UrlToBytes(s: string): Uint8Array {
  const b64 = s.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((s.length + 3) % 4);
  const bin = atob(b64);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out;
}

/** Verify HMAC join token: base64url(HMAC_SHA256(secret, `${room}.${exp}`)) + "." + exp */
async function verifyToken(secret: string, room: string, token: string | null): Promise<boolean> {
  if (!token) return false;
  const dot = token.lastIndexOf(".");
  if (dot < 0) return false;
  const sigPart = token.slice(0, dot);
  const exp = Number(token.slice(dot + 1));
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return false;
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(secret),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["verify"],
    );
    return await crypto.subtle.verify(
      "HMAC",
      key,
      base64UrlToBytes(sigPart),
      new TextEncoder().encode(`${room}.${exp}`),
    );
  } catch {
    return false;
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (request.headers.get("Upgrade") !== "websocket") {
      return new Response("Budget Beacon sync relay. Connect a y-websocket client.", { status: 426 });
    }
    // Path is /<room>; the y-websocket client appends the room name.
    const room = decodeURIComponent(url.pathname.replace(/^\/+/, "")) || "default";

    if (env.RELAY_SECRET) {
      const ok = await verifyToken(env.RELAY_SECRET, room, url.searchParams.get("token"));
      if (!ok) return new Response("Invalid or expired join token.", { status: 401 });
    } else {
      console.warn("RELAY_SECRET unset — relay is OPEN (development mode only).");
    }

    const id = env.YJS_ROOM.idFromName(room);
    return env.YJS_ROOM.get(id).fetch(request);
  },
};

/** One instance per room. Holds the authoritative server-side Y.Doc. */
export class YjsRoom implements DurableObject {
  private state: DurableObjectState;
  private doc: Y.Doc;
  private awareness: awarenessProtocol.Awareness;
  private sessions = new Set<WebSocket>();
  private loaded = false;

  constructor(state: DurableObjectState) {
    this.state = state;
    this.doc = new Y.Doc();
    this.awareness = new awarenessProtocol.Awareness(this.doc);

    // Persist document state whenever it changes (debounced via storage).
    this.doc.on("update", (update: Uint8Array, origin: unknown) => {
      this.broadcastSyncUpdate(update, origin);
      void this.persist();
    });
  }

  private async ensureLoaded() {
    if (this.loaded) return;
    const stored = await this.state.storage.get<ArrayBuffer | Uint8Array>(DOC_KEY);
    if (stored) {
      Y.applyUpdate(this.doc, new Uint8Array(stored as ArrayBuffer), "storage");
    }
    this.loaded = true;
  }

  private async persist() {
    await this.state.storage.put(DOC_KEY, Y.encodeStateAsUpdate(this.doc));
  }

  async fetch(_request: Request): Promise<Response> {
    await this.ensureLoaded();
    const pair = new WebSocketPair();
    const client = pair[0];
    const server = pair[1];
    server.accept();
    this.sessions.add(server);

    // Step 1: send our sync step 1 so the client reconciles with server state.
    {
      const enc = encoding.createEncoder();
      encoding.writeVarUint(enc, MESSAGE_SYNC);
      syncProtocol.writeSyncStep1(enc, this.doc);
      server.send(encoding.toUint8Array(enc));
    }
    // Send current awareness states, if any.
    const states = this.awareness.getStates();
    if (states.size > 0) {
      const enc = encoding.createEncoder();
      encoding.writeVarUint(enc, MESSAGE_AWARENESS);
      encoding.writeVarUint8Array(
        enc,
        awarenessProtocol.encodeAwarenessUpdate(this.awareness, Array.from(states.keys())),
      );
      server.send(encoding.toUint8Array(enc));
    }

    server.addEventListener("message", (event: MessageEvent) => {
      try {
        const data = new Uint8Array(event.data as ArrayBuffer);
        const decoder = decoding.createDecoder(data);
        const encoder = encoding.createEncoder();
        const messageType = decoding.readVarUint(decoder);
        switch (messageType) {
          case MESSAGE_SYNC: {
            encoding.writeVarUint(encoder, MESSAGE_SYNC);
            // readSyncMessage applies updates to this.doc (origin=server) and
            // writes any reply (e.g. syncStep2) into encoder.
            syncProtocol.readSyncMessage(decoder, encoder, this.doc, server);
            if (encoding.length(encoder) > 1) {
              server.send(encoding.toUint8Array(encoder));
            }
            break;
          }
          case MESSAGE_AWARENESS: {
            awarenessProtocol.applyAwarenessUpdate(
              this.awareness,
              decoding.readVarUint8Array(decoder),
              server,
            );
            break;
          }
        }
      } catch (err) {
        console.error("relay message error", err);
      }
    });

    const close = () => {
      this.sessions.delete(server);
      awarenessProtocol.removeAwarenessStates(
        this.awareness,
        Array.from(this.awareness.getStates().keys()),
        server,
      );
    };
    server.addEventListener("close", close);
    server.addEventListener("error", close);

    return new Response(null, { status: 101, webSocket: client });
  }

  /** Relay a doc update (origin !== a socket means it came from doc.on) to all peers. */
  private broadcastSyncUpdate(update: Uint8Array, origin: unknown) {
    const enc = encoding.createEncoder();
    encoding.writeVarUint(enc, MESSAGE_SYNC);
    syncProtocol.writeUpdate(enc, update);
    const msg = encoding.toUint8Array(enc);
    for (const ws of this.sessions) {
      if (ws === origin) continue; // don't echo to the originating socket
      try { ws.send(msg); } catch { this.sessions.delete(ws); }
    }
  }
}
