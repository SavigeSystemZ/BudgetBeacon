import { describe, it, expect, vi } from "vitest";
import { OllamaProvider, normalizeChatUrl } from "./ollamaProvider";
import { OpenAiCompatibleProvider, normalizeOpenAiUrl } from "./openAiCompatibleProvider";
import { resolveProviderFromConfig } from "./providerFactory";
import { AiProviderError } from "./types";

describe("M7 — AI provider abstraction", () => {
  describe("URL normalization", () => {
    it("appends /api/chat to bare Ollama host", () => {
      expect(normalizeChatUrl("http://localhost:11434")).toBe("http://localhost:11434/api/chat");
    });
    it("rewrites /api/generate to /api/chat", () => {
      expect(normalizeChatUrl("http://localhost:11434/api/generate")).toBe(
        "http://localhost:11434/api/chat",
      );
    });
    it("preserves explicit /api/chat", () => {
      expect(normalizeChatUrl("http://h.local:11434/api/chat")).toBe("http://h.local:11434/api/chat");
    });
    it("strips trailing slash", () => {
      expect(normalizeChatUrl("http://localhost:11434/")).toBe("http://localhost:11434/api/chat");
    });

    it("appends /v1/chat/completions to bare OpenAI base", () => {
      expect(normalizeOpenAiUrl("https://api.openai.com")).toBe(
        "https://api.openai.com/v1/chat/completions",
      );
    });
    it("appends /chat/completions when base ends in /v1", () => {
      expect(normalizeOpenAiUrl("https://api.groq.com/openai/v1")).toBe(
        "https://api.groq.com/openai/v1/chat/completions",
      );
    });
    it("preserves full /v1/chat/completions URL", () => {
      expect(normalizeOpenAiUrl("https://api.openai.com/v1/chat/completions")).toBe(
        "https://api.openai.com/v1/chat/completions",
      );
    });
  });

  describe("OllamaProvider", () => {
    it("parses message.content from Ollama-shaped response", async () => {
      const mockFetch = vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({ message: { role: "assistant", content: "  hi there  " }, done: true }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
      const provider = new OllamaProvider("http://localhost:11434", "llama3.2", mockFetch);
      const out = await provider.chat([{ role: "user", content: "hello" }]);
      expect(out).toBe("hi there");
      expect(mockFetch).toHaveBeenCalledOnce();
      const [url, init] = mockFetch.mock.calls[0];
      expect(url).toBe("http://localhost:11434/api/chat");
      const body = JSON.parse((init as RequestInit).body as string);
      expect(body.stream).toBe(false);
      expect(body.model).toBe("llama3.2");
    });

    it("throws AiProviderError on non-2xx", async () => {
      const mockFetch = vi.fn().mockResolvedValue(
        new Response("model not found", { status: 404, statusText: "Not Found" }),
      );
      const provider = new OllamaProvider("http://localhost:11434", "missing", mockFetch);
      await expect(provider.chat([{ role: "user", content: "hi" }])).rejects.toThrow(AiProviderError);
    });

    it("wraps fetch network errors in AiProviderError", async () => {
      const mockFetch = vi.fn().mockRejectedValue(new TypeError("Failed to fetch"));
      const provider = new OllamaProvider("http://localhost:11434", "x", mockFetch);
      await expect(provider.chat([{ role: "user", content: "hi" }])).rejects.toThrow(/Ollama request failed/);
    });
  });

  describe("OpenAiCompatibleProvider", () => {
    it("sends Bearer auth + parses choices[0].message.content", async () => {
      const mockFetch = vi.fn().mockResolvedValue(
        new Response(
          JSON.stringify({ choices: [{ message: { role: "assistant", content: "ok" } }] }),
          { status: 200, headers: { "Content-Type": "application/json" } },
        ),
      );
      const provider = new OpenAiCompatibleProvider(
        "https://api.openai.com",
        "sk-test",
        "gpt-4o-mini",
        mockFetch,
      );
      const out = await provider.chat([{ role: "user", content: "hi" }]);
      expect(out).toBe("ok");
      const init = mockFetch.mock.calls[0][1] as RequestInit;
      expect((init.headers as Record<string, string>).Authorization).toBe("Bearer sk-test");
    });

    it("throws when api key is missing", async () => {
      const mockFetch = vi.fn();
      const provider = new OpenAiCompatibleProvider("https://api.openai.com", "", "x", mockFetch);
      await expect(provider.chat([{ role: "user", content: "hi" }])).rejects.toThrow(/Missing API key/);
      expect(mockFetch).not.toHaveBeenCalled();
    });
  });

  describe("resolveProviderFromConfig", () => {
    it("returns OllamaProvider when provider=local with endpoint", () => {
      const r = resolveProviderFromConfig({
        id: "default",
        provider: "local",
        localEndpoint: "http://localhost:11434",
        model: "llama3.2",
      });
      expect(r.provider?.id).toBe("ollama");
      expect(r.provider?.isLocal).toBe(true);
    });

    it("returns null + reason when local provider has no endpoint", () => {
      const r = resolveProviderFromConfig({ id: "default", provider: "local" });
      expect(r.provider).toBeNull();
      expect(r.reason).toBe("missing-endpoint");
    });

    it("returns OpenAiCompatibleProvider when provider=api with key", () => {
      const r = resolveProviderFromConfig({
        id: "default",
        provider: "api",
        apiKey: "sk-test",
        model: "gpt-4o-mini",
      });
      expect(r.provider?.id).toBe("openai-compatible");
      expect(r.provider?.isLocal).toBe(false);
    });

    it("returns null + reason when cloud provider has no key", () => {
      const r = resolveProviderFromConfig({ id: "default", provider: "api" });
      expect(r.provider).toBeNull();
      expect(r.reason).toBe("missing-api-key");
    });
  });
});
