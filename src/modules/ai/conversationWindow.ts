import type { ChatMessage } from "./types";

export interface ConversationWindowOptions {
  maxRecentMessages?: number;
  maxSummaryChars?: number;
}

function compactText(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function formatLine(role: ChatMessage["role"], content: string): string {
  const label = role === "assistant" ? "assistant" : role === "user" ? "user" : "system";
  return `- ${label}: ${content}`;
}

export function buildConversationWindow(
  messages: ChatMessage[],
  options: ConversationWindowOptions = {},
): ChatMessage[] {
  const maxRecentMessages = options.maxRecentMessages ?? 16;
  const maxSummaryChars = options.maxSummaryChars ?? 800;

  if (messages.length <= maxRecentMessages) {
    return messages;
  }

  const older = messages.slice(0, -maxRecentMessages);
  const recent = messages.slice(-maxRecentMessages);

  const lines: string[] = [];
  let used = 0;

  for (const m of older) {
    const compact = compactText(m.content);
    if (!compact) continue;
    const clipped = compact.length > 140 ? `${compact.slice(0, 137)}...` : compact;
    const line = formatLine(m.role, clipped);
    if (used + line.length + 1 > maxSummaryChars) break;
    lines.push(line);
    used += line.length + 1;
  }

  const summaryBody = lines.length > 0 ? lines.join("\n") : "- (No earlier conversational content.)";
  const summary: ChatMessage = {
    role: "system",
    content:
      "Conversation summary of earlier turns (compressed to save context window). " +
      "Prefer newer turns below if any detail conflicts.\n" +
      summaryBody,
  };

  return [summary, ...recent];
}
