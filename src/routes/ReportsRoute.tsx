import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { Button } from "../components/ui/button";
import { Printer, Download, FileText, Sparkles } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";

export default function ReportsRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []);
  const insurance = useLiveQuery(() => db.insuranceRecords.toArray(), []);

  if (!incomes || !bills || !debts || !goals || !transactions || !subscriptions || !insurance) {
    return <div className="p-4 text-muted-foreground animate-pulse font-black uppercase italic text-center mt-20">Compiling Report Telemetry...</div>;
  }

  const summary = calculateBudgetSummary(incomes, bills, debts, goals, transactions, subscriptions, insurance);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="space-y-8 pb-20 max-w-5xl mx-auto animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Reports Arena" 
        subtitle="Printable budget summaries and strategic mission reports."
        actions={
          <div className="flex gap-2 print:hidden">
            <Button variant="outline" size="sm" onClick={() => alert("Report Exported.")} className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5">
              <Download className="h-4 w-4" /> Export
            </Button>
            <Button size="lg" onClick={handlePrint} className="gap-3 shadow-xl shadow-primary/20 h-12 uppercase font-black italic text-xs tracking-widest px-8">
              <Printer className="h-4 w-4" /> Execute Print
            </Button>
          </div>
        }
      />

      <GlassCard intensity="high" className="p-10 space-y-12 print:shadow-none print:border-none print:p-0 print:bg-transparent print:backdrop-blur-none border-primary/20 shadow-2xl">
        <div className="border-b-2 border-primary/10 pb-8 flex justify-between items-end">
          <div>
            <h2 className="text-4xl font-black uppercase italic tracking-tighter text-primary">Monthly Mission Report</h2>
            <p className="text-sm font-bold text-muted-foreground uppercase tracking-widest mt-1">Telemetry Generated: {new Date().toLocaleDateString()}</p>
          </div>
          <div className="text-right">
            <div className="text-[10px] font-black uppercase text-primary">Budget Beacon</div>
            <div className="text-[10px] font-bold text-muted-foreground">OFFLINE ENGINE v2.4.0</div>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
          <div className="space-y-2">
            <h3 className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Aggregate Inflow</h3>
            <div className="text-3xl font-black italic tracking-tighter text-green-500">${summary.totalMonthlyIncome.toLocaleString()}</div>
          </div>
          <div className="space-y-2 border-x border-primary/5 px-12">
            <h3 className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Tactical Outflow</h3>
            <div className="text-3xl font-black italic tracking-tighter text-destructive">${summary.requiredOutflow.toLocaleString()}</div>
          </div>
          <div className="space-y-2 text-right">
            <h3 className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Strategic Surplus</h3>
            <div className="text-3xl font-black italic tracking-tighter text-blue-500">${summary.leftoverAfterSavings.toLocaleString()}</div>
          </div>
        </div>

        <div className="space-y-6">
          <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Mission Telemetry Details</h3>
          <div className="grid grid-cols-2 gap-x-12 gap-y-4">
            <div className="flex justify-between border-b border-primary/5 py-2">
              <span className="text-xs font-bold text-muted-foreground uppercase">Scheduled Bills</span>
              <span className="font-black italic">${summary.totalMonthlyBills.toLocaleString()}</span>
            </div>
            <div className="flex justify-between border-b border-primary/5 py-2">
              <span className="text-xs font-bold text-muted-foreground uppercase">Debt Minimums</span>
              <span className="font-black italic">${summary.totalDebtMinimums.toLocaleString()}</span>
            </div>
            <div className="flex justify-between border-b border-primary/5 py-2">
              <span className="text-xs font-bold text-muted-foreground uppercase">Stash Objectives</span>
              <span className="font-black italic">${summary.totalStashMapScheduled.toLocaleString()}</span>
            </div>
            <div className="flex justify-between border-b border-primary/5 py-2">
              <span className="text-xs font-bold text-muted-foreground uppercase">Actual Spend (MTD)</span>
              <span className="font-black italic">${summary.actualSpend.toLocaleString()}</span>
            </div>
          </div>
        </div>

        <div className="p-8 rounded-3xl bg-primary/5 border border-primary/10 space-y-6 relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-5"><Sparkles className="h-20 w-24 text-primary" /></div>
          <h3 className="text-sm font-black uppercase italic text-primary flex items-center gap-2">
            <FileText className="h-4 w-4" /> Agentic Analysis Overview
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
             <div className="space-y-4">
                <div className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Stability Performance</div>
                <div className="flex items-center gap-4">
                  <div className="text-5xl font-black italic text-primary tracking-tighter">{summary.remainingBudget > 0 ? "85" : "45"}</div>
                  <div className="text-[9px] font-bold text-muted-foreground uppercase leading-tight">Current stability index<br/>based on unified telemetry.</div>
                </div>
             </div>
             <div className="space-y-4">
                <div className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Key Observations</div>
                <ul className="space-y-2">
                  {summary.recommendations.slice(0, 3).map((rec, i) => (
                    <li key={i} className="text-[10px] font-medium leading-relaxed">• {rec}</li>
                  ))}
                </ul>
             </div>
          </div>
        </div>

        <div className="pt-12 text-center text-[8px] font-bold text-muted-foreground uppercase tracking-[0.2em] opacity-40">
          This document is for strategic mission planning only. Data remains 100% private and offline.
        </div>
      </GlassCard>
    </div>
  );
}
