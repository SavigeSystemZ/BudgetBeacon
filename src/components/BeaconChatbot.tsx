import { useState, useEffect, useRef, useMemo } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardContent } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Bot, X, Send, Sparkles, ShieldAlert, Cloud, HardDrive, AlertCircle } from "lucide-react";
import { cn } from "../lib/utils";
import { GlassCard } from "./ui/GlassCard";
import { DemoBadge } from "./ui/DemoBadge";
import { resolveActiveProvider } from "../modules/ai/providerFactory";
import { buildAssistantContext } from "../modules/ai/contextBuilder";
import { AiProviderError, type ChatMessage as AiChatMessage } from "../modules/ai/types";

const HISTORY_TURNS = 8;

export function BeaconChatbot() {
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState("");
  const [isThinking, setIsThinking] = useState(false);
  const [providerStatus, setProviderStatus] = useState<{
    kind: "configured" | "missing";
    label: string;
    isLocal: boolean;
  }>({ kind: "missing", label: "Not configured", isLocal: true });
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const scrollRef = useRef<HTMLDivElement>(null);
  const abortRef = useRef<AbortController | null>(null);

  const messagesRaw = useLiveQuery(() => db.chatMessages.orderBy("timestamp").toArray(), []) || [];
  const messages = useMemo(() => messagesRaw, [messagesRaw]);

  // Live-refresh provider status as the user edits Settings.
  const aiConfigRow = useLiveQuery(() => db.aiConfig.get("default"), []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const r = await resolveActiveProvider();
      if (cancelled) return;
      if (r.provider) {
        setProviderStatus({
          kind: "configured",
          label: r.provider.id === "ollama" ? "Local (Ollama)" : "Cloud (OpenAI-compatible)",
          isLocal: r.provider.isLocal,
        });
      } else {
        setProviderStatus({
          kind: "missing",
          label: r.reason === "missing-endpoint"
            ? "Local endpoint missing"
            : r.reason === "missing-api-key"
              ? "API key missing"
              : "Not configured",
          isLocal: true,
        });
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [aiConfigRow]);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isOpen, isThinking]);

  const handleSend = async () => {
    if (!input.trim() || isThinking) return;
    setErrorMessage(null);

    const userText = input.trim();
    const userMessage = {
      id: createId(),
      role: "user" as const,
      content: userText,
      timestamp: new Date().toISOString(),
    };
    await db.chatMessages.add(userMessage);
    setInput("");
    setIsThinking(true);

    try {
      const { provider } = await resolveActiveProvider();

      let replyText: string;
      if (!provider) {
        replyText = await placeholderReply(userText);
      } else {
        const context = await buildAssistantContext();
        const recent = (await db.chatMessages.orderBy("timestamp").toArray()).slice(-HISTORY_TURNS * 2);
        const ai: AiChatMessage[] = [
          { role: "system", content: context.systemPrompt },
          ...recent.map((m) => ({ role: m.role, content: m.content })),
        ];

        abortRef.current?.abort();
        abortRef.current = new AbortController();
        replyText = await provider.chat(ai, { signal: abortRef.current.signal });
      }

      await db.chatMessages.add({
        id: createId(),
        role: "assistant",
        content: replyText,
        timestamp: new Date().toISOString(),
      });
    } catch (err) {
      const msg = err instanceof AiProviderError
        ? err.message
        : err instanceof Error
          ? err.message
          : "Unknown error talking to the model.";
      setErrorMessage(msg);
      await db.chatMessages.add({
        id: createId(),
        role: "assistant",
        content: `(Could not reach model.) ${msg}\n\nTip: confirm the endpoint and model in Settings → AI Configuration. Local Ollama users — make sure \`ollama serve\` is running.`,
        timestamp: new Date().toISOString(),
      });
    } finally {
      setIsThinking(false);
    }
  };

  const handleStop = () => {
    abortRef.current?.abort();
    setIsThinking(false);
  };

  const clearChat = async () => {
    if (window.confirm("Wipe conversation history?")) {
      await db.chatMessages.clear();
    }
  };

  const showDemoBadge = providerStatus.kind === "missing";

  return (
    <>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={cn(
          "fixed bottom-24 md:bottom-8 right-6 z-[100] h-14 w-14 rounded-full flex items-center justify-center shadow-2xl transition-all hover:scale-110 active:scale-95",
          isOpen ? "bg-destructive text-destructive-foreground rotate-90 shadow-destructive/40" : "bg-primary text-primary-foreground shadow-primary/40 border border-white/20"
        )}
      >
        {isOpen ? <X className="h-6 w-6" /> : <Bot className="h-6 w-6" />}
      </button>

      {isOpen && (
        <GlassCard intensity="high" className="fixed bottom-40 md:bottom-24 right-6 z-[100] w-[350px] md:w-[400px] h-[550px] flex flex-col shadow-[0_30px_100px_rgba(0,0,0,0.5)] border-primary/20 bg-card/90 overflow-hidden animate-in fade-in slide-in-from-bottom-10 duration-500">
          <CardHeader className="bg-primary/10 border-b border-primary/10 p-5 space-y-2">
            <div className="flex flex-row items-center justify-between">
              <div className="flex items-center gap-2">
                <Sparkles className="h-5 w-5 text-primary" />
                <CardTitle className="text-sm font-black uppercase italic tracking-tighter text-primary">Beacon AI Agent</CardTitle>
              </div>
              <Button variant="ghost" size="sm" onClick={clearChat} className="h-8 w-8 p-0 text-muted-foreground hover:text-destructive rounded-full">
                <ShieldAlert className="h-4 w-4" />
              </Button>
            </div>
            {showDemoBadge ? (
              <DemoBadge milestone="M7">
                {providerStatus.label}. Configure in Settings → AI Configuration.
              </DemoBadge>
            ) : (
              <div className="flex items-center gap-2 text-[9px] font-black uppercase tracking-widest text-primary/80">
                {providerStatus.isLocal ? <HardDrive className="h-3 w-3" /> : <Cloud className="h-3 w-3" />}
                <span>{providerStatus.label}</span>
              </div>
            )}
          </CardHeader>

          <CardContent className="flex-1 overflow-y-auto p-4 space-y-6 scrollbar-none" ref={scrollRef}>
            {messages.length === 0 && (
              <div className="h-full flex flex-col items-center justify-center text-center space-y-4 opacity-50">
                <Bot className="h-16 w-16 text-primary animate-pulse" />
                <div className="space-y-1">
                   <p className="font-black text-xs uppercase tracking-widest italic">Agentic Ready</p>
                   <p className="text-[10px] font-bold text-muted-foreground uppercase">
                     {providerStatus.kind === "configured" ? "Ready when you are." : "No model connected."}
                   </p>
                </div>
              </div>
            )}

            {messages.map((m) => (
              <div key={m.id} className={cn("flex flex-col space-y-1 max-w-[85%]", m.role === "user" ? "ml-auto items-end" : "mr-auto items-start")}>
                <div className={cn(
                  "p-4 rounded-2xl text-[13px] font-medium leading-relaxed shadow-xl whitespace-pre-wrap",
                  m.role === "user"
                    ? "bg-primary text-primary-foreground rounded-tr-none shadow-primary/20"
                    : "bg-background/80 border border-primary/10 rounded-tl-none backdrop-blur-xl italic"
                )}>
                  {m.content}
                </div>
                <span className="text-[8px] font-black uppercase tracking-widest text-muted-foreground px-2 opacity-50">
                  {m.role === "assistant" ? "Beacon Agent" : "Telemetry Inflow"}
                </span>
              </div>
            ))}

            {isThinking && (
              <div className="flex items-center gap-2 text-primary p-2 animate-pulse bg-primary/5 rounded-xl w-fit">
                <div className="h-1.5 w-1.5 bg-current rounded-full animate-bounce" />
                <div className="h-1.5 w-1.5 bg-current rounded-full animate-bounce [animation-delay:0.2s]" />
                <div className="h-1.5 w-1.5 bg-current rounded-full animate-bounce [animation-delay:0.4s]" />
              </div>
            )}

            {errorMessage && (
              <div role="alert" className="flex items-start gap-2 p-3 rounded-xl border border-destructive/40 bg-destructive/10 text-destructive text-[11px]">
                <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
                <span>{errorMessage}</span>
              </div>
            )}
          </CardContent>

          <div className="p-5 bg-primary/5 border-t border-primary/10 space-y-4">
            <div className="flex gap-2">
              <Input
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => e.key === "Enter" && handleSend()}
                disabled={isThinking}
                placeholder={providerStatus.kind === "configured" ? "Message Beacon Agent..." : "Configure a model in Settings to chat..."}
                className="bg-background/50 border-none shadow-inner h-12 rounded-2xl px-4 font-bold"
              />
              {isThinking ? (
                <Button size="icon" onClick={handleStop} variant="destructive" className="shrink-0 h-12 w-12 rounded-2xl">
                  <X className="h-4 w-4" />
                </Button>
              ) : (
                <Button size="icon" onClick={handleSend} className="shrink-0 h-12 w-12 rounded-2xl shadow-xl shadow-primary/20">
                  <Send className="h-4 w-4" />
                </Button>
              )}
            </div>
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
              {["Analyze my budget", "Where can I cut spending?", "Stability check"].map(q => (
                <button
                  key={q}
                  onClick={() => setInput(q)}
                  className="whitespace-nowrap px-4 py-1.5 rounded-full bg-primary/10 border border-primary/20 text-[9px] font-black uppercase italic tracking-widest text-primary hover:bg-primary/20 transition-all"
                >
                  {q}
                </button>
              ))}
            </div>
          </div>
        </GlassCard>
      )}
    </>
  );
}

