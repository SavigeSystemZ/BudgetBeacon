import { useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { calculateBudgetSummary } from "../modules/budget-engine/calculateBudgetSummary";
import { calculateStabilityIndex } from "../modules/budget-engine/stabilityIndex";
import { exportDatabaseToJson } from "../modules/reports/exportJson";
import { downloadCsvForEntity, type CsvEntity } from "../modules/reports/exportCsv";
import { Button } from "../components/ui/button";
import { Printer, FileText, Sparkles, Download, Database, ShieldAlert, PiggyBank, FolderLock, Library, ChevronDown } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { cn } from "../lib/utils";

type ReportTab = "monthly" | "debt" | "savings" | "subscriptions" | "documents";

const TABS: { id: ReportTab; label: string; icon: typeof Printer }[] = [
  { id: "monthly", label: "Monthly", icon: FileText },
  { id: "debt", label: "Debts", icon: ShieldAlert },
  { id: "savings", label: "Savings", icon: PiggyBank },
  { id: "subscriptions", label: "Subscriptions", icon: Library },
  { id: "documents", label: "Documents", icon: FolderLock },
];

const CSV_OPTIONS: { entity: CsvEntity; label: string }[] = [
  { entity: "transactions", label: "Transactions" },
  { entity: "bills", label: "Bills" },
  { entity: "debts", label: "Debts" },
  { entity: "savingsGoals", label: "Savings Goals" },
  { entity: "subscriptions", label: "Subscriptions" },
  { entity: "insurance", label: "Insurance Policies" },
  { entity: "creditSnapshots", label: "Credit Snapshots" },
];

export default function ReportsRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const transactions = useLiveQuery(() => db.transactions.toArray(), []);
  const subscriptions = useLiveQuery(() => db.subscriptions.toArray(), []);
  const insurance = useLiveQuery(() => db.insuranceRecords.toArray(), []);
  const documents = useLiveQuery(() => db.documents.toArray(), []);

  const [activeTab, setActiveTab] = useState<ReportTab>("monthly");
  const [exportOpen, setExportOpen] = useState(false);
  const [exportStatus, setExportStatus] = useState<string | null>(null);

  if (!incomes || !bills || !debts || !goals || !transactions || !subscriptions || !insurance || !documents) {
    return <div className="p-4 text-muted-foreground animate-pulse font-black uppercase italic text-center mt-20">Compiling Report Telemetry...</div>;
  }

  const summary = calculateBudgetSummary(incomes, bills, debts, goals, transactions, subscriptions, insurance);
  const stability = calculateStabilityIndex(summary);

  const handlePrint = () => window.print();

  const handleCsvExport = async (entity: CsvEntity) => {
    setExportOpen(false);
    setExportStatus(null);
    try {
      const { filename, rowCount } = await downloadCsvForEntity(entity);
      setExportStatus(`✓ Exported ${rowCount} row${rowCount === 1 ? "" : "s"} to ${filename}`);
      window.setTimeout(() => setExportStatus(null), 4000);
    } catch (err) {
      console.error(err);
      setExportStatus("✕ Export failed. See console.");
    }
  };

  const handleJsonExport = async () => {
    setExportOpen(false);
    setExportStatus(null);
    try {
      await exportDatabaseToJson();
      setExportStatus("✓ Full backup downloaded.");
      window.setTimeout(() => setExportStatus(null), 4000);
    } catch (err) {
      console.error(err);
      setExportStatus("✕ Export failed. See console.");
    }
  };

  return (
    <div className="space-y-8 pb-20 max-w-5xl mx-auto animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Reports Arena"
        subtitle="Budget summaries, per-entity CSVs, and printable views."
        actions={
          <div className="flex items-center gap-3 print:hidden">
            <div className="relative">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setExportOpen((v) => !v)}
                className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5"
                aria-haspopup="menu"
                aria-expanded={exportOpen}
              >
                <Download className="h-4 w-4" /> Export <ChevronDown className="h-3 w-3" />
              </Button>
              {exportOpen && (
                <div role="menu" className="absolute right-0 mt-2 w-64 z-30 rounded-2xl border border-primary/20 bg-card shadow-2xl backdrop-blur-xl overflow-hidden">
                  <button
                    onClick={handleJsonExport}
                    role="menuitem"
                    className="w-full text-left px-4 py-3 flex items-center gap-2 hover:bg-primary/10 text-sm font-bold border-b border-primary/10"
                  >
                    <Database className="h-4 w-4 text-primary" /> Full backup (JSON, v3)
                  </button>
                  <div className="px-4 py-2 text-[9px] font-black uppercase tracking-widest text-muted-foreground">CSV per entity</div>
                  {CSV_OPTIONS.map((o) => (
                    <button
                      key={o.entity}
                      onClick={() => handleCsvExport(o.entity)}
                      role="menuitem"
                      className="w-full text-left px-4 py-2 flex items-center gap-2 hover:bg-primary/10 text-sm"
                    >
                      <FileText className="h-3.5 w-3.5 text-muted-foreground" /> {o.label}
                    </button>
                  ))}
                </div>
              )}
            </div>
            <Button size="lg" onClick={handlePrint} className="gap-3 shadow-xl shadow-primary/20 h-12 uppercase font-black italic text-xs tracking-widest px-8">
              <Printer className="h-4 w-4" /> Execute Print
            </Button>
          </div>
        }
      />

      {exportStatus && (
        <div role="status" className="print:hidden text-xs font-bold text-primary px-2">{exportStatus}</div>
      )}

      {/* Tab strip */}
      <div role="tablist" className="flex gap-2 print:hidden overflow-x-auto pb-1">
        {TABS.map((t) => (
          <button
            key={t.id}
            role="tab"
            aria-selected={activeTab === t.id}
            onClick={() => setActiveTab(t.id)}
            className={cn(
              "flex items-center gap-2 px-4 h-10 rounded-full text-[11px] font-black uppercase italic tracking-widest border whitespace-nowrap transition-all",
              activeTab === t.id
                ? "bg-primary text-primary-foreground border-primary shadow-lg shadow-primary/20"
                : "bg-primary/5 border-primary/20 text-muted-foreground hover:text-primary"
            )}
          >
            <t.icon className="h-4 w-4" /> {t.label}
          </button>
        ))}
      </div>

      <GlassCard intensity="high" className="p-10 space-y-12 print:shadow-none print:border-none print:p-0 print:bg-transparent print:backdrop-blur-none border-primary/20 shadow-2xl">
        <div className="border-b-2 border-primary/10 pb-8 flex justify-between items-end">
          <div>
            <h2 className="text-4xl font-black uppercase italic tracking-tighter text-primary">
              {TABS.find((t) => t.id === activeTab)?.label} Report
            </h2>
            <p className="text-sm font-bold text-muted-foreground uppercase tracking-widest mt-1">Generated: {new Date().toLocaleDateString()}</p>
          </div>
          <div className="text-right">
            <div className="text-[10px] font-black uppercase text-primary">Budget Beacon</div>
            <div className="text-[10px] font-bold text-muted-foreground">OFFLINE ENGINE</div>
          </div>
        </div>

        {activeTab === "monthly" && <MonthlyReport summary={summary} stability={stability} />}
        {activeTab === "debt" && <DebtReport debts={debts} />}
        {activeTab === "savings" && <SavingsReport goals={goals} />}
        {activeTab === "subscriptions" && <SubscriptionsReport subscriptions={subscriptions} />}
        {activeTab === "documents" && <DocumentsReport documents={documents} />}

        <div className="pt-12 text-center text-[8px] font-bold text-muted-foreground uppercase tracking-[0.2em] opacity-40">
          This document is for household budget planning. Data remains 100% private and offline.
        </div>
      </GlassCard>
    </div>
  );
}

