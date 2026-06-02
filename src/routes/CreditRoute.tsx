import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { creditSnapshotSchema } from "../modules/credit/credit.schema";
import { CardHeader, CardTitle, CardContent } from "../components/ui/card";
import { RouteSkeleton } from "../components/ui/Skeleton";
import { Button } from "../components/ui/button";

import { Label } from "../components/ui/label";
import { ResettableInput } from "../components/ui/ResettableInput";
import { ResettableNativeSelect } from "../components/ui/ResettableNativeSelect";
import { NativeSelect } from "../components/ui/native-select";
import { format, parseISO } from "date-fns";
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, 
  Tooltip as ChartTooltip, ResponsiveContainer, Legend 
} from "recharts";
import { useState } from "react";
import { Sparkles, TrendingUp, Plus, Trash2, FileText } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { BeaconModal } from "../components/ui/BeaconModal";
import { EmptyState } from "../components/ui/EmptyState";
import { useDeleteConfirm } from "../context/DeleteConfirmContext";
import type { z } from "zod";

const formSchema = creditSnapshotSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type CreditFormValues = z.infer<typeof formSchema>;

export default function CreditRoute() {
  const confirmDelete = useDeleteConfirm();
  const snapshots = useLiveQuery(() => db.creditSnapshots.orderBy("snapshotDate").reverse().toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedPersonId, setSelectedPersonId] = useState<string>("");

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { score: 700, bureauOrSource: "Experian", model: "FICO 8", snapshotDate: new Date().toISOString().split("T")[0], notes: "", personId: "" },
  });

  const onSubmit = async (data: CreditFormValues) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    await db.creditSnapshots.add({
      ...data,
      snapshotDate: new Date(data.snapshotDate).toISOString(),
      id: createId(),
      householdId,
      createdAt: now,
      updatedAt: now,
    });
    form.reset();
    setIsModalOpen(false);
  };

  if (!snapshots || !persons) return <RouteSkeleton cards={3} label="Opening credit vault" />;

  const filteredSnapshots = selectedPersonId ? snapshots.filter(s => s.personId === selectedPersonId) : snapshots;
  const chartData = filteredSnapshots.slice().reverse().map(s => {
    const person = persons.find(p => p.id === s.personId);
    return {
      date: format(parseISO(s.snapshotDate), "MMM d"),
      score: s.score,
      name: person?.name || "Unknown"
    };
  });

  const snapshotsEmpty = filteredSnapshots.length === 0;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader
        title="Credit Snapshot"
        subtitle="Multi-person manual credit-score tracking."
        actions={
          <div className="flex gap-2">
            <Button
              size="icon"
              variant="outline"
              aria-label="Wipe all credit snapshots"
              onClick={async () => {
                if (await confirmDelete("all credit snapshots", "Wipe Credit Vault")) {
                  const ids = snapshots?.map(s => s.id) || [];
                  await db.creditSnapshots.bulkDelete(ids);
                }
              }}
              className="h-10 w-10 text-destructive border-destructive/20 hover:bg-destructive/10 bg-primary/5"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
            <Button
              size="icon"
              aria-label="Log new credit score snapshot"
              onClick={() => { form.reset(); setIsModalOpen(true); }}
              className="rounded-full shadow-lg shadow-primary/20 h-10 w-10"
            >
              <Plus className="h-5 w-5" />
            </Button>
          </div>
        }
      />

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="lg:col-span-3 space-y-8">
          <GlassCard intensity="high">
            <CardHeader className="pb-2 flex flex-row items-center justify-between">
              <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                <TrendingUp className="h-4 w-4" /> Score Trajectory
              </CardTitle>
              <div className="w-48">
                <NativeSelect value={selectedPersonId} onChange={(e) => setSelectedPersonId(e.target.value)} className="bg-primary/5 border-none font-black uppercase text-[10px]">
                  <option value="">All Household</option>
                  {persons.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
                </NativeSelect>
              </div>
            </CardHeader>
            <CardContent className="h-80">
              {snapshotsEmpty ? (
                <div className="h-full flex items-center justify-center text-center px-6">
                  <p className="text-sm font-bold text-muted-foreground max-w-md">
                    {snapshots.length === 0
                      ? "Add a snapshot below to unlock the trajectory chart."
                      : "No data for this person — switch to All Household or log a score for them."}
                  </p>
                </div>
              ) : (
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.05)" vertical={false} />
                    <XAxis dataKey="date" stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} />
                    <YAxis domain={['dataMin - 50', 'dataMax + 50']} stroke="hsl(var(--muted-foreground))" fontSize={10} axisLine={false} tickLine={false} />
                    <ChartTooltip contentStyle={{ background: "rgba(0,0,0,0.85)", border: "none", borderRadius: "12px", color: "#fff", fontSize: "10px" }} />
                    <Legend />
                    <Line type="monotone" dataKey="score" stroke="hsl(var(--primary))" strokeWidth={4} dot={{ r: 4, fill: "hsl(var(--primary))" }} activeDot={{ r: 6 }} />
                  </LineChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </GlassCard>

          {snapshotsEmpty ? (
            <EmptyState
              icon={FileText}
              title={snapshots.length === 0 ? "No credit snapshots yet" : "Nothing for this filter"}
              description={
                snapshots.length === 0
                  ? "Pull your bureau or bank score and log it here — automated bureau fetch stays out of scope on purpose."
                  : "Pick “All Household” in the dropdown or add a snapshot for this member."
              }
              action={
                <Button
                  onClick={() => { form.reset(); setIsModalOpen(true); }}
                  className="gap-2 uppercase font-black italic text-xs"
                >
                  <Plus className="h-4 w-4" /> Log snapshot
                </Button>
              }
              className="min-h-[280px]"
            />
          ) : (
            <div className="space-y-4">
              <h2 className="text-xl font-black uppercase italic text-primary px-2">Score History</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {filteredSnapshots.map((snap) => (
                  <GlassCard hoverable key={snap.id} className="group overflow-hidden">
                    <CardHeader className="pb-2 flex flex-row items-center justify-between border-b border-primary/5 bg-primary/5">
                      <CardTitle className="text-3xl font-black italic tracking-tighter text-primary">{snap.score}</CardTitle>
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label={`Delete credit snapshot ${snap.score} ${snap.bureauOrSource}`}
                        onClick={() => {
                          void (async () => {
                            const name = `${snap.score} · ${snap.bureauOrSource} · ${format(parseISO(snap.snapshotDate), "MMM d yyyy")}`;
                            if (!(await confirmDelete("credit snapshot", name))) return;
                            await db.creditSnapshots.delete(snap.id);
                          })();
                        }}
                        className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive opacity-0 group-hover:opacity-100 transition-opacity"
                      ><Trash2 className="h-4 w-4" /></Button>
                    </CardHeader>
                    <CardContent className="pt-4">
                      <div className="text-[10px] font-black uppercase text-muted-foreground tracking-widest mb-1">{persons.find(p => p.id === snap.personId)?.name}</div>
                      <div className="text-[8px] uppercase font-bold text-primary/70">{snap.bureauOrSource} • {format(parseISO(snap.snapshotDate), "MMM d, yyyy")}</div>
                    </CardContent>
                  </GlassCard>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="space-y-6">
          <GlassCard className="bg-primary/5 border-primary/20 shadow-2xl">
            <CardHeader>
              <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
                <Sparkles className="h-4 w-4" /> How to update
              </CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] font-bold text-muted-foreground leading-relaxed italic space-y-2">
              <p>
                Pull your free annual report at <span className="text-primary not-italic">annualcreditreport.com</span>, or check the score your bank already shows you, then log it here with the bureau and date.
              </p>
              <p className="opacity-70 not-italic">
                Automated bureau fetch is not available — Budget Beacon will not pretend to "scavenge" a score from your bank. Manual entry is the honest baseline.
              </p>
            </CardContent>
          </GlassCard>
        </div>
      </div>

      <BeaconModal isOpen={isModalOpen} onClose={() => setIsModalOpen(false)} title="Log Credit Score">
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Person</Label>
              <ResettableNativeSelect label="Person" onResetValue={() => form.setValue("personId", "")} {...form.register("personId")} className="bg-primary/5 border-none font-bold h-12">
                <option value="">Select Member</option>
                {persons.map(p => <option key={p.id} value={p.id}>{p.name}</option>)}
              </ResettableNativeSelect>
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Credit Score</Label>
              <ResettableInput label="Credit Score" type="number" onResetValue={() => form.setValue("score", 0)} {...form.register("score", { valueAsNumber: true })} className="bg-primary/5 border-none font-black h-12 text-2xl text-primary" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Timestamp</Label>
              <ResettableInput label="Timestamp" type="date" onResetValue={() => form.setValue("snapshotDate", "")} {...form.register("snapshotDate")} className="bg-primary/5 border-none font-bold h-12" />
            </div>
            <div className="space-y-2">
              <Label className="text-[10px] uppercase font-black tracking-widest opacity-70 px-1">Bureau / Model</Label>
              <ResettableInput label="Bureau" onResetValue={() => form.setValue("bureauOrSource", "")} {...form.register("bureauOrSource")} className="bg-primary/5 border-none font-bold h-12" />
            </div>
          </div>
          <Button type="submit" disabled={!householdId} className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">Commit Snapshot</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
