import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { TrendingUp, Calculator, FileCheck, ClipboardList, Edit2, Trash2, Plus } from "lucide-react";
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, 
  Tooltip as ChartTooltip, ResponsiveContainer
} from "recharts";
import { useState } from "react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";

export default function TaxTaxiRoute() {
  const taxRecords = useLiveQuery(() => db.taxRecords.toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);
  const defaultPersonId = persons?.[0]?.id || "default-person";

  const [activeTab, setActiveTarget] = useState<"tracker" | "forms">("tracker");
  const [selectedFormType, setSelectedFormType] = useState<string | null>(null);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const form = useForm({
    defaultValues: {
      year: new Date().getFullYear(),
      estimatedTaxLiability: 0,
      totalWithheld: 0,
      status: "filing",
      notes: "",
      personId: defaultPersonId
    },
  });

  const onSubmit = async (data: any) => {
    if (!householdId) return;
    if (editingId) {
      await db.taxRecords.update(editingId, data);
      setEditingId(null);
    } else {
      await db.taxRecords.add({ ...data, id: createId(), householdId });
    }
    form.reset();
    setIsModalOpen(false);
  };

  const handleEdit = (record: any) => {
    setEditingId(record.id);
    form.reset({
      year: record.year,
      estimatedTaxLiability: record.estimatedTaxLiability,
      totalWithheld: record.totalWithheld,
      status: record.status,
      notes: record.notes || "",
      personId: record.personId
    });
    setIsModalOpen(true);
  };

  const handleSaveForm = async (type: string, data: Record<string, unknown>) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    await db.taxForms.put({
      id: `${type}-${new Date().getFullYear()}`, 
      year: new Date().getFullYear(),
      type,
      data,
      updatedAt: now,
      personId: defaultPersonId
    });
    alert(`${type} saved to local storage.`);
    setSelectedFormType(null);
  };

  const chartData = taxRecords?.map(r => ({
    year: r.year.toString(),
    Liability: r.estimatedTaxLiability,
    Withheld: r.totalWithheld
  })).sort((a, b) => parseInt(a.year) - parseInt(b.year)) || [];

  if (!taxRecords) return <div className="p-4 text-muted-foreground animate-pulse font-black italic uppercase text-center mt-20">Summoning Tax Taxi...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Tax Taxi" 
        subtitle="Navigate withholdings and annual liability telemetry."
        actions={
          <div className="flex gap-2 bg-primary/5 p-1 rounded-2xl border border-primary/10 shadow-2xl">
            <Button 
              variant={activeTab === "tracker" ? "default" : "ghost"} 
              size="sm" 
              onClick={() => setActiveTarget("tracker")}
              className="rounded-xl uppercase font-black italic text-[10px] tracking-widest h-10 px-6"
            >
              Tracker
            </Button>
            <Button 
              variant={activeTab === "forms" ? "default" : "ghost"} 
              size="sm" 
              onClick={() => setActiveTarget("forms")}
              className="rounded-xl uppercase font-black italic text-[10px] tracking-widest h-10 px-6"
            >
              Forms
            </Button>
          </div>
        }
      />

      {activeTab === "tracker" ? (
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="lg:col-span-3 space-y-8">
            <GlassCard intensity="high">
              <CardHeader className="pb-2 flex flex-row items-center justify-between">
                <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                  <TrendingUp className="h-4 w-4" /> Tax Trajectory
                </CardTitle>
                <Button size="icon" onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
                  <Plus className="h-5 w-5" />
                </Button>
              </CardHeader>
              <CardContent className="h-72">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                    <XAxis dataKey="year" stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} />
                    <YAxis stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} tickFormatter={(v) => `$${v}`} />
                    <ChartTooltip contentStyle={{ background: "rgba(0,0,0,0.85)", border: "none", borderRadius: "12px", color: "#fff", fontSize: "10px" }} />
                    <Bar dataKey="Liability" fill="hsl(var(--destructive))" radius={[4, 4, 0, 0]} barSize={24} />
                    <Bar dataKey="Withheld" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} barSize={24} />
                  </BarChart>
                </ResponsiveContainer>
              </CardContent>
            </GlassCard>

            {taxRecords.length === 0 ? (
              <EmptyState 
                icon={Calculator}
                title="No Records Found"
                description="Start tracking your annual tax records to visualize your refund trajectory."
                action={<Button onClick={() => setIsModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Log Tax Year</Button>}
              />
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {taxRecords.map((record) => {
                  const diff = record.totalWithheld - record.estimatedTaxLiability;
                  const person = persons?.find(p => p.id === record.personId);
                  return (
                    <GlassCard hoverable key={record.id} className={cn("group overflow-hidden", editingId === record.id && "border-primary ring-1 ring-primary")}>
                      <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
                        <div className="flex justify-between items-start">
                          <div>
                            <CardTitle className="text-xl font-black italic tracking-tight uppercase">{record.year} Record</CardTitle>
                            <CardDescription className="text-[10px] font-black uppercase text-primary opacity-70">{person?.name || "Household"}</CardDescription>
                          </div>
                          <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all">
                            <Button variant="ghost" size="icon" onClick={() => handleEdit(record)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-4 w-4" /></Button>
                            <Button variant="ghost" size="icon" onClick={() => db.taxRecords.delete(record.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-4 w-4" /></Button>
                          </div>
                        </div>
                      </CardHeader>
                      <CardContent className="pt-6 space-y-6">
                        <div className="flex justify-between items-end">
                          <div>
                            <div className="text-[10px] font-black uppercase text-muted-foreground opacity-50 mb-1">Owed vs Paid</div>
                            <div className="text-xl font-black italic tracking-tighter text-foreground">${record.estimatedTaxLiability.toLocaleString()} / <span className="text-primary">${record.totalWithheld.toLocaleString()}</span></div>
                          </div>
                        </div>
                        <div className={cn("p-3 rounded-2xl text-center font-black italic text-xs border shadow-inner uppercase tracking-widest", diff >= 0 ? "bg-green-500/5 border-green-500/20 text-green-500" : "bg-destructive/5 border-destructive/20 text-destructive")}>
                          {diff >= 0 ? "Estimated Refund: " : "Telemetry Owed: "}${Math.abs(diff).toLocaleString()}
                        </div>
                      </CardContent>
                    </GlassCard>
                  );
                })}
              </div>
            )}
          </div>
          <div className="lg:col-span-1">
             <GlassCard className="bg-primary/5 border-primary/20 shadow-2xl">
               <CardHeader><CardTitle className="text-[10px] font-black uppercase tracking-widest">Tax Agent Note</CardTitle></CardHeader>
               <CardContent className="text-[10px] font-bold text-muted-foreground leading-relaxed italic">
                 Telemetry tracked here is utilized by Beacon AI to pre-populate digital forms and identify missing deduction opportunities.
               </CardContent>
             </GlassCard>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
           <div className="md:col-span-1 space-y-4">
            <h2 className="text-xl font-black uppercase italic text-primary flex items-center gap-2 px-2">
              <ClipboardList className="h-5 w-5" /> Library
            </h2>
            <div className="space-y-2">
              {["IRS Form 1040", "W-2 Wage Statement", "1099-NEC"].map(f => (
                <button
                  key={f}
                  onClick={() => setSelectedFormType(f)}
                  className={`w-full text-left p-4 rounded-2xl border-2 transition-all duration-300 ${
                    selectedFormType === f ? 'bg-primary text-primary-foreground border-primary shadow-2xl scale-105 italic' : 'bg-card/40 border-primary/5 hover:bg-primary/5 hover:border-primary/20'
                  }`}
                >
                  <div className="font-black text-sm uppercase tracking-tighter">{f}</div>
                  <div className="text-[8px] opacity-70 uppercase font-bold tracking-widest mt-1">Digital Template</div>
                </button>
              ))}
            </div>
          </div>

          <div className="md:col-span-3">
            {selectedFormType ? (
              <GlassCard intensity="high" className="border-primary/20 shadow-2xl animate-in zoom-in-95">
                <CardHeader className="border-b border-primary/10 bg-primary/5">
                  <div className="flex justify-between items-center">
                    <div>
                      <CardTitle className="text-2xl font-black uppercase italic tracking-tighter">{selectedFormType}</CardTitle>
                      <CardDescription className="text-[10px] font-bold uppercase tracking-widest">Digital Drafting Engine • TY{new Date().getFullYear()}</CardDescription>
                    </div>
                    <FileCheck className="h-10 w-10 text-primary opacity-20" />
                  </div>
                </CardHeader>
                <CardContent className="pt-8 space-y-8">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                    <div className="space-y-2"><Label className="text-[10px] font-black uppercase tracking-widest opacity-60 px-1">Entity / Payer</Label><Input placeholder="Payer Name" className="bg-primary/5 border-none font-black h-12" /></div>
                    <div className="space-y-2"><Label className="text-[10px] font-black uppercase tracking-widest opacity-60 px-1">Gross Telemetry</Label><Input type="number" placeholder="0.00" className="bg-primary/5 border-none font-black h-12" /></div>
                  </div>
                  <div className="pt-6 border-t border-primary/5 flex justify-end gap-3">
                    <Button variant="ghost" onClick={() => setSelectedFormType(null)} className="h-12 px-8 uppercase font-black italic text-xs tracking-widest">Discard</Button>
                    <Button onClick={() => handleSaveForm(selectedFormType!, {})} className="h-12 px-10 uppercase font-black italic text-xs tracking-widest shadow-xl shadow-primary/20">Commit Draft</Button>
                  </div>
                </CardContent>
              </GlassCard>
            ) : (
              <EmptyState 
                icon={Calculator}
                title="Drafting Engine Offline"
                description="Select a form from the library to initiate the agentic drafting protocol."
              />
            )}
          </div>
        </div>
      )}

      <BeaconModal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setEditingId(null); }} title={editingId ? "Modify Tax Record" : "Register Tax Year"}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Fiscal Year</Label><Input type="number" {...form.register("year", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Telemetry Owner</Label>
              <NativeSelect {...form.register("personId")} className="bg-primary/5 border-none font-bold h-12 uppercase text-[10px]">
                {persons?.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </NativeSelect>
            </div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Total Owed</Label><Input type="number" step="0.01" {...form.register("estimatedTaxLiability", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Total Paid</Label><Input type="number" step="0.01" {...form.register("totalWithheld", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12 text-primary" /></div>
          </div>
          <Button type="submit" className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">{editingId ? "Update telemetry" : "Commit to Tracker"}</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