/**
 * No-provider fallback. Honest about being a placeholder; pulls real numbers
 * so the user is not misled by fabricated values.
 */
async function placeholderReply(userText: string): Promise<string> {
  const ctx = await buildAssistantContext();
  const f = ctx.facts;
  const fmt = (n: number) =>
    n.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

  const lower = userText.toLowerCase();
  const lines: string[] = [
    "(No model connected — replying from real db aggregates only.)",
    `Monthly income ${fmt(f.monthlyIncome)} · bills ${fmt(f.monthlyBills)} · debt min ${fmt(f.monthlyDebtMin)} · subs ${fmt(f.monthlySubs)}.`,
    `Leftover after required + savings: ${fmt(f.netMonthly)}. Stability index ${f.stabilityIndex}/100 (${f.stabilityLabel}).`,
  ];

  if (lower.includes("cut") || lower.includes("save") || lower.includes("reduce")) {
    lines.push(
      `For real recommendations, configure a model in Settings → AI Configuration. ` +
        `In the meantime, the Mission Control and Reports screens already surface the highest-leverage cuts based on these numbers.`,
    );
  } else if (lower.includes("stability") || lower.includes("health")) {
    lines.push(`See Mission Control's Stability Index card for the full breakdown.`);
  } else {
    lines.push(`Configure a model in Settings to get a real conversational answer to "${userText}".`);
  }

  return lines.join("\n");
}
