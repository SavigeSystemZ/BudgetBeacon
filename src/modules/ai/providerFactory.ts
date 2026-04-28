import { db } from "../../db/db";
import type { AiProvider, AiConfigRow } from "./types";
import { OllamaProvider } from "./ollamaProvider";
import { OpenAiCompatibleProvider } from "./openAiCompatibleProvider";

/** Must match the id used in SettingsRoute.tsx when persisting aiConfig. */
export const AI_CONFIG_ID = "primary";

export interface ResolvedProvider {
  provider: AiProvider | null;
  reason?: string;
  config?: AiConfigRow;
}

/**
 * Read the persisted aiConfig and return the matching provider.
 * Returns `provider: null` when no usable configuration exists; the chatbot
 * falls back to a clearly-labeled placeholder reply in that case.
 */
export async function resolveActiveProvider(): Promise<ResolvedProvider> {
  const row = (await db.aiConfig.get(AI_CONFIG_ID)) as AiConfigRow | undefined;
  if (!row) return { provider: null, reason: "no-config" };
  return resolveProviderFromConfig(row);
}

export function resolveProviderFromConfig(row: AiConfigRow): ResolvedProvider {
  if (row.provider === "local") {
    const endpoint = row.localEndpoint?.trim();
    if (!endpoint) return { provider: null, reason: "missing-endpoint", config: row };
    const model = row.model?.trim() || undefined;
    return { provider: new OllamaProvider(endpoint, model), config: row };
  }

  if (row.provider === "api") {
    const apiKey = row.apiKey?.trim();
    if (!apiKey) return { provider: null, reason: "missing-api-key", config: row };
    const baseUrl = row.localEndpoint?.trim() || "https://api.openai.com";
    const model = row.model?.trim() || undefined;
    return { provider: new OpenAiCompatibleProvider(baseUrl, apiKey, model), config: row };
  }

  return { provider: null, reason: "unknown-provider", config: row };
}
