import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { AlertCircle, TrendingDown, Edit2, Trash2, Plus, ShieldAlert } from "lucide-react";
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip as ChartTooltip, ResponsiveContainer 
} from "recharts";
import { format, parseISO, endOfMonth, eachMonthOfInterval, subMonths } from "date-fns";
import { useState } from "react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";

const debtCenterSchema = z.object({
  label: z.string().min(1, "Label is required"),
  balance: z.number().min(0),
  minimumPayment: z.number().min(0),
  interestRate: z.number().min(0),
  category: z.enum(["collection", "credit-card", "medical", "legal", "other"]),
  status: z.enum(["active", "negotiating", "settled", "disputed"]),
  notes: z.string().optional()
});

type FormData = z.infer<typeof debtCenterSchema>;

export default function DebtCenterRoute() {
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const transactions = useLiveQuery(() => db.debtTransactions.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const form = useForm<FormData>({
    resolver: zodResolver(debtCenterSchema),
    defaultValues: { label: "", balance: 0, minimumPayment: 0, interestRate: 0, category: "collection", status: "active", notes: "" },
  });

  const onSubmit = async (data: FormData) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    const mappedData = { ...data, category: (data.category === "collection" ? "other" : data.category) as any };

    if (editingId) {
      await db.debts.update(editingId, { ...mappedData, updatedAt: now });
      await db.debtTransactions.add({ id: createId(), debtId: editingId, amount: data.balance, date: now, type: "update" });
      setEditingId(null);
    } else {
      const id = createId();
      await db.debts.add({ ...mappedData, id, householdId, ownerPersonId: "default-person", priority: "high", dueDay: 1, createdAt: now, updatedAt: now });
      await db.debtTransactions.add({ id: createId(), debtId: id, amount: data.balance, date: now, type: "snapshot" });
    }
    form.reset();
    setIsModalOpen(false);
  };

  const handleEdit = (debt: any) => {
    setEditingId(debt.id);
    form.reset({
      label: debt.label,
      balance: debt.balance,
      minimumPayment: debt.minimumPayment,
      interestRate: debt.interestRate || 0,
      category: (debt.category === "other" ? "collection" : debt.category) as any,
      status: debt.status || "active",
      notes: debt.notes || "",
    });
    setIsModalOpen(true);
  };

  const chartData = eachMonthOfInterval({
    start: subMonths(new Date(), 5),
    end: new Date()
  }).map(month => {
    const monthStr = format(month, "MMM yy");
    const totalAtMonth = debts?.reduce((acc, debt) => {
      const monthEnd = endOfMonth(month);
      const relevantTx = transactions?.filter(t => t.debtId === debt.id && parseISO(t.date) <= monthEnd)
        .sort((a, b) => parseISO(b.date).getTime() - parseISO(a.date).getTime())[0];
      return acc + (relevantTx?.amount || 0);
    }, 0) || 0;
    return { month: monthStr, balance: totalAtMonth };
  });

  if (!debts) return <div className="p-4 text-muted-foreground animate-pulse font-black italic uppercase">Opening Debt Center...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Debt Center" 
        subtitle="Collections and high-pressure liability management."
        actions={
          <Button onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }} className="gap-2 px-6 bg-destructive text-destructive-foreground hover:bg-destructive/90 uppercase font-black italic text-xs tracking-widest shadow-xl shadow-destructive/20 h-12">
            <Plus className="h-4 w-4" /> Add Liability
          </Button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="lg:col-span-3 space-y-8">
          <GlassCard intensity="high" className="border-destructive/10">
            <CardHeader className="pb-2">
              <CardTitle className="text-[10px] font-black uppercase tracking-widest text-destructive flex items-center gap-2">
                <TrendingDown className="h-4 w-4" /> Liability Trajectory
              </CardTitle>
            </CardHeader>
            <CardContent className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={chartData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                  <XAxis dataKey="month" stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} />
                  <YAxis stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v}`} />
                  <ChartTooltip contentStyle={{ background: "rgba(0,0,0,0.85)", border: "none", borderRadius: "12px", color: "#fff", fontSize: "10px" }} />
                  <Line type="monotone" dataKey="balance" stroke="hsl(var(--destructive))" strokeWidth={4} dot={{ r: 4, fill: "hsl(var(--destructive))" }} activeDot={{ r: 6 }} />
                </LineChart>
              </ResponsiveContainer>
            </CardContent>
          </GlassCard>

          {debts.length === 0 ? (
            <EmptyState 
              icon={ShieldAlert}
              title="No Liabilities Found"
              description="Your debt center is currently at zero pressure. Add collections or loans to track payoff trajectory."
            />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {debts.map((debt) => (
                <GlassCard hoverable key={debt.id} className={cn("group border-destructive/10 bg-destructive/5 hover:border-destructive/30", editingId === debt.id && "border-destructive ring-1 ring-destructive")}>
                  <CardHeader className="pb-3 flex flex-row items-center justify-between border-b border-destructive/5">
                    <div>
                      <CardTitle className="text-lg font-black uppercase italic truncate max-w-[150px]">{debt.label}</CardTitle>
                      <CardDescription className="text-destructive font-bold uppercase text-[8px] flex items-center gap-1">
                        <AlertCircle className="h-2 w-2" /> High Pressure
                      </CardDescription>
                    </div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all">
                      <Button variant="ghost" size="icon" onClick={() => handleEdit(debt)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Edit2 className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" onClick={() => db.debts.delete(debt.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-4 w-4" /></Button>
                    </div>
                  </CardHeader>
                  <CardContent className="pt-6">
                    <div className="flex justify-between items-end">
                      <div>
                        <div className="text-[10px] font-black uppercase text-muted-foreground opacity-50 mb-1">Total Liability</div>
                        <div className="text-3xl font-black italic tracking-tighter text-foreground">${debt.balance.toLocaleString()}</div>
                      </div>
                      <div className="text-right">
                        <div className="text-[10px] font-black uppercase text-destructive mb-1">Min Payment</div>
                        <div className="text-lg font-black italic text-foreground">${debt.minimumPayment}/mo</div>
                      </div>
                    </div>
                  </CardContent>
                </GlassCard>
              ))}
            </div>
          )}
        </div>

        <div className="space-y-6">
          <GlassCard className="bg-destructive/5 border-destructive/20 shadow-2xl">
            <CardHeader>
              <CardTitle className="text-[10px] font-black uppercase tracking-widest text-destructive flex items-center gap-2">
                <AlertCircle className="h-4 w-4" /> Critical Focus
              </CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] font-bold text-muted-foreground leading-relaxed italic">
              Items in the Debt Center represent immediate mission threats. Prioritize settlements to increase strategic propulsion in Mission Control.
            </CardContent>
          </GlassCard>
        </div>
      </div>

      <BeaconModal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setEditingId(null); }} title={editingId ? "Refine Liability" : "Register Collection"}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 col-span-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1 text-destructive">Entity Label</Label>
              <Input {...form.register("label")} placeholder="e.g. Portfolio Recovery" className="bg-destructive/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1 text-destructive">Total Balance</Label>
              <Input type="number" step="0.01" {...form.register("balance", { valueAsNumber: true })} className="bg-destructive/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1 text-destructive">Minimum Flow</Label>
              <Input type="number" step="0.01" {...form.register("minimumPayment", { valueAsNumber: true })} className="bg-destructive/5 border-none font-bold h-12" />
            </div>
          </div>
          <Button type="submit" className="w-full h-12 bg-destructive text-white uppercase font-black italic tracking-widest shadow-xl shadow-destructive/20">{editingId ? "Update Record" : "Commit to Center"}</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
