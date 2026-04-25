import { useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { transactionSchema } from "../modules/ledger/ledger.schema";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { 
  Edit2, Trash2, RefreshCw, Link, FileSearch, CheckCircle2, Plus, 
  History, ArrowDownCircle, ArrowUpCircle 
} from "lucide-react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";

const formSchema = transactionSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });

export default function LedgerRoute() {
  const transactions = useLiveQuery(() => db.transactions.orderBy("date").reverse().toArray(), []);
  const documents = useLiveQuery(() => db.documents.filter(d => d.category === "bank-statement").toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isSyncing, setIsSyncing] = useState(false);
  const [isScavenging, setIsScavenging] = useState(false);
  const [scavengedItems, setScavengedItems] = useState<any[] | null>(null);

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { payee: "", amount: 0, date: new Date().toISOString().split("T")[0], category: "food", type: "expense" as const },
  });

  const onSubmit = async (data: any) => {
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

  const handleSyncBank = () => {
    setIsSyncing(true);
    setTimeout(() => {
      const apiResults = [
        { payee: "Starbucks Coffee", amount: 5.45, date: "2026-04-23", category: "food", type: "expense" },
        { payee: "Amazon.com", amount: 42.99, date: "2026-04-22", category: "shopping", type: "expense" }
      ];
      setScavengedItems(apiResults);
      setIsSyncing(false);
    }, 2500);
  };

  const handleScavengeStatements = () => {
    if (documents?.length === 0) {
      alert("No bank statements found in The Vault.");
      return;
    }
    setIsScavenging(true);
    setTimeout(() => {
      const docResults = [
        { payee: "Rent Payment", amount: 1200.00, date: "2026-04-01", category: "housing", type: "expense" },
        { payee: "Work Bonus", amount: 500.00, date: "2026-04-10", category: "income", type: "income" }
      ];
      setScavengedItems(docResults);
      setIsScavenging(false);
    }, 3000);
  };

  const applyItems = async () => {
    if (!scavengedItems || !householdId) return;
    const now = new Date().toISOString();
    for (const item of scavengedItems) {
      await db.transactions.add({ ...item, id: createId(), householdId, createdAt: now, updatedAt: now });
    }
    setScavengedItems(null);
    alert("Ledger auto-populated.");
  };

  const handleEdit = (t: any) => {
    setEditingId(t.id);
    form.reset({ payee: t.payee, amount: t.amount, date: t.date, category: t.category, type: t.type });
    setIsModalOpen(true);
  };

  if (!transactions) return <div className="p-4 text-muted-foreground animate-pulse font-black uppercase italic">Opening Ledger...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Ledger Loops" 
        subtitle="Tactical daily outflow and revenue tracking."
        actions={
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={handleScavengeStatements} disabled={isScavenging} className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5">
              {isScavenging ? <RefreshCw className="h-3 w-3 animate-spin" /> : <FileSearch className="h-3 w-3" />}
              Scavenge
            </Button>
            <Button variant="outline" size="sm" onClick={handleSyncBank} disabled={isSyncing} className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5">
              {isSyncing ? <RefreshCw className="h-3 w-3 animate-spin" /> : <Link className="h-3 w-3" />}
              Bank Sync
            </Button>
            <Button size="icon" onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
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
              description="Start logging your daily spending or use Bank Sync to auto-populate your ledger telemetry."
              action={<Button onClick={() => setIsModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Log Manual Loop</Button>}
            />
          ) : (
            <div className="space-y-2">
               {transactions.map((t) => (
                <GlassCard hoverable key={t.id} className="group border-primary/5 bg-primary/5">
                  <CardContent className="p-4 flex justify-between items-center">
                    <div className="flex items-center gap-4">
                      {t.type === "expense" ? (
                        <div className="h-10 w-10 rounded-2xl bg-destructive/10 flex items-center justify-center text-destructive border border-destructive/20 shadow-inner"><ArrowDownCircle className="h-5 w-5" /></div>
                      ) : (
                        <div className="h-10 w-10 rounded-2xl bg-green-500/10 flex items-center justify-center text-green-500 border border-green-500/20 shadow-inner"><ArrowUpCircle className="h-5 w-5" /></div>
                      )}
                      <div>
                        <div className="font-black italic text-sm truncate max-w-[200px] uppercase tracking-tighter">{t.payee}</div>
                        <div className="text-[9px] uppercase font-black text-muted-foreground opacity-50 tracking-widest">{t.date}</div>
                      </div>
                    </div>
                    <div className="flex items-center gap-6">
                      <div className={cn("text-xl font-black italic tracking-tighter", t.type === "expense" ? "text-foreground" : "text-green-500")}>
                        {t.type === "expense" ? "-" : "+"}${t.amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                      </div>
                      <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                        <Button variant="ghost" size="icon" onClick={() => handleEdit(t)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-3.5 w-3.5" /></Button>
                        <Button variant="ghost" size="icon" onClick={() => db.transactions.delete(t.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-3.5 w-3.5" /></Button>
                      </div>
                    </div>
                  </CardContent>
                </GlassCard>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-6">
          {scavengedItems && (
            <GlassCard className="border-primary/30 bg-primary/5 shadow-2xl animate-in zoom-in-95">
              <CardHeader className="bg-primary/10 pb-3">
                <CardTitle className="text-xs uppercase italic font-black text-primary">Ingestion Queue</CardTitle>
                <CardDescription className="text-[8px] font-bold uppercase tracking-widest">Verify Telemetry</CardDescription>
              </CardHeader>
              <CardContent className="pt-4 space-y-4">
                <div className="space-y-2">
                  {scavengedItems.map((item, i) => (
                    <div key={i} className="flex justify-between items-center p-2 rounded-xl bg-background/40 border border-primary/10">
                      <div>
                        <div className="font-bold text-[10px] truncate max-w-[100px] uppercase italic">{item.payee}</div>
                        <div className="text-[7px] uppercase font-black text-muted-foreground opacity-50">{item.date}</div>
                      </div>
                      <div className={cn("font-black text-[10px] italic", item.type === "income" ? "text-green-500" : "")}>
                        {item.type === "expense" ? "-" : "+"}${item.amount.toFixed(2)}
                      </div>
                    </div>
                  ))}
                </div>
                <div className="flex flex-col gap-2 pt-2 border-t border-primary/10">
                  <Button size="sm" className="w-full h-10 uppercase font-black italic text-[10px] tracking-widest shadow-xl shadow-primary/20" onClick={applyItems}>
                    <CheckCircle2 className="h-3.5 w-3.5 mr-2" /> Commit All
                  </Button>
                  <Button variant="ghost" size="sm" className="w-full text-[9px] font-black uppercase tracking-widest opacity-50" onClick={() => setScavengedItems(null)}>Discard Telemetry</Button>
                </div>
              </CardContent>
            </GlassCard>
          )}

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader className="pb-3 flex flex-row items-center gap-2">
              <RefreshCw className="h-4 w-4 text-primary" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Auto-Reconcile</CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] text-muted-foreground leading-relaxed">
              Ledger Loops are the fuel for Dashboard Cockpit. Consistent logging unlocks deep agentic intel and strategic mission planning.
            </CardContent>
          </GlassCard>
        </div>
      </div>

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
