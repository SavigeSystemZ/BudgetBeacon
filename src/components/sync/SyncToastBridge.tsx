import { useEffect, useRef } from "react";
import { syncService, type SyncStatus } from "../../modules/sync/syncService";
import { useToast } from "../ui/useToast";

/**
 * Watches `syncService.onStatusChange` and surfaces user-visible toasts on
 * meaningful transitions. The status badge already shows the current state
 * inline; this bridge adds the "you should know now" interrupt-level signal.
 *
 * Mount once near the App root, inside <ToastProvider>.
 */
export function SyncToastBridge() {
  const { toast } = useToast();
  const lastRef = useRef<SyncStatus>(syncService.getStatus());

  useEffect(() => {
    const unsubscribe = syncService.onStatusChange((next) => {
      const prev = lastRef.current;
      lastRef.current = next;

      if (next === prev) return;

      if (next === "error") {
        toast({
          id: "sync-error",
          variant: "error",
          title: "Sync error",
          description:
            "Couldn't reach the relay. Local data is safe — we'll keep retrying when the connection is restored.",
          durationMs: 8000,
          action: {
            label: "Retry now",
            onClick: () => {
              try {
                syncService.disconnect();
              } catch {
                /* ignore */
              }
            },
          },
        });
        return;
      }

      if (prev === "error" && next === "connected") {
        toast({
          id: "sync-error",
          variant: "success",
          title: "Sync restored",
          description: "Reconnected to the relay; pending changes are catching up.",
          durationMs: 4000,
        });
        return;
      }

      if (prev === "connecting" && next === "connected") {
        toast({
          id: "sync-connected",
          variant: "success",
          title: "Sync connected",
          description: "Encrypted relay is live.",
          durationMs: 3000,
        });
      }
    });
    return unsubscribe;
  }, [toast]);

  return null;
}
