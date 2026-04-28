import { describe, it, expect, vi } from "vitest";
import { OllamaProvider } from "./ollamaProvider";
import { OpenAiCompatibleProvider } from "./openAiCompatibleProvider";

function streamFromLines(lines: string[]): ReadableStream<Uint8Array> {
  const enc = new TextEncoder();
  return new ReadableStream({
    start(controller) {
      for (const l of lines) controller.enqueue(enc.encode(l));
      controller.close();
    },
  });
}

describe("M7.2 — streaming", () => {
  it("OllamaProvider yields message.content chunks from JSONL stream", async () => {
    const lines = [
      JSON.stringify({ message: { content: "Hel" }, done: false }) + "\n",
      JSON.stringify({ message: { content: "lo " }, done: false }) + "\n",
      JSON.stringify({ message: { content: "world" }, done: false }) + "\n",
      JSON.stringify({ message: { content: "" }, done: true }) + "\n",
    ];
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(streamFromLines(lines), { status: 200 }),
    );
    const provider = new OllamaProvider("http://localhost:11434", "llama3.2", mockFetch);
    const out: string[] = [];
    for await (const chunk of provider.chatStream([{ role: "user", content: "hi" }])) {
      out.push(chunk);
    }
    expect(out.join("")).toBe("Hello world");
  });

  it("OllamaProvider tolerates lines split across chunks", async () => {
    const enc = new TextEncoder();
    const stream = new ReadableStream<Uint8Array>({
      start(controller) {
        // Split a JSONL line across two chunks.
        controller.enqueue(enc.encode('{"message":{"content":"abc"},"done":'));
        controller.enqueue(enc.encode("false}\n"));
        controller.enqueue(enc.encode('{"message":{"content":"def"},"done":true}\n'));
        controller.close();
      },
    });
    const mockFetch = vi.fn().mockResolvedValue(new Response(stream, { status: 200 }));
    const provider = new OllamaProvider("http://localhost:11434", "x", mockFetch);
    const out: string[] = [];
    for await (const chunk of provider.chatStream([{ role: "user", content: "hi" }])) {
      out.push(chunk);
    }
    expect(out.join("")).toBe("abcdef");
  });

  it("OpenAiCompatibleProvider yields delta.content chunks from SSE stream", async () => {
    const sse = [
      `data: ${JSON.stringify({ choices: [{ delta: { content: "Hel" } }] })}\n`,
      "\n",
      `data: ${JSON.stringify({ choices: [{ delta: { content: "lo" } }] })}\n`,
      "\n",
      "data: [DONE]\n",
    ];
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(streamFromLines(sse), { status: 200 }),
    );
    const provider = new OpenAiCompatibleProvider("https://api.openai.com", "sk-test", "gpt-4o-mini", mockFetch);
    const out: string[] = [];
    for await (const chunk of provider.chatStream([{ role: "user", content: "hi" }])) {
      out.push(chunk);
    }
    expect(out.join("")).toBe("Hello");
  });

  it("OpenAiCompatibleProvider stops on data: [DONE]", async () => {
    // Anything after [DONE] must not be yielded.
    const sse = [
      `data: ${JSON.stringify({ choices: [{ delta: { content: "first" } }] })}\n\n`,
      "data: [DONE]\n",
      `data: ${JSON.stringify({ choices: [{ delta: { content: "should-not-appear" } }] })}\n\n`,
    ];
    const mockFetch = vi.fn().mockResolvedValue(
      new Response(streamFromLines(sse), { status: 200 }),
    );
    const provider = new OpenAiCompatibleProvider("https://api.openai.com", "sk-test", "x", mockFetch);
    const out: string[] = [];
    for await (const chunk of provider.chatStream([{ role: "user", content: "hi" }])) {
      out.push(chunk);
    }
    expect(out.join("")).toBe("first");
  });
});
