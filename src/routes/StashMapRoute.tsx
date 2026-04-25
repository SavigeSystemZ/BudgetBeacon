import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { savingsGoalSchema } from "../modules/stash-map/stash-map.schema";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { useState } from "react";
import { Edit2, Trash2, Target, Plus } from "lucide-react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";
import { Progress } from "../components/ui/progress";

const formSchema = savingsGoalSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });

export default function StashMapRoute() {
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { label: "", targetAmount: 0, currentAmount: 0, monthlyContribution: 0, category: "other" as const, deadline: "", priority: "medium" as const },
  });

  const onSubmit = async (data: any) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    if (editingId) {
      await db.savingsGoals.update(editingId, { ...data, updatedAt: now });
      setEditingId(null);
    } else {
      await db.savingsGoals.add({ ...data, id: createId(), householdId, createdAt: now, updatedAt: now });
    }
    form.reset();
    setIsModalOpen(false);
  };

  const handleEdit = (goal: any) => {
    setEditingId(goal.id);
    form.reset({
      label: goal.label,
      targetAmount: goal.targetAmount,
      currentAmount: goal.currentAmount,
      monthlyContribution: goal.monthlyContribution,
      category: goal.category || "other",
      deadline: goal.deadline || "",
      priority: goal.priority || "medium"
    });
    setIsModalOpen(true);
  };

  if (!goals) return <div className="p-4 text-muted-foreground animate-pulse font-black italic uppercase">Synchronizing Stash...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Stash Map" 
        subtitle="Plan and track strategic savings objectives."
        actions={
          <Button size="icon" onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
            <Plus className="h-5 w-5" />
          </Button>
        }
      />

      {goals.length === 0 ? (
        <EmptyState 
          icon={Target}
          title="Map is Blank"
          description="Define your strategic stash objectives—Emergency Funds, Home Down Payments, or Vacation Pools."
          action={<Button onClick={() => setIsModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Add Objective</Button>}
        />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {goals.map((goal) => {
            const progress = (goal.currentAmount / goal.targetAmount) * 100;
            return (
              <GlassCard hoverable key={goal.id} className={cn("group border-primary/10 overflow-hidden relative", editingId === goal.id && "border-primary ring-1 ring-primary shadow-2xl")}>
                <CardHeader className="pb-3 border-b border-primary/5 bg-primary/5">
                  <div className="flex justify-between items-start">
                    <div>
                      <CardTitle className="text-lg font-black italic tracking-tight uppercase">{goal.label}</CardTitle>
                      <CardDescription className="text-[10px] uppercase font-black tracking-widest text-primary opacity-70">Target: ${goal.targetAmount.toLocaleString()}</CardDescription>
                    </div>
                    <div className="flex gap-1 opacity-0 group-hover:opacity-100 transition-all duration-300">
                      <Button variant="ghost" size="icon" onClick={() => handleEdit(goal)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-4 w-4" /></Button>
                      <Button variant="ghost" size="icon" onClick={() => db.savingsGoals.delete(goal.id)} className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"><Trash2 className="h-4 w-4" /></Button>
                    </div>
                  </div>
                </CardHeader>
                <CardContent className="pt-6 space-y-4">
                  <div className="flex justify-between items-end">
                    <div className="text-3xl font-black italic tracking-tighter text-foreground">${goal.currentAmount.toLocaleString()}</div>
                    <div className="text-[10px] font-black uppercase text-primary bg-primary/10 px-2 py-1 rounded-md">{progress.toFixed(0)}% Complete</div>
                  </div>
                  <Progress value={progress} className="h-2 bg-primary/5" />
                  <div className="flex justify-between text-[8px] font-black uppercase text-muted-foreground tracking-widest pt-2">
                    <span>Active Contribution: ${goal.monthlyContribution}/mo</span>
                    <span>Deadline: {goal.deadline || "TBD"}</span>
                  </div>
                </CardContent>
              </GlassCard>
            );
          })}
        </div>
      )}

      <BeaconModal isOpen={isModalOpen} onClose={() => { setIsModalOpen(false); setEditingId(null); }} title={editingId ? "Modify Objective" : "New Stash Target"}>
        <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-2 col-span-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label><Input {...form.register("label")} placeholder="e.g. Emergency Fund" className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Target Value</Label><Input type="number" step="0.01" {...form.register("targetAmount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Current Stash</Label><Input type="number" step="0.01" {...form.register("currentAmount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Monthly Fuel</Label><Input type="number" step="0.01" {...form.register("monthlyContribution", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Mission Deadline</Label><Input type="date" {...form.register("deadline")} className="bg-primary/5 border-none font-bold h-12" /></div>
          </div>
          <Button type="submit" className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">{editingId ? "Update Plan" : "Commit to Map"}</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
