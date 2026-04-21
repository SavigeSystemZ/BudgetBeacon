import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from "recharts";
import type { BudgetSummary } from "../../modules/budget-engine/budget.types";

interface AllocationDonutProps {
  summary: BudgetSummary;
}

export function AllocationDonut({ summary }: AllocationDonutProps) {
  const { totalMonthlyBills, totalDebtMinimums, totalStashMapScheduled, leftoverAfterSavings } = summary;

  // Don't render empty charts gracefully
  if (summary.totalMonthlyIncome === 0) {
    return <div className="h-64 flex items-center justify-center text-muted-foreground text-sm">No active income to allocate.</div>;
  }

  const data = [
    { name: "Bills", value: totalMonthlyBills, color: "var(--color-chart-1)" },
    { name: "Debt", value: totalDebtMinimums, color: "var(--color-chart-2)" },
    { name: "Savings", value: totalStashMapScheduled, color: "var(--color-chart-3)" },
    { name: "Leftover", value: Math.max(0, leftoverAfterSavings), color: "var(--color-chart-4)" },
  ].filter((d) => d.value > 0);

  return (
    <div className="h-64 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={80}
            paddingAngle={5}
            dataKey="value"
          >
            {data.map((entry, index) => (
              <Cell key={`cell-${index}`} fill={entry.color} />
            ))}
          </Pie>
          <Tooltip 
            formatter={(value: unknown) => {
              if (typeof value === 'number') return [`$${value.toFixed(2)}`, "Amount"];
              return [String(value), "Amount"];
            }}
            contentStyle={{ borderRadius: "8px", border: "1px solid var(--color-border)" }}
          />
          <Legend verticalAlign="bottom" height={36} />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
