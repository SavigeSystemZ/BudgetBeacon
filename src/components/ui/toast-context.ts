import * as React from "react";

export type ToastVariant = "info" | "success" | "warning" | "error";

export interface ToastOptions {
  id?: string;
  title?: string;
  description?: string;
  variant?: ToastVariant;
  durationMs?: number;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export type ToastContextValue = {
  toast: (opts: ToastOptions) => string;
  dismiss: (id: string) => void;
};

export const ToastContext = React.createContext<ToastContextValue | null>(null);
