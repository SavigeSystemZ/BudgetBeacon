/**
 * AI provider abstraction. M7 ships two concrete providers:
 *  - OllamaProvider (local, default) — talks to /api/chat at the configured endpoint
 *  - OpenAiCompatibleProvider (cloud opt-in) — POSTs to /v1/chat/completions with
 *    a Bearer token. Works with OpenAI, Together, Groq, OpenRouter, Anthropic via
 *    proxy, and most local servers (LM Studio, llama.cpp, vLLM) out of the box.
 *
 * No tool-use yet — that lands in M7.2 with explicit user-confirmation UI.
 * For now the assistant is read-only: it ingests db context, returns text.
 */

export type ChatRole = "system" | "user" | "assistant";

export interface ChatMessage {
  role: ChatRole;
  content: string;
}

export interface ChatOptions {
  /** Model id (e.g. "llama3.2", "gpt-4o-mini"). Falls back to provider default. */
  model?: string;
  /** AbortSignal so the caller can cancel a slow request. */
  signal?: AbortSignal;
  /** Lower = more deterministic. 0.2 is a good default for budget math. */
  temperature?: number;
}

export interface AiProvider {
  /** Stable identifier — "ollama" | "openai-compatible". */
  id: string;
  /** True when the provider is reachable on a private/local network only. */
  isLocal: boolean;
  /** Single-shot, non-streaming completion. */
  chat(messages: ChatMessage[], opts?: ChatOptions): Promise<string>;
}

/**
 * Persisted shape of `aiConfig`. Mirrors the Dexie row in `db.ts`.
 * `provider` value reflects the historical schema; the new factory maps it:
 *   "local" → OllamaProvider, "api" → OpenAiCompatibleProvider.
 */
export interface AiConfigRow {
  id: string;
  provider: "local" | "api";
  apiKey?: string;
  localEndpoint?: string;
  model?: string;
}

export class AiProviderError extends Error {
  readonly cause?: unknown;
  readonly status?: number;

  constructor(message: string, cause?: unknown, status?: number) {
    super(message);
    this.name = "AiProviderError";
    this.cause = cause;
    this.status = status;
  }
}
