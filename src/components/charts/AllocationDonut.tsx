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
    <div className="h-72 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={data}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={90}
            paddingAngle={5}
            dataKey="value"
            animationBegin={0}
            animationDuration={1500}
          >
            {data.map((entry, index) => (
              <Cell 
                key={`cell-${index}`} 
                fill={entry.color} 
                stroke="rgba(255,255,255,0.1)" 
                strokeWidth={2}
                className="hover:opacity-80 transition-opacity cursor-pointer"
              />
            ))}
          </Pie>
          <Tooltip 
            formatter={(value: any, name: any) => {
              const numValue = Number(value);
              const percentage = ((numValue / summary.totalMonthlyIncome) * 100).toFixed(1);
              return [`$${numValue.toLocaleString(undefined, {minimumFractionDigits: 2})} (${percentage}%)`, String(name)];
            }}
            contentStyle={{ 
              borderRadius: "16px", 
              border: "1px solid rgba(255,255,255,0.1)",
              background: "rgba(0,0,0,0.8)",
              backdropFilter: "blur(12px)",
              color: "#fff",
              boxShadow: "0 10px 30px rgba(0,0,0,0.5)"
            }}
            itemStyle={{ color: "#fff" }}
          />
          <Legend 
            verticalAlign="bottom" 
            height={36} 
            formatter={(value) => <span className="text-xs font-bold uppercase tracking-wider">{value}</span>}
          />
        </PieChart>
      </ResponsiveContainer>
    </div>
  );
}
