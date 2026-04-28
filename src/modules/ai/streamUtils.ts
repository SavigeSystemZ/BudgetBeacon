/**
 * Read a Response body as UTF-8 lines. Splits on \n and keeps a tail buffer
 * across reads so multi-byte / mid-line boundaries don't corrupt the stream.
 *
 * Used for Ollama JSONL (one JSON object per line) and OpenAI-compatible
 * SSE (text/event-stream — `data: {...}` lines separated by blank lines).
 */
export async function* readLines(body: ReadableStream<Uint8Array>): AsyncGenerator<string> {
  const reader = body.getReader();
  const decoder = new TextDecoder("utf-8");
  let buf = "";
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      buf += decoder.decode(value, { stream: true });
      let nl = buf.indexOf("\n");
      while (nl >= 0) {
        yield buf.slice(0, nl);
        buf = buf.slice(nl + 1);
        nl = buf.indexOf("\n");
      }
    }
    if (buf.length > 0) yield buf;
  } finally {
    reader.releaseLock();
  }
}
