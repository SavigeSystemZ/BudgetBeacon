import { useEffect, useState } from "react";
import { syncService, type SyncStatus } from "../../modules/sync/syncService";
import { Wifi, WifiOff, Loader2, ShieldCheck, AlertTriangle } from "lucide-react";
import { cn } from "../../lib/utils";

const LABELS: Record<SyncStatus, string> = {
  "local-only": "Local-only",
  "connecting": "Connecting…",
  "connected": "Synced",
  "disconnected": "Offline",
  "error": "Sync error",
};

export function SyncStatusBadge({ compact = false, className }: { compact?: boolean; className?: string }) {
  const [status, setStatus] = useState<SyncStatus>(() => syncService.getStatus());

  useEffect(() => syncService.onStatusChange(setStatus), []);

  const Icon =
    status === "connected" ? Wifi
    : status === "connecting" ? Loader2
    : status === "local-only" ? ShieldCheck
    : status === "error" ? AlertTriangle
    : WifiOff;

  const tone =
    status === "connected" ? "text-success"
    : status === "connecting" ? "text-warning"
    : status === "error" ? "text-destructive"
    : status === "disconnected" ? "text-muted-foreground"
    : "text-primary";

  return (
    <span
      role="status"
      aria-label={`Sync status: ${LABELS[status]}`}
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full border border-white/10 bg-card/40 px-2.5 py-1 text-[9px] font-black uppercase tracking-widest backdrop-blur",
        tone,
        className,
      )}
    >
      <Icon className={cn("h-3 w-3", status === "connecting" && "animate-spin")} aria-hidden />
      {!compact && <span>{LABELS[status]}</span>}
    </span>
  );
}
