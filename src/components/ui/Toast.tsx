import * as React from "react";
import { createPortal } from "react-dom";
import { X } from "lucide-react";
import { cn } from "../../lib/utils";
import {
  ToastContext,
  type ToastContextValue,
  type ToastOptions,
  type ToastVariant,
} from "./toast-context";

export type { ToastOptions, ToastVariant } from "./toast-context";

interface ToastRecord extends Required<Pick<ToastOptions, "id" | "variant">> {
  title?: string;
  description?: string;
  durationMs: number;
  action?: ToastOptions["action"];
}

let nextSyntheticId = 0;
function makeId(): string {
  nextSyntheticId += 1;
  return `toast-${Date.now().toString(36)}-${nextSyntheticId}`;
}

const VARIANT_CLASSES: Record<ToastVariant, string> = {
  info: "border-info/40 bg-info/10 text-info-foreground",
  success: "border-success/40 bg-success/10 text-success-foreground",
  warning: "border-warning/40 bg-warning/10 text-warning-foreground",
  error: "border-destructive/40 bg-destructive/10 text-destructive-foreground",
};

const VARIANT_ROLE: Record<ToastVariant, "status" | "alert"> = {
  info: "status",
  success: "status",
  warning: "alert",
  error: "alert",
};

function ToastItem({
  toast,
  onDismiss,
}: {
  toast: ToastRecord;
  onDismiss: (id: string) => void;
}) {
  React.useEffect(() => {
    if (toast.durationMs <= 0) return;
    const t = window.setTimeout(() => onDismiss(toast.id), toast.durationMs);
    return () => window.clearTimeout(t);
  }, [toast.id, toast.durationMs, onDismiss]);

  return (
    <div
      role={VARIANT_ROLE[toast.variant]}
      aria-live={toast.variant === "error" || toast.variant === "warning" ? "assertive" : "polite"}
      className={cn(
        "pointer-events-auto w-full max-w-sm overflow-hidden rounded-2xl border shadow-lg backdrop-blur-md",
        "animate-in slide-in-from-bottom-4 fade-in duration-200",
        VARIANT_CLASSES[toast.variant],
      )}
    >
      <div className="flex items-start gap-3 p-4">
        <div className="flex-1 space-y-1">
          {toast.title && <div className="font-semibold leading-none">{toast.title}</div>}
          {toast.description && <div className="text-sm opacity-90">{toast.description}</div>}
          {toast.action && (
            <button
              type="button"
              onClick={() => {
                toast.action!.onClick();
                onDismiss(toast.id);
              }}
              className="mt-2 inline-flex h-8 items-center rounded-md border border-current/30 bg-background/40 px-3 text-xs font-medium hover:bg-background/60 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            >
              {toast.action.label}
            </button>
          )}
        </div>
        <button
          type="button"
          aria-label="Dismiss notification"
          onClick={() => onDismiss(toast.id)}
          className="rounded-full p-1 opacity-70 transition hover:opacity-100 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
        >
          <X className="h-4 w-4" aria-hidden="true" />
        </button>
      </div>
    </div>
  );
}

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = React.useState<ToastRecord[]>([]);

  const dismiss = React.useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  const toast = React.useCallback((opts: ToastOptions) => {
    const id = opts.id ?? makeId();
    const record: ToastRecord = {
      id,
      variant: opts.variant ?? "info",
      title: opts.title,
      description: opts.description,
      durationMs: opts.durationMs ?? 6000,
      action: opts.action,
    };
    setToasts((prev) => {
      const filtered = prev.filter((t) => t.id !== id);
      return [...filtered, record];
    });
    return id;
  }, []);

  const ctx = React.useMemo<ToastContextValue>(() => ({ toast, dismiss }), [toast, dismiss]);

  return (
    <ToastContext.Provider value={ctx}>
      {children}
      <ToastViewport toasts={toasts} onDismiss={dismiss} />
    </ToastContext.Provider>
  );
}

function ToastViewport({
  toasts,
  onDismiss,
}: {
  toasts: ToastRecord[];
  onDismiss: (id: string) => void;
}) {
  if (typeof document === "undefined") return null;
  return createPortal(
    <div
      className="pointer-events-none fixed inset-x-0 bottom-0 z-[300] flex flex-col items-center gap-2 px-4 pb-[calc(env(safe-area-inset-bottom)+1rem)] sm:items-end sm:pr-6"
      aria-label="Notifications"
    >
      {toasts.map((t) => (
        <ToastItem key={t.id} toast={t} onDismiss={onDismiss} />
      ))}
    </div>,
    document.body,
  );
}
