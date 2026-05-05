import { useState, useMemo } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { transactionSchema, type Transaction } from "../modules/ledger/ledger.schema";
import type { z } from "zod";
import { CardHeader, CardTitle, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import {
  Edit2, Trash2, Plus, Upload,
  History, ArrowDownCircle, ArrowUpCircle, Database
} from "lucide-react";
import { cn } from "../lib/utils";
import { formatLedgerAmountDisplay, rollupCategoryTotals } from "../modules/ledger/transactionDisplay";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";
import { DemoBadge } from "../components/ui/DemoBadge";
import { featureFlags } from "../lib/flags/featureFlags";
import { LedgerImportFlow } from "../components/import/LedgerImportFlow";
import { CardSkeleton, TableRowSkeleton } from "../components/ui/Skeleton";
import { useDeleteConfirm } from "../context/DeleteConfirmContext";

const formSchema = transactionSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type LedgerFormValues = z.infer<typeof formSchema>;

export default function LedgerRoute() {
  const confirmDelete = useDeleteConfirm();
  const transactions = useLiveQuery(() => db.transactions.orderBy("date").reverse().toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { payee: "", amount: 0, date: new Date().toISOString().split("T")[0], category: "food", type: "expense" as const },
  });

  const onSubmit = async (data: LedgerFormValues) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    if (editingId) {
      await db.transactions.update(editingId, { ...data, updatedAt: now });
      setEditingId(null);
    } else {
      await db.transactions.add({ ...data, id: createId(), householdId, createdAt: now, updatedAt: now });
    }
    form.reset();
    setIsModalOpen(false);
  };

  const handleEdit = (t: Transaction) => {
    setEditingId(t.id);
    form.reset({ payee: t.payee, amount: t.amount, date: t.date, category: t.category, type: t.type });
    setIsModalOpen(true);
  };

  const monthPrefix = new Date().toISOString().slice(0, 7);
  const topSpendCategories = useMemo(() => {
    if (!transactions) return [];
    const rollup = rollupCategoryTotals(transactions, { type: "expense", monthPrefix });
    return Object.entries(rollup)
      .map(([category, v]) => ({ category, total: v.total, count: v.count }))
      .sort((a, b) => b.total - a.total)
      .slice(0, 3);
  }, [transactions, monthPrefix]);

  if (!transactions) {
    return (
      <div
        className="space-y-6 pb-20 px-4 md:px-0"
        role="status"
        aria-label="Opening Ledger"
      >
        <CardSkeleton rows={1} />
        <div className="rounded-3xl border border-primary/10 bg-card/60 overflow-hidden">
          <TableRowSkeleton />
          <TableRowSkeleton />
          <TableRowSkeleton />
          <TableRowSkeleton />
          <TableRowSkeleton />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Ledger Loops"
        subtitle="Tactical daily outflow and revenue tracking."
        actions={
          <div className="flex gap-2">
            {featureFlags.bankImportTierA && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => setIsImportOpen(true)}
                className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5"
              >
                <Upload className="h-3 w-3" /> Import CSV
              </Button>
            )}
            <Button
              size="icon"
              aria-label="Add ledger transaction"
              onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }}
              className="rounded-full shadow-lg shadow-primary/20 h-10 w-10"
            >
              <Plus className="h-5 w-5" />
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="lg:col-span-3 space-y-6">
          {transactions.length === 0 ? (
            <EmptyState 
              icon={History}
              title="No Loops Recorded"
              description="Start logging your daily spending. Bank import (CSV / QFX / OFX) lands in M5; for now, log loops manually."
              action={<Button onClick={() => setIsModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Log Manual Loop</Button>}
            />
          ) : (
            <div className="space-y-2">
               {transactions.map((t) => {
                const shown = formatLedgerAmountDisplay(t.amount, t.type);
                return (
                <GlassCard hoverable key={t.id} className="group border-primary/5 bg-primary/5">
                  <CardContent className="p-4 flex justify-between items-center">
                    <div className="flex items-center gap-4">
                      {t.type === "expense" ? (
                        <div className="h-10 w-10 rounded-2xl bg-destructive/10 flex items-center justify-center text-destructive border border-destructive/20 shadow-inner"><ArrowDownCircle className="h-5 w-5" /></div>
                      ) : (
                        <div className="h-10 w-10 rounded-2xl bg-success/10 flex items-center justify-center text-success border border-success/20 shadow-inner"><ArrowUpCircle className="h-5 w-5" /></div>
                      )}
                      <div>
                        <div className="font-black italic text-sm truncate max-w-[200px] uppercase tracking-tighter">{t.payee}</div>
                        <div className="text-[9px] uppercase font-black text-muted-foreground opacity-50 tracking-widest">{t.date}</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-6">
                      <div className={cn("text-xl font-black italic tracking-tighter", t.type === "expense" ? "text-foreground" : "text-success")}>
                        {shown.sign}
                        {shown.currencyBody}
                      </div>
                      <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                        <Button variant="ghost" size="icon" aria-label={`Edit transaction ${t.payee}`} onClick={() => handleEdit(t)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-3.5 w-3.5" /></Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          aria-label={`Delete transaction ${t.payee}`}
                          onClick={() => {
                            void (async () => {
                              if (!(await confirmDelete("transaction", `${t.payee} (${t.date})`))) return;
                              await db.transactions.delete(t.id);
                            })();
                          }}
                          className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"
                        ><Trash2 className="h-3.5 w-3.5" /></Button>
                      </div>
                    </div>
                  </CardContent>
                </GlassCard>
                );
              })}
            </div>
          )}
        </div>

        <div className="space-y-6">
          {featureFlags.bankImportTierA ? (
            <GlassCard className="border-primary/20 bg-primary/5">
              <CardHeader className="pb-3 flex flex-row items-center gap-2">
                <Upload className="h-4 w-4 text-primary" />
                <CardTitle className="text-[10px] font-black uppercase tracking-widest">CSV Import</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <p className="text-[10px] text-muted-foreground leading-relaxed">
                  Export a CSV from your bank or credit card statement, then click <strong className="text-foreground">Import CSV</strong> above. You map columns once, dedupe is automatic, and you can deselect rows in the review step before they land in your ledger.
                </p>
                <p className="text-[10px] text-muted-foreground leading-relaxed">
                  QFX / OFX support and an optional aggregator (Plaid / MX) are deferred to later milestones — see <code className="text-[10px]">docs/INTEGRATIONS_STRATEGY.md</code>.
                </p>
              </CardContent>
            </GlassCard>
          ) : (
            <GlassCard className="border-warning/20 bg-warning/5">
              <CardHeader className="pb-3 flex flex-row items-center gap-2">
                <Database className="h-4 w-4 text-warning" />
                <CardTitle className="text-[10px] font-black uppercase tracking-widest">Bank Import</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <DemoBadge milestone="M5">CSV file import + dedupe + review queue.</DemoBadge>
              </CardContent>
            </GlassCard>
          )}

          <GlassCard className="border-primary/15 bg-card/40">
            <CardHeader className="pb-2 flex flex-row items-center gap-2">
              <ArrowDownCircle className="h-4 w-4 text-destructive" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Top spend ({monthPrefix})</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-[10px]">
              {topSpendCategories.length === 0 ? (
                <p className="text-muted-foreground leading-relaxed">
                  No expense loops this calendar month yet. Categories here match Reports and Mission Control rollups.
                </p>
              ) : (
                <ul className="space-y-2.5">
                  {topSpendCategories.map((row, i) => (
                    <li key={row.category} className="flex justify-between gap-2 border-b border-primary/5 pb-2 last:border-0 last:pb-0">
                      <span className="min-w-0 truncate font-bold uppercase tracking-tight text-foreground">
                        {i + 1}. {row.category}
                      </span>
                      <span className="shrink-0 font-black text-destructive">${row.total.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
                    </li>
                  ))}
                </ul>
              )}
            </CardContent>
          </GlassCard>

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader className="pb-3 flex flex-row items-center gap-2">
              <History className="h-4 w-4 text-primary" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Why log loops?</CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] text-muted-foreground leading-relaxed">
              Ledger Loops feed Dashboard Cockpit and Mission Control. Consistent logging is what makes the Stability Index meaningful.
            </CardContent>
          </GlassCard>
        </div>
      </div>

      <LedgerImportFlow isOpen={isImportOpen} onClose={() => setIsImportOpen(false)} householdId={householdId} />

      <BeaconModal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setEditingId(null); }} title={editingId ? "Edit Loop" : "Log Manual Loop"}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 col-span-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Entity / Payee</Label>
              <Input {...form.register("payee")} placeholder="e.g. Starbucks" className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Loop Value</Label>
              <Input type="number" step="0.01" {...form.register("amount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Timestamp</Label>
              <Input type="date" {...form.register("date")} className="bg-primary/5 border-none font-bold h-12" />
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 h-12 uppercase font-black italic tracking-widest border-primary/20">Cancel</Button>
            <Button type="submit" className="flex-[2] h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">
              {editingId ? "Update telemetry" : "Commit to Ledger"}
            </Button>
          </div>
        </form>
      </BeaconModal>
    </div>
  );
}
