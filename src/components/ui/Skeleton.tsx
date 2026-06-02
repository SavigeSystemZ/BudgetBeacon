import * as React from "react";
import { cn } from "../../lib/utils";

/**
 * Base shimmer block. Sized by the caller via className. Always renders an
 * `aria-hidden` placeholder + an off-screen polite live region so screen
 * readers hear "Loading…" without seeing the visual shimmer.
 */
export function Skeleton({
  className,
  ...rest
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        "animate-pulse rounded-md bg-muted/60",
        className,
      )}
      {...rest}
    />
  );
}

export function ScreenReaderLoading({ label = "Loading" }: { label?: string }) {
  return (
    <span role="status" aria-live="polite" className="sr-only">
      {label}
    </span>
  );
}

/** Drop-in placeholder for a card whose content is loading from Dexie. */
export function CardSkeleton({
  rows = 3,
  className,
}: {
  rows?: number;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "rounded-3xl border border-primary/10 bg-card/60 p-6 space-y-4",
        className,
      )}
    >
      <Skeleton className="h-5 w-1/3" />
      <Skeleton className="h-3 w-2/3" />
      <div className="space-y-2 pt-2">
        {Array.from({ length: rows }).map((_, i) => (
          <Skeleton key={i} className="h-4 w-full" />
        ))}
      </div>
      <ScreenReaderLoading />
    </div>
  );
}

/** Drop-in placeholder for a single row of a transactions / bills / etc. table. */
export function TableRowSkeleton({ columns = 4 }: { columns?: number }) {
  return (
    <div className="flex items-center gap-3 px-3 py-2 border-b border-border/40">
      {Array.from({ length: columns }).map((_, i) => (
        <Skeleton
          key={i}
          className={cn(
            "h-4",
            i === 0 ? "w-1/4" : i === columns - 1 ? "w-1/6" : "flex-1",
          )}
        />
      ))}
    </div>
  );
}

/** Drop-in placeholder for a metric/stat card (label + value + sub). */
export function MetricSkeleton() {
  return (
    <div className="rounded-2xl border border-primary/10 bg-card/60 p-4 space-y-2">
      <Skeleton className="h-3 w-1/2" />
      <Skeleton className="h-7 w-3/4" />
      <Skeleton className="h-3 w-1/3" />
      <ScreenReaderLoading />
    </div>
  );
}

/**
 * Full-page first-load placeholder for a standard route: a PageHeader-shaped
 * header (title + subtitle + action chip), an optional metric row, and a
 * responsive grid of cards. Mirrors the common route chrome so there is no
 * layout shift between the loading state and the ready state. The whole block
 * is a single `role="status"` region so screen readers announce one "Loading…"
 * instead of N shimmer blocks.
 */
export function RouteSkeleton({
  cards = 6,
  metrics = 0,
  rows = 3,
  label = "Loading",
}: {
  cards?: number;
  metrics?: number;
  rows?: number;
  label?: string;
}) {
  return (
    <div
      role="status"
      aria-label={label}
      className="space-y-8 pb-20 animate-in fade-in duration-300"
    >
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="space-y-2">
          <Skeleton className="h-8 w-56 max-w-[60vw]" />
          <Skeleton className="h-3 w-72 max-w-[80vw]" />
        </div>
        <Skeleton className="h-12 w-44 max-w-[45vw] rounded-2xl" />
      </div>

      {metrics > 0 && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: metrics }).map((_, i) => (
            <MetricSkeleton key={i} />
          ))}
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {Array.from({ length: cards }).map((_, i) => (
          <CardSkeleton key={i} rows={rows} />
        ))}
      </div>

      <ScreenReaderLoading label={label} />
    </div>
  );
}
