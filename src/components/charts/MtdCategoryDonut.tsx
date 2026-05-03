import { useMemo } from "react";
import { Cell, Legend, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import type { Transaction } from "../../modules/ledger/ledger.schema";
import { buildExpenseCategoryRollup } from "../../modules/ledger/transactionDisplay";

const CHART_COLORS = [
  "var(--color-chart-1)",
  "var(--color-chart-2)",
  "var(--color-chart-3)",
  "var(--color-chart-4)",
];

interface MtdSlice {
  name: string;
  value: number;
  color: string;
}

export interface MtdCategoryDonutProps {
  transactions: readonly Transaction[];
  /** Defaults to current UTC `YYYY-MM` (matches budget MTD filtering). */
  monthPrefix?: string;
}

/**
 * Donut of month-to-date expense totals by category (ledger), same rollup as Reports / Mission Control.
 */
export function MtdCategoryDonut({ transactions, monthPrefix }: MtdCategoryDonutProps) {
  const month = monthPrefix ?? new Date().toISOString().slice(0, 7);
  const { rows, monthTotal } = useMemo(
    () => buildExpenseCategoryRollup(transactions, month, 10),
    [transactions, month],
  );

  const data: MtdSlice[] = useMemo(
    () => rows.map((r, i) => ({ name: r.category, value: r.total, color: CHART_COLORS[i % CHART_COLORS.length] })),
    [rows],
  );

  if (monthTotal <= 0) {
    return (
      <div className="flex h-56 flex-col items-center justify-center gap-2 px-4 text-center text-muted-foreground">
        <p className="text-[10px] font-black uppercase tracking-widest">No MTD expense categories</p>
        <p className="max-w-sm text-xs font-medium leading-relaxed opacity-80">
          Log expense loops for {month} to see how spend spreads across categories.
        </p>
      </div>
    );
  }

  return (
    <div className="h-56 w-full md:h-64">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={48}
            outerRadius={76}
            paddingAngle={4}
            dataKey="value"
            animationBegin={0}
            animationDuration={900}
          >
            {data.map((entry) => (
              <Cell
                key={`cell-${entry.name}`}
                fill={entry.color}
                stroke="rgba(255,255,255,0.08)"
                strokeWidth={1}
                className="cursor-pointer transition-opacity hover:opacity-90"
              />
            ))}
          </Pie>
          <Tooltip
            content={({ active, payload }) => {
              if (!active || !payload?.length) return null;
              const slice = payload[0].payload as MtdSlice;
              const num = slice.value;
              const pct = monthTotal > 0 ? ((num / monthTotal) * 100).toFixed(1) : "0.0";
              return (
                <div
                  className="rounded-2xl border border-white/10 px-3 py-2 text-[11px] text-white shadow-xl"
                  style={{
                    background: "rgba(0,0,0,0.82)",
                    backdropFilter: "blur(12px)",
                  }}
                >
                  <div className="font-bold uppercase tracking-wide">{slice.name}</div>
                  <div className="mt-1 font-mono text-[10px] opacity-90">
                    ${num.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })} ({pct}% of MTD)
                  </div>
                </div>
              );
            }}
          />
          <Legend
            verticalAlign="bottom"
            height={28}
            formatter={(value) => <span className="text-[10px] font-bold uppercase tracking-wide">{value}</span>}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
