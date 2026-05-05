import * as React from "react";
import { ToastContext, type ToastContextValue } from "./toast-context";

/**
 * Subscribes to the nearest <ToastProvider>. Returns a no-op fallback in prod
 * if used outside the provider; throws in dev so the wiring bug surfaces.
 */
export function useToast(): ToastContextValue {
  const ctx = React.useContext(ToastContext);
  if (!ctx) {
    if (
      typeof window !== "undefined" &&
      (import.meta as ImportMeta & { env?: { DEV?: boolean } }).env?.DEV
    ) {
      throw new Error("useToast() called outside <ToastProvider>");
    }
    return {
      toast: () => "",
      dismiss: () => {},
    };
  }
  return ctx;
}
