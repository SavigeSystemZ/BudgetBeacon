import { useMemo } from "react";
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { BarChart3 } from "lucide-react";
import type { Transaction } from "../../modules/ledger/ledger.schema";
import { buildMonthlyIncomeExpenseSeries } from "../../modules/ledger/transactionDisplay";
import { CardContent, CardHeader, CardTitle } from "../ui/card";
import { GlassCard } from "../ui/GlassCard";

interface IncomeExpenseBarChartProps {
  transactions: readonly Transaction[];
  /** Number of calendar months to include ending this month */
  months?: number;
  className?: string;
}

export function IncomeExpenseBarChart({ transactions, months = 6, className }: IncomeExpenseBarChartProps) {
  const chartData = useMemo(() => buildMonthlyIncomeExpenseSeries(transactions, months), [transactions, months]);

  return (
    <GlassCard intensity="high" className={className}>
      <CardHeader className="pb-2">
        <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
          <BarChart3 className="h-4 w-4" />
          Income vs Expenses
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} barGap={4}>
              <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.06)" vertical={false} />
              <XAxis
                dataKey="month"
                axisLine={false}
                tickLine={false}
                tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 10 }}
              />
              <YAxis
                axisLine={false}
                tickLine={false}
                tick={{ fill: "hsl(var(--muted-foreground))", fontSize: 10 }}
                tickFormatter={(value: number) => {
                  if (Math.abs(value) >= 1000) return `$${(value / 1000).toFixed(1)}k`;
                  return `$${value}`;
                }}
              />
              <Tooltip
                cursor={{ fill: "hsl(var(--primary) / 0.06)" }}
                content={({ active, payload }) => {
                  if (!active || !payload?.length) return null;
                  const row = payload[0].payload as {
                    fullMonth: string;
                    income: number;
                    expenses: number;
                    net: number;
                  };
                  return (
                    <div className="rounded-2xl border border-white/10 bg-background/95 p-3 text-xs shadow-xl backdrop-blur-md">
                      <p className="mb-2 font-bold text-foreground">{row.fullMonth}</p>
                      <p className="text-success">Income: ${row.income.toLocaleString()}</p>
                      <p className="text-rose-500">Expenses: ${row.expenses.toLocaleString()}</p>
                      <hr className="my-2 border-border" />
                      <p className={row.net >= 0 ? "font-semibold text-primary" : "font-semibold text-destructive"}>
                        Net: ${row.net.toLocaleString()}
                      </p>
                    </div>
                  );
                }}
              />
              <Bar dataKey="income" fill="hsl(142 76% 36%)" radius={[6, 6, 0, 0]} name="Income" />
              <Bar dataKey="expenses" fill="hsl(var(--destructive))" radius={[6, 6, 0, 0]} name="Expenses" />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div className="mt-4 flex flex-wrap items-center justify-center gap-6 text-[10px] font-bold uppercase tracking-widest text-muted-foreground">
          <span className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-full bg-success" />
            Income
          </span>
          <span className="flex items-center gap-2">
            <span className="h-2.5 w-2.5 rounded-full bg-destructive" />
            Expenses
          </span>
        </div>
      </CardContent>
    </GlassCard>
  );
}
