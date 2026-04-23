import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { MetricCard } from "../components/cards/MetricCard";
import { AllocationDonut } from "../components/charts/AllocationDonut";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { cn } from "../lib/utils";

export default function DashboardRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);

  if (!incomes || !bills || !debts || !goals || !transactions) {
    return <div className="p-4 text-muted-foreground">Mapping budget telemetry...</div>;
  }

  const summary = calculateBudgetSummary(incomes, bills, debts, goals, transactions);

  return (
    <div className="space-y-6">
      {/* Header & Status Banner */}
      <div className="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Beacon Dashboard</h1>
          <p className="text-muted-foreground">Your monthly household telemetry.</p>
        </div>
        <div
          className={cn(
            "px-4 py-2 rounded-full text-sm font-bold border flex items-center gap-2",
            summary.budgetStatus === "GREEN" && "bg-green-50 text-green-700 border-green-200 dark:bg-green-950 dark:text-green-300 dark:border-green-900",
            summary.budgetStatus === "YELLOW" && "bg-yellow-50 text-yellow-700 border-yellow-200 dark:bg-yellow-950 dark:text-yellow-300 dark:border-yellow-900",
            summary.budgetStatus === "RED" && "bg-red-50 text-red-700 border-red-200 dark:bg-red-950 dark:text-red-300 dark:border-red-900"
          )}
        >
          <div className={cn(
            "h-2.5 w-2.5 rounded-full",
            summary.budgetStatus === "GREEN" && "bg-green-500",
            summary.budgetStatus === "YELLOW" && "bg-yellow-500",
            summary.budgetStatus === "RED" && "bg-red-500"
          )} />
          {summary.budgetStatus === "GREEN" && "Healthy Margin"}
          {summary.budgetStatus === "YELLOW" && "High Pressure"}
          {summary.budgetStatus === "RED" && "Deficit Warning"}
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3 lg:grid-cols-6">
        <MetricCard
          title="Monthly Income"
          value={summary.totalMonthlyIncome}
          description="Total active inflow"
          className="md:col-span-1 lg:col-span-2"
        />
        <MetricCard
          title="Planned Outflow"
          value={summary.requiredOutflow + summary.totalStashMapScheduled}
          description="Bills, debt, & savings"
          className="md:col-span-1 lg:col-span-2"
        />
        <MetricCard
          title="Planned Margin"
          value={summary.leftoverAfterSavings}
          description="Expected end-of-month surplus"
          className={cn("md:col-span-1 lg:col-span-2", summary.leftoverAfterSavings < 0 ? "border-destructive" : "")}
        />
        <MetricCard
          title="Actual Spend (MTD)"
          value={summary.actualSpend}
          description="Logged transactions this month"
          className="md:col-span-1 lg:col-span-3 border-orange-500/30 dark:border-orange-500/30 bg-orange-500/5 dark:bg-orange-500/10"
        />
        <MetricCard
          title="Remaining Budget"
          value={summary.remainingBudget}
          description="Income - Savings - Actual Spend"
          className={cn("md:col-span-1 lg:col-span-3", summary.remainingBudget < 0 ? "border-destructive bg-destructive/10" : "border-green-500/30 dark:border-green-500/30 bg-green-500/5 dark:bg-green-500/10")}
        />
      </div>

      {/* Charts & Recommendations */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>Income Allocation</CardTitle>
            <CardDescription>How your monthly money is distributed.</CardDescription>
          </CardHeader>
          <CardContent>
            <AllocationDonut summary={summary} />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Beacon Recommendations</CardTitle>
            <CardDescription>Actionable insights based on your cash flow.</CardDescription>
          </CardHeader>
          <CardContent>
            {summary.recommendations.length === 0 ? (
              <p className="text-sm text-muted-foreground py-4">No critical recommendations at this time. Your budget is perfectly balanced.</p>
            ) : (
              <ul className="space-y-3">
                {summary.recommendations.map((rec, i) => (
                  <li key={i} className="flex gap-3 text-sm p-3 rounded-lg bg-muted/50 border">
                    <span className="text-primary mt-0.5">•</span>
                    <span>{rec}</span>
                  </li>
                ))}
              </ul>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Cash Flow Bar */}
      <Card>
        <CardHeader className="pb-3">
          <CardTitle className="text-sm font-medium text-muted-foreground uppercase tracking-wider">Cash Flow Pressure</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="w-full h-4 bg-secondary/30 dark:bg-secondary/10 backdrop-blur-md rounded-full overflow-hidden flex relative border border-white/10 dark:border-white/5">
            {summary.totalMonthlyIncome > 0 && (
              <>
                <div 
                  className="h-full bg-destructive transition-all duration-500" 
                  style={{ width: `${Math.min(100, summary.payPathPressureRatio * 100)}%` }} 
                  title={`Pay Path: ${(summary.payPathPressureRatio * 100).toFixed(1)}%`}
                />
                <div 
                  className="h-full bg-blue-500 transition-all duration-500" 
                  style={{ width: `${Math.min(100 - (summary.payPathPressureRatio * 100), summary.savingsRate * 100)}%` }} 
                  title={`Savings: ${(summary.savingsRate * 100).toFixed(1)}%`}
                />
              </>
            )}
          </div>
          <div className="flex justify-between mt-2 text-xs text-muted-foreground font-medium">
            <span className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-destructive" /> Required Outflow ({(summary.payPathPressureRatio * 100).toFixed(0)}%)</span>
            <span className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-blue-500" /> Scheduled Savings ({(summary.savingsRate * 100).toFixed(0)}%)</span>
            <span className="flex items-center gap-1.5"><div className="w-2 h-2 rounded-full bg-secondary" /> Unallocated ({(Math.max(0, 100 - (summary.payPathPressureRatio * 100) - (summary.savingsRate * 100))).toFixed(0)}%)</span>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
