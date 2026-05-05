import React, { useEffect, useId, useRef } from "react";
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

const FOCUSABLE_SELECTOR =
  'a[href], button:not([disabled]), textarea:not([disabled]), input:not([disabled]), select:not([disabled]), [tabindex]:not([tabindex="-1"])';

export function BeaconModal({
  isOpen,
  onClose,
  title,
  children,
  footer,
  maxWidth = "max-w-2xl",
}: BeaconModalProps) {
  const containerRef = useRef<HTMLDivElement | null>(null);
  const previouslyFocusedRef = useRef<HTMLElement | null>(null);
  const headingId = useId();

  // Capture the previously focused element + lock body scroll for the lifetime
  // of the modal. Restored on unmount or close.
  useEffect(() => {
    if (!isOpen) return;
    previouslyFocusedRef.current = (document.activeElement as HTMLElement) ?? null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    // Focus the first focusable inside the dialog (or the dialog itself).
    const root = containerRef.current;
    if (root) {
      const focusables = root.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR);
      const target = focusables.length > 0 ? focusables[0] : root;
      // Defer to next frame so child portals settle before we focus.
      requestAnimationFrame(() => target.focus());
    }

    return () => {
      document.body.style.overflow = previousOverflow;
      // Return focus to whatever opened the modal, when still in the DOM.
      const prev = previouslyFocusedRef.current;
      if (prev && document.contains(prev)) {
        try {
          prev.focus();
        } catch {
          /* ignore */
        }
      }
    };
  }, [isOpen]);

  // Escape-to-close + Tab focus trap.
  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        e.stopPropagation();
        onClose();
        return;
      }
      if (e.key !== "Tab") return;
      const root = containerRef.current;
      if (!root) return;
      const focusables = Array.from(root.querySelectorAll<HTMLElement>(FOCUSABLE_SELECTOR)).filter(
        (el) => !el.hasAttribute("disabled") && el.offsetParent !== null,
      );
      if (focusables.length === 0) {
        e.preventDefault();
        root.focus();
        return;
      }
      const first = focusables[0];
      const last = focusables[focusables.length - 1];
      const active = document.activeElement as HTMLElement | null;
      if (e.shiftKey && active === first) {
        e.preventDefault();
        last.focus();
      } else if (!e.shiftKey && active === last) {
        e.preventDefault();
        first.focus();
      }
    };
    window.addEventListener("keydown", onKey, true);
    return () => window.removeEventListener("keydown", onKey, true);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-[200] flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-background/80 backdrop-blur-sm"
        data-beacon-modal-backdrop=""
        aria-hidden="true"
        onClick={onClose}
      />
      <div
        ref={containerRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={headingId}
        tabIndex={-1}
        className={cn(
          "relative flex w-full flex-col overflow-hidden rounded-3xl border border-primary/20 bg-card/95 shadow-2xl outline-none backdrop-blur-3xl animate-in zoom-in-95 duration-300",
          "max-h-[90dvh]",
          maxWidth,
        )}
      >
        <div className="flex items-center justify-between border-b border-primary/10 bg-primary/5 px-4 py-4 sm:px-6 sm:py-5">
          <h2
            id={headingId}
            className="text-lg sm:text-xl font-black uppercase italic tracking-tighter text-primary"
          >
            {title}
          </h2>
          <Button
            variant="ghost"
            size="icon"
            aria-label="Close dialog"
            onClick={onClose}
            className="rounded-full hover:bg-destructive/10 hover:text-destructive"
          >
            <X className="h-5 w-5" aria-hidden="true" />
          </Button>
        </div>
        <div className="flex-1 overflow-y-auto px-4 py-4 sm:px-6 sm:py-6">{children}</div>
        {footer && (
          <div className="flex items-center justify-end gap-3 border-t border-primary/10 bg-primary/5 px-4 py-3 sm:px-6 sm:py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
