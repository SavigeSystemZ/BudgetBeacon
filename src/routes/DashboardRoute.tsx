import { useMemo, useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { MetricCard } from "../components/cards/MetricCard";
import { AllocationDonut } from "../components/charts/AllocationDonut";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { cn } from "../lib/utils";
import { 
  XAxis, YAxis, CartesianGrid, 
  Tooltip as ChartTooltip, ResponsiveContainer, AreaChart, Area
} from "recharts";
import { format, subDays, eachDayOfInterval, isSameDay, parseISO } from "date-fns";
import { AgenticTooltip } from "../components/AgenticTooltip";
import { Sparkles, TrendingUp, Lightbulb, Zap, Rocket, Shield, Wallet, Flame, MapPinned, PieChart } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { IncomeExpenseBarChart } from "../components/charts/IncomeExpenseBarChart";
import { MtdCategoryDonut } from "../components/charts/MtdCategoryDonut";
import { BudgetHealthScoreCard } from "../components/dashboard/BudgetHealthScoreCard";
import { BeaconModal } from "../components/ui/BeaconModal";
import {
  FULL_WIPE_EXPORT_HINT,
  FULL_WIPE_MODAL_TITLE,
  FULL_WIPE_SCOPE_DESCRIPTION,
  CANNOT_UNDONE_SHORT,
} from "../lib/fullDatabaseWipeCopy";
import { clearDatabase } from "../db/seedDemoData";

export default function DashboardRoute() {
  const [wipeOpen, setWipeOpen] = useState(false);
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []);
  const insurance = useLiveQuery(() => db.insuranceRecords.toArray(), []);

  const summary = useMemo(() => {
    if (!incomes || !bills || !debts || !goals || !transactions || !subscriptions || !insurance) return null;
    return calculateBudgetSummary(incomes, bills, debts, goals, transactions, subscriptions, insurance);
  }, [incomes, bills, debts, goals, transactions, subscriptions, insurance]);

  const dailySpendData = useMemo(() => {
    if (!transactions) return [];
    return eachDayOfInterval({
      start: subDays(new Date(), 30),
      end: new Date()
    }).map(day => {
      const dayTotal = transactions
        .filter(t => t.type === "expense" && isSameDay(parseISO(t.date), day))
        .reduce((acc, t) => acc + t.amount, 0);
      return {
        date: format(day, "MMM d"),
        amount: dayTotal
      };
    });
  }, [transactions]);

  const runWipeReload = async () => {
    setWipeOpen(false);
    await clearDatabase();
    window.location.reload();
  };

  if (!summary) return <div className="flex h-screen items-center justify-center text-primary font-black uppercase italic animate-pulse">Synchronizing Cockpit...</div>;

  const burnBarPct = Math.min(100, summary.payPathPressureRatio * 100);
  const stashBarPct = Math.min(Math.max(0, 100 - burnBarPct), summary.savingsRate * 100);
  const surplusPct = Math.max(0, 100 - summary.payPathPressureRatio * 100 - summary.savingsRate * 100);

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Dashboard Cockpit"
        subtitle="Household telemetry and propulsion status."
        actions={
          <Button
            type="button"
            variant="outline"
            size="sm"
            aria-label="Open confirmation to wipe entire local database"
            onClick={() => setWipeOpen(true)}
            className="text-destructive hover:bg-destructive/10 border-destructive/20 uppercase font-black italic text-[10px] px-4"
          >
            Wipe All
          </Button>
        }
      />

      <BeaconModal
        isOpen={wipeOpen}
        onClose={() => setWipeOpen(false)}
        title={FULL_WIPE_MODAL_TITLE}
        maxWidth="max-w-lg"
        footer={
          <>
            <Button type="button" variant="ghost" className="uppercase font-black italic text-xs tracking-widest" onClick={() => setWipeOpen(false)}>
              Cancel
            </Button>
            <Button
              type="button"
              variant="destructive"
              className="uppercase font-black italic text-xs tracking-widest"
              onClick={() => void runWipeReload()}
            >
              Wipe everything
            </Button>
          </>
        }
      >
        <p className="text-sm text-muted-foreground font-medium leading-relaxed">
          {FULL_WIPE_SCOPE_DESCRIPTION} {FULL_WIPE_EXPORT_HINT}{" "}
          <span className="text-destructive font-bold">{CANNOT_UNDONE_SHORT}</span>
        </p>
      </BeaconModal>
      
      <div className="flex flex-wrap gap-4 items-center">
        <AgenticTooltip content={`Your budget status is ${summary.budgetStatus}. Strategic margin of 20% is recommended.`}>
          <div className={cn(
            "px-6 py-2.5 rounded-full text-xs font-black uppercase italic tracking-widest border flex items-center gap-3 transition-all hover:scale-105 shadow-2xl",
            summary.budgetStatus === "GREEN" && "bg-success/10 text-success border-success/20 shadow-success/10",
            summary.budgetStatus === "YELLOW" && "bg-warning/10 text-warning border-warning/20 shadow-warning/10",
            summary.budgetStatus === "RED" && "bg-destructive/10 text-destructive border-destructive/20 shadow-destructive/10"
          )}>
            <div className={cn(
              "h-3 w-3 rounded-full animate-pulse",
              summary.budgetStatus === "GREEN" && "bg-success",
              summary.budgetStatus === "YELLOW" && "bg-warning",
              summary.budgetStatus === "RED" && "bg-destructive"
            )} />
            {summary.budgetStatus === "GREEN" && "Healthy Margin"}
            {summary.budgetStatus === "YELLOW" && "Propulsion Pressure"}
            {summary.budgetStatus === "RED" && "Deficit Critical"}
          </div>
        </AgenticTooltip>
        
        <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-primary/5 border border-primary/10 text-[10px] font-bold uppercase tracking-widest">
          <Shield className="h-3 w-3 text-primary" />
          Secured Offline Engine
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <MetricCard
          title="Monthly Inflow"
          value={summary.totalMonthlyIncome}
          description="Unified capital stream"
          className="hoverable"
          icon={<Wallet className="h-4 w-4" />}
        />
        <MetricCard
          title="Burn Rate"
          value={summary.requiredOutflow}
          description="Bills, Debts, & Subscriptions"
          className="hoverable"
          icon={<Flame className="h-4 w-4" />}
        />
        <MetricCard
          title="Strategic Plan"
          value={summary.totalStashMapScheduled}
          description="Committed to Stash Map"
          className="hoverable"
          icon={<MapPinned className="h-4 w-4" />}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            <GlassCard intensity="high">
              <CardHeader className="pb-2">
                <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                  <TrendingUp className="h-4 w-4" /> Capital Allocation
                </CardTitle>
              </CardHeader>
              <CardContent>
                <AllocationDonut summary={summary} />
              </CardContent>
            </GlassCard>

            <GlassCard intensity="high">
              <CardHeader className="pb-2">
                <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                  <Rocket className="h-4 w-4" /> Outflow Velocity (30d)
                </CardTitle>
              </CardHeader>
              <CardContent className="h-64">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={dailySpendData}>
                    <defs>
                      <linearGradient id="colorSpend" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="5%" stopColor="hsl(var(--primary))" stopOpacity={0.3}/>
                        <stop offset="95%" stopColor="hsl(var(--primary))" stopOpacity={0}/>
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                    <XAxis dataKey="date" stroke="hsl(var(--muted-foreground))" fontSize={9} axisLine={false} tickLine={false} minTickGap={20} />
                    <YAxis stroke="hsl(var(--muted-foreground))" fontSize={9} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v}`} />
                    <ChartTooltip contentStyle={{ background: "rgba(0,0,0,0.85)", border: "1px solid rgba(255,255,255,0.1)", borderRadius: "16px", color: "#fff", fontSize: "10px" }} />
                    <Area type="monotone" dataKey="amount" stroke="hsl(var(--primary))" strokeWidth={3} fillOpacity={1} fill="url(#colorSpend)" />
                  </AreaChart>
                </ResponsiveContainer>
              </CardContent>
            </GlassCard>

            <IncomeExpenseBarChart transactions={transactions ?? []} months={6} className="md:col-span-2" />

            <GlassCard intensity="high" className="md:col-span-2">
              <CardHeader className="pb-2">
                <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                  <PieChart className="h-4 w-4" /> MTD expense mix (ledger)
                </CardTitle>
              </CardHeader>
              <CardContent>
                <MtdCategoryDonut transactions={transactions ?? []} />
              </CardContent>
            </GlassCard>
          </div>

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader className="pb-3 flex flex-row items-center justify-between">
              <CardTitle className="text-[10px] font-black text-muted-foreground uppercase tracking-widest">Global Pressure Index</CardTitle>
              <AgenticTooltip content="Aggregated household burn rate vs inflow.">
                <div className="text-[10px] font-black uppercase italic text-primary flex items-center gap-1 cursor-help"><Sparkles className="h-3 w-3" /> Agent Note</div>
              </AgenticTooltip>
            </CardHeader>
            <CardContent>
              <div className="w-full h-8 bg-secondary/20 dark:bg-secondary/10 backdrop-blur-3xl rounded-2xl overflow-hidden flex relative border border-white/10 dark:border-white/5 shadow-inner">
                {summary.totalMonthlyIncome > 0 && (
                  <>
                    <div
                      className="h-full bg-destructive transition-all duration-1000 ease-out shadow-[10px_0_25px_rgba(239,68,68,0.5)]"
                      style={{ width: `${burnBarPct}%` }}
                    />
                    <div
                      className="h-full bg-info transition-all duration-1000 ease-out shadow-[10px_0_25px_rgba(59,130,246,0.5)]"
                      style={{ width: `${stashBarPct}%` }}
                    />
                  </>
                )}
              </div>
              {summary.totalMonthlyIncome <= 0 ? (
                <p className="mt-4 text-[11px] font-bold text-muted-foreground uppercase tracking-tight leading-relaxed">
                  No planned monthly inflow — add active income sources to calibrate burn vs stash. Ratios stay at 0 until then.
                </p>
              ) : (
                <div className="flex flex-wrap justify-between mt-6 gap-6">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest opacity-70"><div className="w-2.5 h-2.5 rounded-full bg-destructive" /> Burn Index</div>
                    <div className="text-xl font-black italic tracking-tighter">{(summary.payPathPressureRatio * 100).toFixed(1)}%</div>
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest opacity-70"><div className="w-2.5 h-2.5 rounded-full bg-info" /> Stash Rate</div>
                    <div className="text-xl font-black italic tracking-tighter">{(summary.savingsRate * 100).toFixed(1)}%</div>
                  </div>
                  <div className="space-y-1">
                    <div className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest opacity-70"><div className="w-2.5 h-2.5 rounded-full bg-secondary" /> Propulsion Surplus</div>
                    <div className="text-xl font-black italic tracking-tighter">{surplusPct.toFixed(1)}%</div>
                  </div>
                </div>
              )}
            </CardContent>
          </GlassCard>
        </div>

        <div className="space-y-6">
          <BudgetHealthScoreCard savingsRateFraction={summary.savingsRate} />
          <GlassCard intensity="high" className="border-primary/20 bg-primary/5 shadow-2xl relative overflow-hidden h-full">
            <div className="absolute -top-10 -right-10 opacity-10 rotate-12"><Lightbulb className="h-40 w-40 text-primary" /></div>
            <CardHeader>
              <CardTitle className="flex items-center gap-2 text-primary font-black uppercase italic tracking-tighter"><Sparkles className="h-5 w-5" /> Agentic Intel</CardTitle>
              <CardDescription className="text-[10px] font-bold uppercase tracking-widest opacity-60">Telemetry-Driven Optimization</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 pt-2">
              {summary.recommendations.length === 0 ? (
                <div className="p-8 rounded-3xl border-2 border-dashed border-primary/10 bg-background/20 text-center space-y-4">
                  <Zap className="h-10 w-10 text-muted-foreground mx-auto opacity-20" />
                  <p className="text-xs font-black uppercase text-muted-foreground tracking-tighter leading-tight">Telemetry Locked.<br/>Add Ledger Data to unlock intel.</p>
                </div>
              ) : (
                summary.recommendations.map((rec, i) => (
                  <div key={i} className="group p-4 rounded-2xl bg-background/30 border border-primary/5 hover:border-primary/20 transition-all relative overflow-hidden cursor-help">
                    <div className="absolute inset-0 bg-primary/5 translate-x-[-100%] group-hover:translate-x-0 transition-transform duration-700" />
                    <div className="relative flex gap-4 items-start">
                      <div className="h-6 w-6 rounded-full bg-primary text-primary-foreground flex items-center justify-center text-[10px] font-black shrink-0">{i + 1}</div>
                      <p className="text-xs font-bold leading-relaxed">{rec}</p>
                    </div>
                  </div>
                ))
              )}
              {/* "Execute Deep Audit" button removed in M3 — was a no-op. Real audit lands in M4. */}
            </CardContent>
          </GlassCard>
        </div>
      </div>
    </div>
  );
}
