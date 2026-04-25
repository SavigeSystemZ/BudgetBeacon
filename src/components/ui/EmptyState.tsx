import React from "react";
import type { LucideIcon } from "lucide-react";
import { cn } from "../../lib/utils";

interface EmptyStateProps {
  icon: LucideIcon;
  title: string;
  description: string;
  action?: React.ReactNode;
  className?: string;
}

export function EmptyState({ icon: Icon, title, description, action, className }: EmptyStateProps) {
  return (
    <div className={cn(
      "h-full min-h-[300px] flex flex-col items-center justify-center rounded-3xl border-2 border-dashed border-primary/10 bg-primary/5 p-12 text-center",
      className
    )}>
      <Icon className="h-12 w-12 text-muted-foreground mb-4 opacity-20" />
      <h3 className="text-lg font-bold uppercase italic tracking-tighter">{title}</h3>
      <p className="text-sm text-muted-foreground max-w-xs mx-auto mb-6">{description}</p>
      {action}
    </div>
  );
}
