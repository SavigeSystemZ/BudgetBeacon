import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { billSchema, debtSchema } from "../modules/pay-path/pay-path.schema";
import { CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { useState } from "react";
import { Edit2, Trash2, Receipt, CreditCard as CardIcon, Plus } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { BeaconModal } from "../components/ui/BeaconModal";

const billFormSchema = billSchema.omit({ id: true, householdId: true, ownerPersonId: true, createdAt: true, updatedAt: true });
const debtFormSchema = debtSchema.omit({ id: true, householdId: true, ownerPersonId: true, createdAt: true, updatedAt: true });

export default function PayPathRoute() {
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingBillId, setEditingBillId] = useState<string | null>(null);
  const [editingDebtId, setEditingDebtId] = useState<string | null>(null);
  const [isBillModalOpen, setIsBillModalOpen] = useState(false);
  const [isDebtModalOpen, setIsDebtModalOpen] = useState(false);

  const billForm = useForm({
    resolver: zodResolver(billFormSchema),
    defaultValues: { label: "", amount: 0, frequency: "monthly", category: "housing" as const, dueDay: 1, autopay: false, isEssential: true },
  });

  const debtForm = useForm({
    resolver: zodResolver(debtFormSchema),
    defaultValues: { label: "", balance: 0, minimumPayment: 0, apr: 0, category: "credit-card" as const, dueDay: 1, priority: "high" as const },
  });

  const onBillSubmit = async (data: any) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    if (editingBillId) {
      await db.bills.update(editingBillId, { ...data, updatedAt: now });
      setEditingBillId(null);
    } else {
      await db.bills.add({ ...data, id: createId(), householdId, ownerPersonId: "default-person", createdAt: now, updatedAt: now });
    }
    billForm.reset();
    setIsBillModalOpen(false);
  };

  const onDebtSubmit = async (data: any) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    if (editingDebtId) {
      await db.debts.update(editingDebtId, { ...data, updatedAt: now });
      setEditingDebtId(null);
    } else {
      await db.debts.add({ ...data, id: createId(), householdId, ownerPersonId: "default-person", createdAt: now, updatedAt: now });
    }
    debtForm.reset();
    setIsDebtModalOpen(false);
  };

  const handleEditBill = (bill: any) => {
    setEditingBillId(bill.id);
    billForm.reset({ label: bill.label, amount: bill.amount, frequency: bill.frequency, category: bill.category, dueDay: bill.dueDay, autopay: bill.autopay, isEssential: bill.isEssential });
    setIsBillModalOpen(true);
  };

  const handleEditDebt = (debt: any) => {
    setEditingDebtId(debt.id);
    debtForm.reset({ label: debt.label, balance: debt.balance, minimumPayment: debt.minimumPayment, apr: debt.apr, category: debt.category, dueDay: debt.dueDay, priority: debt.priority });
    setIsDebtModalOpen(true);
  };

  if (!bills || !debts) return <div className="p-4 text-muted-foreground animate-pulse font-black italic">Mapping Pay Path...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Pay Path" 
        subtitle="Mission-critical bills and liability telemetry."
        actions={
          <div className="flex gap-2">
            <Button variant="outline" size="sm" onClick={() => { setEditingBillId(null); billForm.reset(); setIsBillModalOpen(true); }} className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5">
              <Plus className="h-4 w-4" /> Add Bill
            </Button>
            <Button variant="outline" size="sm" onClick={() => { setEditingDebtId(null); debtForm.reset(); setIsDebtModalOpen(true); }} className="gap-2 h-10 border-primary/20 text-primary uppercase font-black italic text-[10px] tracking-widest bg-primary/5">
              <Plus className="h-4 w-4" /> Add Debt
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div className="space-y-6">
          <h2 className="text-xl font-black uppercase italic text-primary flex items-center gap-2 px-2"><Receipt className="h-5 w-5" /> Active Bills</h2>
          <div className="grid grid-cols-1 gap-3">
            {bills.map((bill) => (
              <GlassCard hoverable key={bill.id} className="group border-primary/5 bg-primary/5">
                <CardContent className="p-4 flex justify-between items-center">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center text-primary border border-primary/20 shadow-inner font-black text-xs">{bill.dueDay}</div>
                    <div>
                      <div className="font-black italic text-sm uppercase tracking-tighter">{bill.label}</div>
                      <div className="text-[9px] uppercase font-black text-muted-foreground opacity-50 tracking-widest">Day {bill.dueDay} • {bill.category}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-6">
                    <div className="text-xl font-black italic tracking-tighter text-foreground">${bill.amount.toLocaleString()}</div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                      <Button variant="ghost" size="icon" onClick={() => handleEditBill(bill)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-3.5 w-3.5" /></Button>
                      <Button variant="ghost" size="icon" onClick={() => db.bills.delete(bill.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-3.5 w-3.5" /></Button>
                    </div>
                  </div>
                </CardContent>
              </GlassCard>
            ))}
          </div>
        </div>

        <div className="space-y-6">
          <h2 className="text-xl font-black uppercase italic text-primary flex items-center gap-2 px-2"><CardIcon className="h-5 w-5" /> Liabilities</h2>
          <div className="grid grid-cols-1 gap-3">
            {debts.map((debt) => (
              <GlassCard hoverable key={debt.id} className="group border-primary/5 bg-primary/5">
                <CardContent className="p-4 flex justify-between items-center">
                  <div className="flex items-center gap-4">
                    <div className="h-10 w-10 rounded-xl bg-destructive/10 flex items-center justify-center text-destructive border border-destructive/20 shadow-inner font-black text-xs italic">!</div>
                    <div>
                      <div className="font-black italic text-sm uppercase tracking-tighter">{debt.label}</div>
                      <div className="text-[9px] uppercase font-black text-muted-foreground opacity-50 tracking-widest">Balance: ${debt.balance.toLocaleString()}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-6">
                    <div className="text-right">
                      <div className="text-xl font-black italic tracking-tighter text-foreground">${debt.minimumPayment.toLocaleString()}</div>
                      <div className="text-[8px] uppercase font-black text-muted-foreground opacity-50">Min Payment</div>
                    </div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                      <Button variant="ghost" size="icon" onClick={() => handleEditDebt(debt)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-3.5 w-3.5" /></Button>
                      <Button variant="ghost" size="icon" onClick={() => db.debts.delete(debt.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-3.5 w-3.5" /></Button>
                    </div>
                  </div>
                </CardContent>
              </GlassCard>
            ))}
          </div>
        </div>
      </div>

      <BeaconModal isOpen={isBillModalOpen} onClose={() => setIsBillModalOpen(false)} title={editingBillId ? "Modify Bill Telemetry" : "Register Bill"}>
        <form onSubmit={billForm.handleSubmit(onBillSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 col-span-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label><Input {...billForm.register("label")} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Amount</Label><Input type="number" step="0.01" {...billForm.register("amount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Due Day</Label><Input type="number" {...billForm.register("dueDay", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
          </div>
          <Button type="submit" className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">{editingBillId ? "Update Bill" : "Stock Pay Path"}</Button>
        </form>
      </BeaconModal>

      <BeaconModal isOpen={isDebtModalOpen} onClose={() => setIsDebtModalOpen(false)} title={editingDebtId ? "Modify Liability" : "Register Debt"}>
        <form onSubmit={debtForm.handleSubmit(onDebtSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 col-span-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label><Input {...debtForm.register("label")} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Balance</Label><Input type="number" step="0.01" {...debtForm.register("balance", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Min. Payment</Label><Input type="number" step="0.01" {...debtForm.register("minimumPayment", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
          </div>
          <Button type="submit" className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">{editingDebtId ? "Update Debt" : "Stock Pay Path"}</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
