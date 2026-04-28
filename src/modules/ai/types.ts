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
  /**
   * Streaming completion — yields text deltas as they arrive. Each yielded
   * string is a partial chunk; the caller concatenates to build the full
   * response. AbortSignal cancels mid-stream.
   */
  chatStream(messages: ChatMessage[], opts?: ChatOptions): AsyncIterable<string>;
}

/**
 * Structured action the assistant can propose. Surfaced to the user as a
 * confirm-or-deny chip in the chatbot; nothing is committed without explicit
 * approval. The grammar is intentionally narrow — extending it requires
 * adding an applyProposedAction handler.
 */
export type BillCategory = "housing" | "utilities" | "food" | "transportation" | "insurance" | "subscriptions" | "medical" | "other";
export type StashCategory = "emergency" | "vehicle" | "home" | "vacation" | "debt-payoff" | "holiday" | "other";
export type StashPriority = "low" | "medium" | "high";

export type ProposedAction =
  | { type: "addIncome"; label: string; amount: number; frequency: "weekly" | "biweekly" | "semimonthly" | "monthly" | "annual" }
  | { type: "addBill"; label: string; amount: number; frequency: "weekly" | "biweekly" | "monthly" | "annual"; category?: BillCategory; dueDay?: number }
  | { type: "addSavingsGoal"; label: string; targetAmount: number; monthlyContribution: number; category?: StashCategory; priority?: StashPriority };

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