function MonthlyReport({ summary, stability }: { summary: ReturnType<typeof calculateBudgetSummary>; stability: number }) {
  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
        <Stat label="Aggregate Inflow" value={summary.totalMonthlyIncome} color="text-green-500" />
        <Stat label="Tactical Outflow" value={summary.requiredOutflow} color="text-destructive" border />
        <Stat label="Strategic Surplus" value={summary.leftoverAfterSavings} color="text-blue-500" align="right" />
      </div>
      <div className="space-y-6">
        <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Mission Telemetry Details</h3>
        <div className="grid grid-cols-2 gap-x-12 gap-y-4">
          <Row label="Scheduled Bills" value={summary.totalMonthlyBills} />
          <Row label="Debt Minimums" value={summary.totalDebtMinimums} />
          <Row label="Stash Objectives" value={summary.totalStashMapScheduled} />
          <Row label="Actual Spend (MTD)" value={summary.actualSpend} />
        </div>
      </div>
      <div className="p-8 rounded-3xl bg-primary/5 border border-primary/10 space-y-6 relative overflow-hidden">
        <div className="absolute top-0 right-0 p-4 opacity-5"><Sparkles className="h-20 w-24 text-primary" /></div>
        <h3 className="text-sm font-black uppercase italic text-primary flex items-center gap-2">
          <FileText className="h-4 w-4" /> Analysis Overview
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="space-y-4">
            <div className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Stability Index</div>
            <div className="flex items-center gap-4">
              <div className="text-5xl font-black italic text-primary tracking-tighter">{stability}</div>
              <div className="text-[9px] font-bold text-muted-foreground uppercase leading-tight">0–100 score from margin,<br/>savings rate, pay-path pressure.</div>
            </div>
          </div>
          <div className="space-y-4">
            <div className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">Key Observations</div>
            {summary.recommendations.length === 0 ? (
              <p className="text-[10px] font-medium opacity-60">No recommendations — household telemetry is balanced.</p>
            ) : (
              <ul className="space-y-2">
                {summary.recommendations.slice(0, 5).map((rec, i) => (
                  <li key={i} className="text-[10px] font-medium leading-relaxed">• {rec}</li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>
    </>
  );
}

function DebtReport({ debts }: { debts: { id: string; label: string; balance: number; minimumPayment: number; category: string }[] }) {
  const totalBalance = debts.reduce((s, d) => s + d.balance, 0);
  const totalMinimum = debts.reduce((s, d) => s + d.minimumPayment, 0);
  const sorted = debts.slice().sort((a, b) => b.balance - a.balance);

  if (debts.length === 0) {
    return <p className="text-sm text-muted-foreground py-8">No debts tracked. Add liabilities in Debt Center to see them here.</p>;
  }

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
        <Stat label="Total Liability" value={totalBalance} color="text-destructive" />
        <Stat label="Total Monthly Minimum" value={totalMinimum} color="text-destructive" border />
        <Stat label="Active Liabilities" value={debts.length} color="text-foreground" align="right" plain />
      </div>
      <div className="space-y-3">
        <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Liabilities (largest first — Avalanche order)</h3>
        <div className="space-y-2">
          {sorted.map((d) => (
            <div key={d.id} className="flex justify-between items-center p-4 rounded-2xl bg-primary/5 border border-primary/10">
              <div>
                <div className="font-black italic uppercase tracking-tight text-sm">{d.label}</div>
                <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60">{d.category}</div>
              </div>
              <div className="flex gap-8 text-right">
                <div>
                  <div className="text-[9px] uppercase font-black opacity-50">Balance</div>
                  <div className="font-black italic">${d.balance.toLocaleString()}</div>
                </div>
                <div>
                  <div className="text-[9px] uppercase font-black opacity-50">Minimum/mo</div>
                  <div className="font-black italic">${d.minimumPayment.toLocaleString()}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </>
  );
}

function SavingsReport({ goals }: { goals: { id: string; label: string; targetAmount: number; currentAmount: number; monthlyContribution: number; category: string }[] }) {
  const totalTarget = goals.reduce((s, g) => s + g.targetAmount, 0);
  const totalCurrent = goals.reduce((s, g) => s + g.currentAmount, 0);
  const totalMonthly = goals.reduce((s, g) => s + g.monthlyContribution, 0);

  if (goals.length === 0) {
    return <p className="text-sm text-muted-foreground py-8">No goals set. Add a savings goal in Stash Map to see progress here.</p>;
  }

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
        <Stat label="Total Target" value={totalTarget} color="text-blue-500" />
        <Stat label="Currently Saved" value={totalCurrent} color="text-green-500" border />
        <Stat label="Monthly Allocation" value={totalMonthly} color="text-foreground" align="right" />
      </div>
      <div className="space-y-3">
        <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Goals</h3>
        {goals.map((g) => {
          const pct = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) * 100 : 0;
          const eta = g.monthlyContribution > 0 ? Math.ceil((g.targetAmount - g.currentAmount) / g.monthlyContribution) : null;
          return (
            <div key={g.id} className="p-4 rounded-2xl bg-primary/5 border border-primary/10 space-y-2">
              <div className="flex justify-between items-center">
                <div>
                  <div className="font-black italic uppercase tracking-tight text-sm">{g.label}</div>
                  <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60">{g.category}</div>
                </div>
                <div className="text-2xl font-black italic tracking-tighter text-primary">{pct.toFixed(0)}%</div>
              </div>
              <div className="h-2 bg-primary/10 rounded-full overflow-hidden">
                <div className="h-full bg-primary transition-all" style={{ width: `${Math.min(pct, 100)}%` }} />
              </div>
              <div className="flex justify-between text-[9px] font-bold text-muted-foreground uppercase">
                <span>${g.currentAmount.toLocaleString()} / ${g.targetAmount.toLocaleString()}</span>
                <span>{eta !== null ? `~${eta} mo @ $${g.monthlyContribution}/mo` : "no monthly contribution"}</span>
              </div>
            </div>
          );
        })}
      </div>
    </>
  );
}

function SubscriptionsReport({ subscriptions }: { subscriptions: { id: string; label: string; amount: number; frequency: string; category: string }[] }) {
  const monthlyEquiv = (s: { amount: number; frequency: string }) => {
    if (s.frequency === "annual") return s.amount / 12;
    if (s.frequency === "quarterly") return s.amount / 3;
    return s.amount;
  };
  const totalMonthly = subscriptions.reduce((sum, s) => sum + monthlyEquiv(s), 0);

  if (subscriptions.length === 0) {
    return <p className="text-sm text-muted-foreground py-8">No subscriptions tracked.</p>;
  }

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
        <Stat label="Active Subscriptions" value={subscriptions.length} color="text-foreground" plain />
        <Stat label="Monthly Equivalent" value={totalMonthly} color="text-destructive" border />
        <Stat label="Annual Cost" value={totalMonthly * 12} color="text-destructive" align="right" />
      </div>
      <div className="space-y-3">
        <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Subscriptions (largest monthly first)</h3>
        {subscriptions.slice().sort((a, b) => monthlyEquiv(b) - monthlyEquiv(a)).map((s) => (
          <div key={s.id} className="flex justify-between items-center p-4 rounded-2xl bg-primary/5 border border-primary/10">
            <div>
              <div className="font-black italic uppercase tracking-tight text-sm">{s.label}</div>
              <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60">{s.category} · {s.frequency}</div>
            </div>
            <div className="text-right">
              <div className="text-[9px] uppercase font-black opacity-50">Monthly equiv.</div>
              <div className="font-black italic">${monthlyEquiv(s).toFixed(2)}</div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

function DocumentsReport({ documents }: { documents: { id: string; label: string; category: string; fileName: string; fileSize: number; createdAt: string }[] }) {
  const totalSize = documents.reduce((s, d) => s + d.fileSize, 0);
  const byCategory = documents.reduce<Record<string, number>>((acc, d) => {
    acc[d.category] = (acc[d.category] || 0) + 1;
    return acc;
  }, {});

  if (documents.length === 0) {
    return <p className="text-sm text-muted-foreground py-8">No documents in The Vault.</p>;
  }

  return (
    <>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-12">
        <Stat label="Documents Stored" value={documents.length} color="text-foreground" plain />
        <Stat label="Total Size" value={`${(totalSize / 1024).toFixed(1)} KB`} color="text-foreground" border plain />
        <Stat label="Categories" value={Object.keys(byCategory).length} color="text-foreground" align="right" plain />
      </div>
      <div className="space-y-3">
        <h3 className="text-sm font-black uppercase italic border-b border-primary/5 pb-2 text-primary">Inventory</h3>
        {documents.slice().sort((a, b) => b.createdAt.localeCompare(a.createdAt)).map((d) => (
          <div key={d.id} className="flex justify-between items-center p-4 rounded-2xl bg-primary/5 border border-primary/10">
            <div>
              <div className="font-black italic uppercase tracking-tight text-sm">{d.label}</div>
              <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60">{d.category} · {d.fileName}</div>
            </div>
            <div className="text-right text-[10px] font-bold text-muted-foreground">
              <div>{(d.fileSize / 1024).toFixed(1)} KB</div>
              <div>{d.createdAt.split("T")[0]}</div>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

function Stat({ label, value, color, border, align = "left", plain = false }: {
  label: string;
  value: number | string;
  color: string;
  border?: boolean;
  align?: "left" | "right";
  plain?: boolean;
}) {
  const display = typeof value === "number" && !plain ? `$${value.toLocaleString()}` : String(value);
  return (
    <div className={cn("space-y-2", border && "border-x border-primary/5 px-12", align === "right" && "text-right")}>
      <h3 className="text-[10px] font-black uppercase tracking-widest text-muted-foreground">{label}</h3>
      <div className={cn("text-3xl font-black italic tracking-tighter", color)}>{display}</div>
    </div>
  );
}

function Row({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex justify-between border-b border-primary/5 py-2">
      <span className="text-xs font-bold text-muted-foreground uppercase">{label}</span>
      <span className="font-black italic">${value.toLocaleString()}</span>
    </div>
  );
}
