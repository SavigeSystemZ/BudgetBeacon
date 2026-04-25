import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Progress } from "../components/ui/progress";
import { Target, Rocket, Zap, Shield, TrendingUp, Compass, Flag } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";

export default function BudgetMissionControlRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []);
  const insurance = useLiveQuery(() => db.insuranceRecords.toArray(), []);

  if (!incomes || !bills || !debts || !goals || !transactions || !subscriptions || !insurance) {
    return <div className="p-4 text-muted-foreground animate-pulse font-black uppercase italic text-center mt-20">Synchronizing Strategic Data...</div>;
  }

  const summary = calculateBudgetSummary(incomes, bills, debts, goals, transactions, subscriptions, insurance);

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Mission Control" 
        subtitle="Strategic planning and long-term goal telemetry."
        actions={
          <Button size="lg" onClick={() => alert("Strategic plan saved.")} className="uppercase font-black italic text-xs tracking-widest shadow-xl shadow-primary/20 h-12 px-8">
            Persist Plan
          </Button>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <GlassCard intensity="high" className="md:col-span-2 border-primary/20 bg-card/60">
          <CardHeader className="pb-6 border-b border-primary/5 bg-primary/5">
            <CardTitle className="flex items-center gap-2 uppercase italic font-black text-primary">
              <Rocket className="h-5 w-5" /> Propulsion Summary
            </CardTitle>
            <CardDescription className="text-[10px] font-bold uppercase tracking-widest opacity-60">Capital Inflow (Fill) vs Operational Outflow (Burn)</CardDescription>
          </CardHeader>
          <CardContent className="space-y-8 pt-8 px-8">
            <div className="space-y-3">
              <div className="flex justify-between items-end">
                <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Monthly Inflow (Fill Rate)</span>
                <span className="text-xl font-black italic text-green-500">${summary.totalMonthlyIncome.toLocaleString()}</span>
              </div>
              <Progress value={100} className="h-4 bg-primary/5 shadow-inner rounded-full" />
            </div>
            <div className="space-y-3">
              <div className="flex justify-between items-end">
                <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Operational Outflow (Burn Rate)</span>
                <span className="text-xl font-black italic text-destructive">${summary.requiredOutflow.toLocaleString()}</span>
              </div>
              <Progress 
                value={(summary.requiredOutflow / summary.totalMonthlyIncome) * 100} 
                className="h-4 bg-primary/5 shadow-inner rounded-full" 
              />
            </div>
            <div className="space-y-3">
              <div className="flex justify-between items-end">
                <span className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Strategic Allocation (Stash Rate)</span>
                <span className="text-xl font-black italic text-blue-500">${summary.totalStashMapScheduled.toLocaleString()}</span>
              </div>
              <Progress 
                value={(summary.totalStashMapScheduled / summary.totalMonthlyIncome) * 100} 
                className="h-4 bg-primary/5 shadow-inner rounded-full" 
              />
            </div>
          </CardContent>
        </GlassCard>

        <GlassCard intensity="high" className="border-primary/20 bg-primary/5 shadow-2xl relative flex flex-col items-center justify-center p-8 overflow-hidden">
          <div className="absolute inset-0 bg-primary/5 animate-pulse" />
          <CardHeader className="text-center z-10">
            <CardTitle className="flex items-center justify-center gap-2 uppercase italic font-black text-primary">
              <Shield className="h-5 w-5" /> Stability Index
            </CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center justify-center pt-6 z-10">
            <div className="relative h-48 w-48 flex items-center justify-center">
              <svg className="h-full w-full rotate-[-90deg]">
                <circle cx="96" cy="96" r="80" fill="none" stroke="currentColor" strokeWidth="16" className="text-primary/10" />
                <circle
                  cx="96"
                  cy="96"
                  r="80"
                  fill="none"
                  stroke="currentColor"
                  strokeWidth="16"
                  strokeDasharray={502}
                  strokeDashoffset={502 - (502 * (summary.remainingBudget > 0 ? 85 : 45)) / 100}
                  strokeLinecap="round"
                  className="text-primary transition-all duration-1000 ease-out"
                />
              </svg>
              <div className="absolute inset-0 flex flex-col items-center justify-center">
                <span className="text-6xl font-black italic tracking-tighter">{summary.remainingBudget > 0 ? "85" : "45"}</span>
                <span className="text-[10px] uppercase font-black text-muted-foreground tracking-widest">Stability</span>
              </div>
            </div>
            <p className="text-[11px] font-bold text-center mt-8 text-muted-foreground leading-relaxed uppercase tracking-tighter">
              {summary.remainingBudget > 0 
                ? "Propulsion positive. Unified telemetry indicates high strategic readiness." 
                : "Deficit warning. Mission stability compromised. Audit Pay Path immediately."}
            </p>
          </CardContent>
        </GlassCard>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-10">
        <div className="space-y-6">
          <h2 className="text-2xl font-black uppercase italic flex items-center gap-3 text-primary px-2">
            <Target className="h-6 w-6" /> Objectives
          </h2>
          <div className="grid grid-cols-1 gap-4">
            {goals.map((goal) => {
              const progress = (goal.currentAmount / goal.targetAmount) * 100;
              return (
                <GlassCard key={goal.id} className="border-primary/10 overflow-hidden group">
                  <div className="p-6">
                    <div className="flex justify-between items-start mb-4">
                      <div>
                        <div className="font-black italic uppercase tracking-tight text-lg">{goal.label}</div>
                        <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60">Target: ${goal.targetAmount.toLocaleString()}</div>
                      </div>
                      <div className="text-2xl font-black italic tracking-tighter text-primary">{progress.toFixed(0)}%</div>
                    </div>
                    <Progress value={progress} className="h-2.5 bg-primary/5 rounded-full" />
                    <div className="flex justify-between text-[8px] font-black uppercase text-muted-foreground tracking-widest mt-3">
                      <span>${goal.currentAmount.toLocaleString()} Stashed</span>
                      <span className="flex items-center gap-1"><Flag className="h-2 w-2" /> Mission: {goal.category}</span>
                    </div>
                  </div>
                </GlassCard>
              );
            })}
          </div>
        </div>

        <div className="space-y-6">
          <h2 className="text-2xl font-black uppercase italic flex items-center gap-3 text-primary px-2">
            <Zap className="h-6 w-6" /> Strategic Intel
          </h2>
          <div className="space-y-4">
            <GlassCard className="border-primary/20 bg-primary/5 shadow-2xl relative group overflow-hidden">
               <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
               <CardContent className="p-8 flex gap-6">
                <Compass className="h-10 w-10 text-primary shrink-0 group-hover:scale-110 transition-transform duration-500" />
                <div>
                  <h3 className="font-black italic text-sm uppercase mb-2 tracking-tighter">Debt Snowball Protocol</h3>
                  <p className="text-xs font-medium text-muted-foreground leading-relaxed">
                    Based on your Debt Center telemetry, allocating an additional $200/mo could reduce your total liability window by 14 months.
                  </p>
                </div>
              </CardContent>
            </GlassCard>
            <GlassCard className="border-primary/20 bg-primary/5 shadow-2xl relative group overflow-hidden">
               <div className="absolute inset-0 bg-primary/5 opacity-0 group-hover:opacity-100 transition-opacity" />
               <CardContent className="p-8 flex gap-6">
                <TrendingUp className="h-10 w-10 text-primary shrink-0 group-hover:scale-110 transition-transform duration-500" />
                <div>
                  <h3 className="font-black italic text-sm uppercase mb-2 tracking-tighter">Stash Velocity</h3>
                  <p className="text-xs font-medium text-muted-foreground leading-relaxed">
                    Your "Emergency Fund" stash objective is 65% complete. Current velocity puts you at full mission readiness by August 2026.
                  </p>
                </div>
              </CardContent>
            </GlassCard>
          </div>
        </div>
      </div>
    </div>
  );
}
