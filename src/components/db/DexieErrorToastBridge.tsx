import { useEffect, useRef } from "react";
import { db } from "../../db/db";
import { useToast } from "../ui/useToast";
import { logger } from "../../lib/logger";

/**
 * Surfaces user-visible toasts on Dexie / IndexedDB failures.
 *
 * Phase 2 ask: useLiveQuery consumers should not silently fail when a Dexie
 * read or write blows up. `useLiveQuery` itself doesn't expose query errors,
 * so this bridge listens at two boundaries:
 *
 *   1. `db.on("versionchange")` — another tab upgraded the schema; reads here
 *      will start failing. We park a sticky warning and recommend reload.
 *   2. `window.unhandledrejection` — Dexie's promise chain bubbles failures up
 *      via unhandled rejection. We filter to errors whose name starts with
 *      "Dexie" or which have a `inner` of that shape, and toast a destructive
 *      banner. Non-Dexie rejections fall through.
 *
 * Mount once near the App root, inside <ToastProvider>.
 */
export function DexieErrorToastBridge() {
  const { toast } = useToast();
  const seenRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    const versionHandler = () => {
      toast({
        id: "dexie-versionchange",
        variant: "warning",
        title: "Database upgraded in another tab",
        description: "Reload this page to use the new schema. Local data is safe.",
        durationMs: 0,
        action: {
          label: "Reload",
          onClick: () => {
            try {
              window.location.reload();
            } catch {
              /* ignore */
            }
          },
        },
      });
    };

    const blockedHandler = () => {
      toast({
        id: "dexie-blocked",
        variant: "warning",
        title: "Database upgrade blocked",
        description: "Close other Budget Beacon tabs so the schema can finish upgrading.",
        durationMs: 0,
      });
    };

    db.on("versionchange", versionHandler);
    db.on("blocked", blockedHandler);

    const isDexieError = (reason: unknown): boolean => {
      if (!reason || typeof reason !== "object") return false;
      const r = reason as { name?: unknown; inner?: { name?: unknown } };
      const nameTop = typeof r.name === "string" ? r.name : "";
      const nameInner = typeof r.inner?.name === "string" ? r.inner.name : "";
      return (
        nameTop.startsWith("Dexie") ||
        nameTop === "QuotaExceededError" ||
        nameTop === "InvalidStateError" ||
        nameInner.startsWith("Dexie")
      );
    };

    const rejectionHandler = (event: PromiseRejectionEvent) => {
      if (!isDexieError(event.reason)) return;
      const r = event.reason as { name?: string; message?: string };
      const key = `${r.name ?? "DexieError"}:${r.message ?? ""}`;
      if (seenRef.current.has(key)) return;
      seenRef.current.add(key);

      logger.error("[Dexie] unhandled rejection:", event.reason);

      const isQuota = r.name === "QuotaExceededError";
      toast({
        id: `dexie-error:${key}`,
        variant: "error",
        title: isQuota ? "Storage full" : "Database error",
        description: isQuota
          ? "Browser storage is full. Free space (clear other site data, or empty the Vault) and retry."
          : `${r.message ?? "An IndexedDB operation failed."} Reloading often clears transient errors.`,
        durationMs: 10000,
        action: {
          label: "Reload",
          onClick: () => {
            try {
              window.location.reload();
            } catch {
              /* ignore */
            }
          },
        },
      });
    };

    if (typeof window !== "undefined") {
      window.addEventListener("unhandledrejection", rejectionHandler);
    }

    return () => {
      try {
        db.on("versionchange").unsubscribe(versionHandler);
        db.on("blocked").unsubscribe(blockedHandler);
      } catch {
        /* Dexie subscription API differs across versions; ignore on cleanup. */
      }
      if (typeof window !== "undefined") {
        window.removeEventListener("unhandledrejection", rejectionHandler);
      }
    };
  }, [toast]);

  return null;
}
