import { useState, useEffect, useRef, useMemo } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardContent } from "./ui/card";
import { Button } from "./ui/button";
import { Input } from "./ui/input";
import { Bot, X, Send, Sparkles, ShieldAlert } from "lucide-react";
import { cn } from "../lib/utils";
import { GlassCard } from "./ui/GlassCard";

export function BeaconChatbot() {
  const [isOpen, setIsOpen] = useState(false);
  const [input, setInput] = useState("");
  const [isThinking, setIsThinking] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  const messagesRaw = useLiveQuery(() => db.chatMessages.orderBy("timestamp").toArray(), []) || [];
  const messages = useMemo(() => messagesRaw, [messagesRaw]);

  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [messages, isOpen]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMessage = {
      id: createId(),
      role: "user" as const,
      content: input,
      timestamp: new Date().toISOString()
    };

    await db.chatMessages.add(userMessage);
    setInput("");
    setIsThinking(true);

    setTimeout(async () => {
      let response = "I'm ready to help. You can ask me to analyze your loops or scavenge documents.";
      
      if (input.toLowerCase().includes("analyze")) {
        const totalIncome = incomes?.reduce((acc, i) => acc + i.amount, 0) || 0;
        const subCount = subscriptions?.length || 0;
        response = `Agentic Sweep Complete: You have ${subCount} active subscriptions and a total monthly inflow of $${totalIncome.toLocaleString()}. I recommend auditing your Subscriptions Shelf to increase propulsion surplus.`;
      } else if (input.toLowerCase().includes("scavenge")) {
        response = "Scavenging Protocol Initiated. Please upload a PDF or Image in The Vault, and I will extract the financial telemetry for you automatically.";
      }

      const botResponse = {
        id: createId(),
        role: "assistant" as const,
        content: response,
        timestamp: new Date().toISOString()
      };
      await db.chatMessages.add(botResponse);
      setIsThinking(false);
    }, 1500);
  };

  const clearChat = async () => {
    if (window.confirm("Wipe conversation history?")) {
      await db.chatMessages.clear();
    }
  };

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
          <CardHeader className="bg-primary/10 border-b border-primary/10 p-5 flex flex-row items-center justify-between">
            <div className="flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-primary" />
              <CardTitle className="text-sm font-black uppercase italic tracking-tighter text-primary">Beacon AI Agent</CardTitle>
            </div>
            <Button variant="ghost" size="sm" onClick={clearChat} className="h-8 w-8 p-0 text-muted-foreground hover:text-destructive rounded-full">
              <ShieldAlert className="h-4 w-4" />
            </Button>
          </CardHeader>
          
          <CardContent className="flex-1 overflow-y-auto p-4 space-y-6 scrollbar-none" ref={scrollRef}>
            {messages.length === 0 && (
              <div className="h-full flex flex-col items-center justify-center text-center space-y-4 opacity-50">
                <Bot className="h-16 w-16 text-primary animate-pulse" />
                <div className="space-y-1">
                   <p className="font-black text-xs uppercase tracking-widest italic">Agentic Ready</p>
                   <p className="text-[10px] font-bold text-muted-foreground uppercase">Analyzing Household Telemetry...</p>
                </div>
              </div>
            )}
            
            {messages.map((m) => (
              <div key={m.id} className={cn("flex flex-col space-y-1 max-w-[85%]", m.role === "user" ? "ml-auto items-end" : "mr-auto items-start")}>
                <div className={cn(
                  "p-4 rounded-2xl text-[13px] font-medium leading-relaxed shadow-xl",
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
          </CardContent>

          <div className="p-5 bg-primary/5 border-t border-primary/10 space-y-4">
            <div className="flex gap-2">
              <Input 
                value={input} 
                onChange={(e) => setInput(e.target.value)} 
                onKeyDown={(e) => e.key === "Enter" && handleSend()} 
                placeholder="Message Beacon Agent..." 
                className="bg-background/50 border-none shadow-inner h-12 rounded-2xl px-4 font-bold" 
              />
              <Button size="icon" onClick={handleSend} className="shrink-0 h-12 w-12 rounded-2xl shadow-xl shadow-primary/20">
                <Send className="h-4 w-4" />
              </Button>
            </div>
            <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
              {["Analyze Dashboard", "Initiate Scavenge", "Check Stability"].map(q => (
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
