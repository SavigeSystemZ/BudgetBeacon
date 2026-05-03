import { useMemo } from "react";
import { PieChart } from "lucide-react";
import type { Transaction } from "../../modules/ledger/ledger.schema";
import { buildExpenseCategoryRollup } from "../../modules/ledger/transactionDisplay";
import { Progress } from "../ui/progress";
import { cn } from "../../lib/utils";

export interface ExpenseCategoryRollupProps {
  transactions: readonly Transaction[];
  /** `YYYY-MM`, same convention as budget summary MTD filtering */
  monthPrefix?: string;
  maxCategories?: number;
  /** Tighter typography for dashboard surfaces */
  density?: "comfortable" | "compact";
  className?: string;
}

function defaultMonthPrefix(): string {
  return new Date().toISOString().slice(0, 7);
}

/**
 * Printable-friendly category spend for the active month (expenses only).
 */
export function ExpenseCategoryRollup({
  transactions,
  monthPrefix = defaultMonthPrefix(),
  maxCategories = 12,
  density = "comfortable",
  className,
}: ExpenseCategoryRollupProps) {
  const { rows, monthTotal } = useMemo(
    () => buildExpenseCategoryRollup(transactions, monthPrefix, maxCategories),
    [transactions, monthPrefix, maxCategories]
  );

  const compact = density === "compact";
  const maxRow = rows.length ? Math.max(...rows.map((r) => r.total), 1) : 1;

  if (monthTotal <= 0) {
    return (
      <div
        className={cn(
          "rounded-3xl border border-dashed border-primary/15 bg-primary/5 px-6 py-8 text-center",
          className
        )}
      >
        <p className={cn("font-bold text-muted-foreground", compact ? "text-[10px] uppercase tracking-widest" : "text-xs")}>
          No expense loops this month — category pressure will appear as you log ledger outflows.
        </p>
      </div>
    );
  }

  return (
    <div className={cn("space-y-4", className)}>
      <div className="flex items-center justify-between gap-4 border-b border-primary/10 pb-3">
        <h3
          className={cn(
            "flex items-center gap-2 font-black uppercase italic text-primary",
            compact ? "text-xs" : "text-sm"
          )}
        >
          <PieChart className={compact ? "h-3.5 w-3.5" : "h-4 w-4"} />
          MTD spend by category
        </h3>
        <span
          className={cn(
            "shrink-0 font-black text-muted-foreground",
            compact ? "text-[9px] uppercase tracking-widest" : "text-[10px] uppercase tracking-widest"
          )}
        >
          {monthPrefix} · ${monthTotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
        </span>
      </div>
      <div className={cn("space-y-3", compact && "space-y-2.5")}>
        {rows.map((row) => (
          <div key={row.category} className="space-y-1.5">
            <div className="flex justify-between gap-3 text-[10px] font-bold uppercase tracking-tight">
              <span className="min-w-0 truncate text-foreground">{row.category}</span>
              <span className="shrink-0 text-muted-foreground">
                ${row.total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
                <span className="ml-1.5 text-[9px] opacity-60">({row.count})</span>
              </span>
            </div>
            <Progress value={(row.total / maxRow) * 100} className={cn("h-1.5 bg-primary/10", compact && "h-1")} />
          </div>
        ))}
      </div>
      <p className={cn("text-[9px] font-bold uppercase tracking-widest text-muted-foreground opacity-70")}>
        Bars are relative to the largest category this month, not % of income.
      </p>
    </div>
  );
}
