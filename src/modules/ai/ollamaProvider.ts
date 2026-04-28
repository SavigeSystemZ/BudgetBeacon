import type { AiProvider, ChatMessage, ChatOptions } from "./types";
import { AiProviderError } from "./types";

/**
 * Ollama-native chat. Endpoint defaults to http://localhost:11434/api/chat.
 *
 * Ollama returns a streamed JSONL response by default; we send `stream: false`
 * so we get a single JSON envelope back. Streaming lands in M7 follow-up.
 */
export class OllamaProvider implements AiProvider {
  readonly id = "ollama";
  readonly isLocal = true;
  private readonly endpoint: string;
  private readonly defaultModel: string;
  private readonly fetchImpl: typeof fetch;

  constructor(endpoint: string, defaultModel: string = "llama3.2", fetchImpl: typeof fetch = fetch) {
    this.endpoint = endpoint;
    this.defaultModel = defaultModel;
    this.fetchImpl = fetchImpl;
  }

  async chat(messages: ChatMessage[], opts: ChatOptions = {}): Promise<string> {
    const url = normalizeChatUrl(this.endpoint);
    let res: Response;
    try {
      res = await this.fetchImpl(url, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: opts.signal,
        body: JSON.stringify({
          model: opts.model || this.defaultModel,
          messages,
          stream: false,
          options: { temperature: opts.temperature ?? 0.2 },
        }),
      });
    } catch (err) {
      throw new AiProviderError(
        `Ollama request failed (network or CORS). Is Ollama running at ${url}?`,
        err,
      );
    }

    if (!res.ok) {
      const body = await safeText(res);
      throw new AiProviderError(
        `Ollama responded ${res.status}: ${body || res.statusText}`,
        undefined,
        res.status,
      );
    }

    const json = await res.json();
    const content = json?.message?.content;
    if (typeof content !== "string") {
      throw new AiProviderError(`Ollama returned an unexpected payload shape (no message.content).`);
    }
    return content.trim();
  }
}

/**
 * Normalize various ways a user might enter the endpoint.
 *  - "http://localhost:11434"               → "http://localhost:11434/api/chat"
 *  - "http://localhost:11434/"              → "http://localhost:11434/api/chat"
 *  - "http://localhost:11434/api/generate"  → "http://localhost:11434/api/chat" (legacy default in Settings)
 *  - "http://localhost:11434/api/chat"      → as-is
 */
export function normalizeChatUrl(endpoint: string): string {
  const trimmed = endpoint.trim().replace(/\/+$/, "");
  if (trimmed.endsWith("/api/chat")) return trimmed;
  if (trimmed.endsWith("/api/generate")) return trimmed.replace(/\/api\/generate$/, "/api/chat");
  return `${trimmed}/api/chat`;
}

async function safeText(res: Response): Promise<string> {
  try {
    return await res.text();
  } catch {
    return "";
  }
}
