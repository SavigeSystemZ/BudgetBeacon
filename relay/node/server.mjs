/**
 * Budget Beacon sync relay — Node.js fallback.
 *
 * A self-contained y-websocket–compatible relay you can run anywhere Node runs
 * (a $5 VPS, a home box, localhost). Functionally equivalent to the Cloudflare
 * Worker: one in-memory Y.Doc per room, broadcast to peers, HMAC join-token
 * gating. Every value in the doc is already AES-GCM ciphertext — the relay
 * never sees plaintext or the household key.
 *
 *   RELAY_SECRET=... PORT=1234 node relay/node/server.mjs
 *
 * Leave RELAY_SECRET unset for open/dev mode (localhost only).
 */
import http from "node:http";
import crypto from "node:crypto";
import { WebSocketServer } from "ws";
import * as Y from "yjs";
import * as syncProtocol from "y-protocols/sync";
import * as awarenessProtocol from "y-protocols/awareness";
import * as encoding from "lib0/encoding";
import * as decoding from "lib0/decoding";

const PORT = Number(process.env.PORT || 1234);
const SECRET = process.env.RELAY_SECRET || "";
const MESSAGE_SYNC = 0;
const MESSAGE_AWARENESS = 1;

/** room name -> { doc, awareness, conns:Set<WebSocket> } */
const rooms = new Map();

function getRoom(name) {
  let r = rooms.get(name);
  if (!r) {
    const doc = new Y.Doc();
    const awareness = new awarenessProtocol.Awareness(doc);
    r = { doc, awareness, conns: new Set() };
    doc.on("update", (update, origin) => {
      const enc = encoding.createEncoder();
      encoding.writeVarUint(enc, MESSAGE_SYNC);
      syncProtocol.writeUpdate(enc, update);
      const msg = encoding.toUint8Array(enc);
      for (const ws of r.conns) {
        if (ws !== origin && ws.readyState === ws.OPEN) ws.send(msg);
      }
    });
    rooms.set(name, r);
  }
  return r;
}

function verifyToken(room, token) {
  if (!SECRET) return true; // open/dev mode
  if (!token) return false;
  const i = token.lastIndexOf(".");
  if (i < 0) return false;
  const sig = token.slice(0, i);
  const exp = Number(token.slice(i + 1));
  if (!Number.isFinite(exp) || exp < Math.floor(Date.now() / 1000)) return false;
  const expected = crypto.createHmac("sha256", SECRET).update(`${room}.${exp}`).digest("base64url");
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

const server = http.createServer((_req, res) => {
  res.writeHead(426, { "Content-Type": "text/plain" });
  res.end("Budget Beacon sync relay. Connect a y-websocket client.");
});

const wss = new WebSocketServer({ noServer: true });

server.on("upgrade", (req, socket, head) => {
  const url = new URL(req.url, "http://localhost");
  const room = decodeURIComponent(url.pathname.replace(/^\/+/, "")) || "default";
  if (!verifyToken(room, url.searchParams.get("token"))) {
    socket.write("HTTP/1.1 401 Unauthorized\r\n\r\n");
    socket.destroy();
    return;
  }
  wss.handleUpgrade(req, socket, head, (ws) => onConnect(ws, room));
});

function onConnect(ws, roomName) {
  const room = getRoom(roomName);
  room.conns.add(ws);
  ws.binaryType = "arraybuffer";

  // Sync step 1 + current awareness.
  {
    const enc = encoding.createEncoder();
    encoding.writeVarUint(enc, MESSAGE_SYNC);
    syncProtocol.writeSyncStep1(enc, room.doc);
    ws.send(encoding.toUint8Array(enc));
  }
  const states = room.awareness.getStates();
  if (states.size > 0) {
    const enc = encoding.createEncoder();
    encoding.writeVarUint(enc, MESSAGE_AWARENESS);
    encoding.writeVarUint8Array(
      enc,
      awarenessProtocol.encodeAwarenessUpdate(room.awareness, Array.from(states.keys())),
    );
    ws.send(encoding.toUint8Array(enc));
  }

  ws.on("message", (data) => {
    try {
      const bytes = new Uint8Array(data);
      const decoder = decoding.createDecoder(bytes);
      const encoder = encoding.createEncoder();
      const type = decoding.readVarUint(decoder);
      if (type === MESSAGE_SYNC) {
        encoding.writeVarUint(encoder, MESSAGE_SYNC);
        syncProtocol.readSyncMessage(decoder, encoder, room.doc, ws);
        if (encoding.length(encoder) > 1) ws.send(encoding.toUint8Array(encoder));
      } else if (type === MESSAGE_AWARENESS) {
        awarenessProtocol.applyAwarenessUpdate(room.awareness, decoding.readVarUint8Array(decoder), ws);
      }
    } catch (err) {
      console.error("relay message error", err);
    }
  });

  const cleanup = () => {
    room.conns.delete(ws);
    awarenessProtocol.removeAwarenessStates(
      room.awareness,
      Array.from(room.awareness.getStates().keys()),
      ws,
    );
    if (room.conns.size === 0) {
      // Keep the doc in memory briefly; drop empty rooms to bound memory.
      setTimeout(() => { if (room.conns.size === 0) rooms.delete(roomName); }, 60_000);
    }
  };
  ws.on("close", cleanup);
  ws.on("error", cleanup);
}

server.listen(PORT, () => {
  console.log(`Budget Beacon relay on :${PORT} — ${SECRET ? "token-gated" : "OPEN (dev only)"}`);
});
