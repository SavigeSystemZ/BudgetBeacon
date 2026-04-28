import type { AiProvider, ChatMessage, ChatOptions } from "./types";
import { AiProviderError } from "./types";

/**
 * OpenAI-compatible chat. Works with OpenAI, Groq, Together, OpenRouter,
 * LM Studio, llama.cpp's server, and most other compatible endpoints.
 *
 * The user picks the base URL and api key; we always append /v1/chat/completions
 * unless the user already specified the full path.
 */
export class OpenAiCompatibleProvider implements AiProvider {
  readonly id = "openai-compatible";
  readonly isLocal: boolean;
  private readonly baseUrl: string;
  private readonly apiKey: string;
  private readonly defaultModel: string;
  private readonly fetchImpl: typeof fetch;

  constructor(
    baseUrl: string,
    apiKey: string,
    defaultModel: string = "gpt-4o-mini",
    fetchImpl: typeof fetch = fetch,
    isLocal: boolean = false,
  ) {
    this.baseUrl = baseUrl;
    this.apiKey = apiKey;
    this.defaultModel = defaultModel;
    this.fetchImpl = fetchImpl;
    this.isLocal = isLocal;
  }

  async chat(messages: ChatMessage[], opts: ChatOptions = {}): Promise<string> {
    if (!this.apiKey) throw new AiProviderError("Missing API key for cloud provider.");
    const url = normalizeOpenAiUrl(this.baseUrl);

    let res: Response;
    try {
      res = await this.fetchImpl(url, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${this.apiKey}`,
        },
        signal: opts.signal,
        body: JSON.stringify({
          model: opts.model || this.defaultModel,
          messages,
          temperature: opts.temperature ?? 0.2,
          stream: false,
        }),
      });
    } catch (err) {
      throw new AiProviderError(`Cloud chat request failed (network or CORS) at ${url}.`, err);
    }

    if (!res.ok) {
      const body = await safeText(res);
      throw new AiProviderError(
        `Cloud provider responded ${res.status}: ${body || res.statusText}`,
        undefined,
        res.status,
      );
    }

    const json = await res.json();
    const content = json?.choices?.[0]?.message?.content;
    if (typeof content !== "string") {
      throw new AiProviderError("Cloud provider returned unexpected payload (no choices[0].message.content).");
    }
    return content.trim();
  }
}

export function normalizeOpenAiUrl(baseUrl: string): string {
  const trimmed = baseUrl.trim().replace(/\/+$/, "");
  if (trimmed.endsWith("/chat/completions")) return trimmed;
  if (trimmed.endsWith("/v1")) return `${trimmed}/chat/completions`;
  return `${trimmed}/v1/chat/completions`;
}

async function safeText(res: Response): Promise<string> {
  try {
    return await res.text();
  } catch {
    return "";
  }
}
