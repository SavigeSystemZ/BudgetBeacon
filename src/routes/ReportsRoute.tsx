import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { Button } from "../components/ui/button";
import { Card } from "../components/ui/card";
import { format } from "date-fns";

export default function ReportsRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);

  if (!incomes || !bills || !debts || !goals || !transactions) {
    return <div className="p-4 text-muted-foreground">Generating report...</div>;
  }

  const summary = calculateBudgetSummary(incomes, bills, debts, goals, transactions);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div className="flex justify-between items-center print:hidden">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Reports</h1>
          <p className="text-muted-foreground">Printable budget summaries.</p>
        </div>
        <Button onClick={handlePrint} variant="outline">Print Monthly Report</Button>
      </div>

      <Card className="p-8 space-y-8 print:shadow-none print:border-none print:p-0 print:bg-transparent print:backdrop-blur-none">
        <div className="border-b pb-4">
          <h2 className="text-2xl font-bold">Monthly Budget Summary</h2>
          <p className="text-muted-foreground">Generated on {format(new Date(summary.generatedAt), "MMMM do, yyyy 'at' h:mm a")}</p>
        </div>

        <div className="grid grid-cols-2 gap-8">
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground mb-4 border-b pb-2">Inflow</h3>
            <div className="space-y-2">
              <div className="flex justify-between font-bold text-lg">
                <span>Total Income</span>
                <span>${summary.totalMonthlyIncome.toFixed(2)}</span>
              </div>
              <ul className="text-sm space-y-1 text-muted-foreground mt-2">
                {incomes.filter(i => i.isActive).map(i => (
                  <li key={i.id} className="flex justify-between">
                    <span>{i.label} ({i.frequency})</span>
                    <span>${i.amount.toFixed(2)}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground mb-4 border-b pb-2">Required Outflow</h3>
            <div className="space-y-2">
              <div className="flex justify-between font-bold text-lg">
                <span>Total Bills & Debt</span>
                <span>${summary.requiredOutflow.toFixed(2)}</span>
              </div>
              <ul className="text-sm space-y-1 text-muted-foreground mt-2">
                {bills.map(b => (
                  <li key={b.id} className="flex justify-between">
                    <span>{b.label} ({b.frequency})</span>
                    <span>${b.amount.toFixed(2)}</span>
                  </li>
                ))}
                {debts.map(d => (
                  <li key={d.id} className="flex justify-between">
                    <span>{d.label} (Min)</span>
                    <span>${d.minimumPayment.toFixed(2)}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-8">
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground mb-4 border-b pb-2">Savings Plan</h3>
            <div className="space-y-2">
              <div className="flex justify-between font-bold text-lg">
                <span>Total Scheduled</span>
                <span>${summary.totalStashMapScheduled.toFixed(2)}</span>
              </div>
              <ul className="text-sm space-y-1 text-muted-foreground mt-2">
                {goals.filter(g => g.monthlyContribution > 0).map(g => (
                  <li key={g.id} className="flex justify-between">
                    <span>{g.label}</span>
                    <span>${g.monthlyContribution.toFixed(2)}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground mb-4 border-b pb-2">Summary</h3>
            <div className="space-y-4">
              <div className="flex justify-between text-base">
                <span className="text-muted-foreground">Leftover (Before Savings):</span>
                <span className="font-semibold">${summary.leftoverAfterRequired.toFixed(2)}</span>
              </div>
              <div className="flex justify-between text-base border-t pt-2">
                <span className="font-bold">Final Leftover Margin:</span>
                <span className={`font-bold ${summary.leftoverAfterSavings < 0 ? 'text-destructive' : 'text-green-600'}`}>
                  ${summary.leftoverAfterSavings.toFixed(2)}
                </span>
              </div>
            </div>
          </div>
        </div>

        {summary.recommendations.length > 0 && (
          <div className="mt-8 border-t pt-6">
            <h3 className="text-sm font-semibold uppercase tracking-wider text-muted-foreground mb-4">Actionable Advice</h3>
            <ul className="list-disc pl-5 space-y-2 text-sm">
              {summary.recommendations.map((rec, i) => (
                <li key={i}>{rec}</li>
              ))}
            </ul>
          </div>
        )}
      </Card>
    </div>
  );
}
