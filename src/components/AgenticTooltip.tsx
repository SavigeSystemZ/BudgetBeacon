import React from "react";
import { 
  Tooltip, 
  TooltipContent, 
  TooltipProvider, 
  TooltipTrigger 
} from "./ui/tooltip";
import { Sparkles } from "lucide-react";

interface AgenticTooltipProps {
  children: React.ReactNode;
  content: string;
}

export function AgenticTooltip({ children, content }: AgenticTooltipProps) {
  return (
    <TooltipProvider>
      <Tooltip delayDuration={300}>
        <TooltipTrigger asChild>
          <span className="cursor-help transition-all duration-300 decoration-dotted decoration-primary underline-offset-4 hover:decoration-solid">
            {children}
          </span>
        </TooltipTrigger>
        <TooltipContent className="max-w-xs bg-card/95 backdrop-blur-xl border-primary/20 shadow-2xl p-4 rounded-2xl animate-in fade-in zoom-in-95">
          <div className="flex gap-3">
            <Sparkles className="h-4 w-4 text-primary shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="text-[10px] font-black uppercase tracking-widest text-primary italic">Beacon Agent Intel</p>
              <p className="text-xs leading-relaxed text-foreground font-medium">{content}</p>
            </div>
          </div>
        </TooltipContent>
      </Tooltip>
    </TooltipProvider>
  );
}
