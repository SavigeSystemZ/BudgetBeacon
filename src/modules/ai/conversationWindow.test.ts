import { describe, expect, it } from "vitest";
import { buildConversationWindow } from "./conversationWindow";
import type { ChatMessage } from "./types";

function msg(role: ChatMessage["role"], content: string): ChatMessage {
  return { role, content };
}

describe("buildConversationWindow", () => {
  it("returns original messages when under window limit", () => {
    const input = [msg("user", "hello"), msg("assistant", "hi there")];
    const out = buildConversationWindow(input, { maxRecentMessages: 4 });
    expect(out).toEqual(input);
  });

  it("compresses older turns into one system summary", () => {
    const input: ChatMessage[] = [
      msg("user", "turn 1"),
      msg("assistant", "turn 2"),
      msg("user", "turn 3"),
      msg("assistant", "turn 4"),
      msg("user", "turn 5"),
    ];
    const out = buildConversationWindow(input, { maxRecentMessages: 2, maxSummaryChars: 200 });

    expect(out.length).toBe(3);
    expect(out[0]?.role).toBe("system");
    expect(out[0]?.content).toContain("Conversation summary of earlier turns");
    expect(out[0]?.content).toContain("- user: turn 1");
    expect(out[1]?.content).toBe("turn 4");
    expect(out[2]?.content).toBe("turn 5");
  });
});
