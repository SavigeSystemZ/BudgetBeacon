import React from "react";
import { X } from "lucide-react";
import { Button } from "./button";
import { cn } from "../../lib/utils";

interface BeaconModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  maxWidth?: string;
}

export function BeaconModal({ isOpen, onClose, title, children, footer, maxWidth = "max-w-2xl" }: BeaconModalProps) {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-background/80 backdrop-blur-sm" onClick={onClose} />
      <div className={cn(
        "relative w-full overflow-hidden rounded-3xl border border-primary/20 bg-card/95 backdrop-blur-3xl shadow-2xl animate-in zoom-in-95 duration-300",
        maxWidth
      )}>
        <div className="flex items-center justify-between border-b border-primary/10 bg-primary/5 p-6">
          <h2 className="text-xl font-black uppercase italic tracking-tighter text-primary">{title}</h2>
          <Button variant="ghost" size="icon" onClick={onClose} className="rounded-full hover:bg-destructive/10 hover:text-destructive">
            <X className="h-5 w-5" />
          </Button>
        </div>
        <div className="p-6 overflow-y-auto max-h-[80vh]">
          {children}
        </div>
        {footer && (
          <div className="flex items-center justify-end gap-3 border-t border-primary/10 bg-primary/5 p-6">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
