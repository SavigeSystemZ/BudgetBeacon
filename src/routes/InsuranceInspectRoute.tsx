import { useLiveQuery } from "dexie-react-hooks";
import { useState } from "react";
import { useForm } from "react-hook-form";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { ShieldCheck, Plus, Edit2, Trash2, ShieldAlert } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";
import { DemoBadge } from "../components/ui/DemoBadge";
import { featureFlags } from "../lib/flags/featureFlags";

interface PolicyForm {
  type: string;
  premium: number;
  expirationDate: string;
}

/**
 * Insurance Inspect — manual policy CRUD against the existing `insuranceRecords` Dexie table.
 *
 * The previous version simulated a "market sweep" with hardcoded Progressive/Geico/State Farm
 * quotes after a setTimeout. Real third-party quote APIs are not available to a household app;
 * Budget Beacon will not pretend to scrape the market. Manual entry is the honest baseline.
 */
export default function InsuranceInspectRoute() {
  const policies = useLiveQuery(() => db.insuranceRecords.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then((h) => h?.id), []);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const form = useForm<PolicyForm>({
    defaultValues: { type: "auto", premium: 0, expirationDate: "" },
  });

  const onSubmit = async (data: PolicyForm) => {
    if (!householdId) return;
    if (editingId) {
      await db.insuranceRecords.update(editingId, data);
      setEditingId(null);
    } else {
      await db.insuranceRecords.add({
        id: createId(),
        householdId,
        type: data.type,
        premium: Number(data.premium),
        expirationDate: data.expirationDate,
      });
    }
    form.reset({ type: "auto", premium: 0, expirationDate: "" });
    setIsModalOpen(false);
  };

  const startEdit = (p: { id: string; type: string; premium?: number; expirationDate: string }) => {
    setEditingId(p.id);
    form.reset({ type: p.type, premium: p.premium ?? 0, expirationDate: p.expirationDate });
    setIsModalOpen(true);
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Delete this policy record?")) await db.insuranceRecords.delete(id);
  };

  if (!policies) {
    return <div className="p-4 text-muted-foreground animate-pulse font-black uppercase italic">Loading policies...</div>;
  }

  const totalMonthly = policies.reduce((sum, p) => sum + (p.premium || 0), 0);

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Insurance Inspect"
        subtitle="Track active household insurance policies."
        actions={
          <Button
            size="icon"
            onClick={() => { setEditingId(null); form.reset({ type: "auto", premium: 0, expirationDate: "" }); setIsModalOpen(true); }}
            className="rounded-full shadow-lg shadow-primary/20 h-10 w-10"
          >
            <Plus className="h-5 w-5" />
          </Button>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="lg:col-span-1 space-y-6">
          <GlassCard intensity="high" className="border-primary/20 bg-primary/5">
            <CardHeader className="pb-3 border-b border-primary/5">
              <CardTitle className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest text-primary">
                <ShieldCheck className="h-4 w-4" /> Active Coverage
              </CardTitle>
            </CardHeader>
            <CardContent className="pt-6 space-y-3">
              <div className="p-4 rounded-2xl bg-primary/10 border border-primary/20 shadow-inner">
                <div className="text-[9px] font-black uppercase text-muted-foreground mb-1">Monthly Premium Total</div>
                <div className="text-3xl font-black italic tracking-tighter text-primary">${totalMonthly.toFixed(2)}</div>
              </div>
              <div className="text-[10px] text-muted-foreground leading-relaxed">
                Tracked across <strong className="text-foreground">{policies.length}</strong> polic{policies.length === 1 ? "y" : "ies"}.
              </div>
            </CardContent>
          </GlassCard>

          {!featureFlags.insuranceMarketScrape && (
            <GlassCard className="border-amber-400/20 bg-amber-400/5">
              <CardHeader className="pb-3 flex flex-row items-center gap-2">
                <ShieldAlert className="h-4 w-4 text-amber-400" />
                <CardTitle className="text-[10px] font-black uppercase tracking-widest">Market Sweep</CardTitle>
              </CardHeader>
              <CardContent className="space-y-2">
                <DemoBadge>Not connected.</DemoBadge>
                <p className="text-[10px] text-muted-foreground leading-relaxed">
                  Budget Beacon does not pull live insurance quotes — no real provider API is wired in. The earlier "market sweep" UI showed hardcoded numbers and has been removed.
                </p>
              </CardContent>
            </GlassCard>
          )}
        </div>

        <div className="lg:col-span-3 space-y-6">
          <h2 className="text-xl font-black uppercase italic text-primary px-2">Policies</h2>

          {policies.length === 0 ? (
            <EmptyState
              icon={ShieldCheck}
              title="No Policies Tracked"
              description="Add your active auto, home, life, or other policies so monthly premium totals roll into Mission Control."
              action={
                <Button
                  onClick={() => { setEditingId(null); form.reset({ type: "auto", premium: 0, expirationDate: "" }); setIsModalOpen(true); }}
                  className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"
                >
                  <Plus className="h-4 w-4" /> Add Policy
                </Button>
              }
            />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {policies.map((p) => (
                <GlassCard hoverable key={p.id} className="group overflow-hidden">
                  <CardHeader className="pb-3 flex flex-row items-center justify-between border-b border-primary/5 bg-primary/5">
                    <div>
                      <CardTitle className="text-sm font-black italic uppercase tracking-tighter">{p.type}</CardTitle>
                      <div className="text-[9px] font-black uppercase tracking-widest text-primary opacity-60 mt-1">
                        Expires {p.expirationDate || "—"}
                      </div>
                    </div>
                    <div className="text-2xl font-black italic tracking-tighter text-primary">
                      ${(p.premium ?? 0).toFixed(2)}
                      <span className="text-[10px] text-muted-foreground not-italic">/mo</span>
                    </div>
                  </CardHeader>
                  <CardContent className="pt-3 flex justify-end gap-1">
                    <Button variant="ghost" size="icon" onClick={() => startEdit(p)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-3.5 w-3.5" /></Button>
                    <Button variant="ghost" size="icon" onClick={() => handleDelete(p.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-3.5 w-3.5" /></Button>
                  </CardContent>
                </GlassCard>
              ))}
            </div>
          )}
        </div>
      </div>

      <BeaconModal
        isOpen={isModalOpen}
        onClose={() => { setIsModalOpen(false); setEditingId(null); }}
        title={editingId ? "Edit Policy" : "Add Policy"}
      >
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="space-y-2">
            <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Policy Type</Label>
            <NativeSelect {...form.register("type")} className="bg-primary/5 border-none font-bold h-12">
              <option value="auto">Auto</option>
              <option value="home">Home / Renters</option>
              <option value="life">Life</option>
              <option value="health">Health</option>
              <option value="dental">Dental / Vision</option>
              <option value="umbrella">Umbrella</option>
              <option value="other">Other</option>
            </NativeSelect>
          </div>
          <div className="space-y-2">
            <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Monthly Premium</Label>
            <Input type="number" step="0.01" {...form.register("premium", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" />
          </div>
          <div className="space-y-2">
            <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Expiration / Renewal Date</Label>
            <Input type="date" {...form.register("expirationDate")} className="bg-primary/5 border-none font-bold h-12" />
          </div>
          <div className="flex gap-3 pt-2">
            <Button type="button" variant="outline" onClick={() => { setIsModalOpen(false); setEditingId(null); }} className="flex-1 h-12 uppercase font-black italic tracking-widest border-primary/20">Cancel</Button>
            <Button type="submit" className="flex-[2] h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">
              {editingId ? "Update Policy" : "Add Policy"}
            </Button>
          </div>
        </form>
      </BeaconModal>
    </div>
  );
}
