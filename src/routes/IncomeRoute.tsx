import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { incomeSourceSchema } from "../modules/income/income.schema";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { useState, useMemo } from "react";
import { cn } from "../lib/utils";
import { Edit2, Trash2, Plus, Wallet } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";

const formSchema = incomeSourceSchema.omit({ id: true, householdId: true, personId: true, createdAt: true, updatedAt: true });

export default function IncomeRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);
  const defaultPersonId = persons?.[0]?.id || "default-person";

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { label: "", amount: 0, frequency: "monthly", isActive: true },
  });

  const totalMonthlyIncome = useMemo(() => {
    if (!incomes) return 0;
    return incomes.reduce((acc, inc) => {
      if (!inc.isActive) return acc;
      // Simple normalization for the list view
      if (inc.frequency === "annual") return acc + (inc.amount / 12);
      if (inc.frequency === "biweekly") return acc + (inc.amount * 2.16);
      if (inc.frequency === "weekly") return acc + (inc.amount * 4.33);
      return acc + inc.amount;
    }, 0);
  }, [incomes]);

  const onSubmit = async (data: any) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    if (editingId) {
      await db.incomeSources.update(editingId, { ...data, updatedAt: now });
      setEditingId(null);
    } else {
      await db.incomeSources.add({ ...data, id: createId(), householdId, personId: defaultPersonId, createdAt: now, updatedAt: now });
    }
    form.reset();
    setIsModalOpen(false);
  };

  const handleEdit = (inc: any) => {
    setEditingId(inc.id);
    form.reset({ label: inc.label, amount: inc.amount, frequency: inc.frequency, isActive: inc.isActive });
    setIsModalOpen(true);
  };

  if (!incomes) return <div className="p-4 text-muted-foreground animate-pulse">Scanning Capital Streams...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Income Pool" 
        subtitle="Manage household capital inflows and active streams."
        actions={
          <div className="flex items-center gap-4 bg-primary/10 px-6 py-2.5 rounded-2xl border border-primary/20 shadow-2xl">
            <div className="text-right">
              <div className="text-[10px] font-black uppercase text-muted-foreground tracking-widest">Aggregate Inflow</div>
              <div className="text-xl font-black text-primary italic tracking-tighter">${totalMonthlyIncome.toLocaleString(undefined, { maximumFractionDigits: 0 })}/mo</div>
            </div>
            <Button size="icon" onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
              <Plus className="h-5 w-5" />
            </Button>
          </div>
        }
      />

      {incomes.length === 0 ? (
        <EmptyState 
          icon={Wallet}
          title="Income Pool is Empty"
          description="Stock your pool with salary, dividends, or other revenue streams to enable budget telemetry."
          action={<Button onClick={() => setIsModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Add Stream</Button>}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {incomes.map((inc) => (
            <GlassCard hoverable key={inc.id} className={cn("overflow-hidden group", editingId === inc.id && "border-primary ring-1 ring-primary shadow-2xl")}>
              <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
                <div className="flex justify-between items-start">
                  <div>
                    <CardTitle className="text-xl font-black italic tracking-tight">{inc.label}</CardTitle>
                    <CardDescription className="uppercase text-[10px] font-black tracking-widest text-primary opacity-70">{inc.frequency}</CardDescription>
                  </div>
                  <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                    <Button variant="ghost" size="icon" onClick={() => handleEdit(inc)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-4 w-4" /></Button>
                    <Button variant="ghost" size="icon" onClick={() => db.incomeSources.delete(inc.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-4 w-4" /></Button>
                  </div>
                </div>
              </CardHeader>
              <CardContent className="pt-6">
                <div className="text-4xl font-black tracking-tighter italic text-foreground mb-4">
                  ${inc.amount.toLocaleString(undefined, { minimumFractionDigits: 2 })}
                </div>
                <div className="flex items-center justify-between pt-4 border-t border-primary/5">
                  <div className="flex items-center gap-2">
                    <div className="h-5 w-5 rounded-full bg-primary/10 flex items-center justify-center text-[10px] font-black text-primary">{persons?.find(p => p.id === inc.personId)?.name?.[0]}</div>
                    <span className="text-[10px] font-bold uppercase text-muted-foreground tracking-widest">{persons?.find(p => p.id === inc.personId)?.name}</span>
                  </div>
                  <div className={cn("text-[8px] font-black uppercase px-2 py-1 rounded-full border", inc.isActive ? "bg-green-500/10 text-green-500 border-green-500/20" : "bg-muted text-muted-foreground border-transparent")}>
                    {inc.isActive ? "Active Stream" : "Inactive"}
                  </div>
                </div>
              </CardContent>
            </GlassCard>
          ))}
        </div>
      )}

      <BeaconModal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setEditingId(null); }} title={editingId ? "Edit Stream" : "Add Inflow"}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label>
              <Input {...form.register("label")} placeholder="e.g. Salary" className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Amount</Label>
              <Input type="number" step="0.01" {...form.register("amount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12 text-lg" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Frequency</Label>
              <NativeSelect {...form.register("frequency")} className="bg-primary/5 border-none font-bold h-12 uppercase text-[10px]">
                <option value="weekly">Weekly</option>
                <option value="biweekly">Bi-weekly</option>
                <option value="monthly">Monthly</option>
                <option value="annual">Annual</option>
              </NativeSelect>
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Stream Status</Label>
              <NativeSelect {...form.register("isActive")} className="bg-primary/5 border-none font-bold h-12 uppercase text-[10px]">
                <option value="true">Active</option>
                <option value="false">Paused</option>
              </NativeSelect>
            </div>
          </div>
          <div className="flex gap-3 pt-4">
            <Button type="button" variant="outline" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 h-12 uppercase font-black italic tracking-widest">Cancel</Button>
            <Button type="submit" className="flex-[2] h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">
              {editingId ? "Update telemetry" : "Stock the Pool"}
            </Button>
          </div>
        </form>
      </BeaconModal>
    </div>
  );
}
