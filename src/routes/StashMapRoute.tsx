import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { savingsGoalSchema, type SavingsGoal } from "../modules/stash-map/stash-map.schema";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { RouteSkeleton } from "../components/ui/Skeleton";
import { Button } from "../components/ui/button";

import { Label } from "../components/ui/label";
import { ResettableInput } from "../components/ui/ResettableInput";
import { useState } from "react";
import { Edit2, Trash2, Target, Plus } from "lucide-react";
import { cn } from "../lib/utils";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";
import { Progress } from "../components/ui/progress";
import { useDeleteConfirm } from "../context/DeleteConfirmContext";

const formSchema = savingsGoalSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type FormData = z.infer<typeof formSchema>;

export default function StashMapRoute() {
  const confirmDelete = useDeleteConfirm();
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then(h => h?.id), []);

  const [editingId, setEditingId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: { label: "", targetAmount: 0, currentAmount: 0, monthlyContribution: 0, category: "other" as const, deadline: "", priority: "medium" as const },
  });

  const onSubmit = async (data: FormData) => {
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

  const handleEdit = (goal: SavingsGoal) => {
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

  if (!goals) return <RouteSkeleton cards={3} label="Synchronizing goals" />;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="Stash Map" 
        subtitle="Plan and track strategic savings objectives."
        actions={
          <div className="flex gap-2">
            <Button
              size="icon"
              variant="outline"
              aria-label="Wipe all stash goals"
              onClick={async () => {
                if (await confirmDelete("all goals", "Wipe Stash Map")) {
                  const ids = goals?.map(g => g.id) || [];
                  await db.savingsGoals.bulkDelete(ids);
                }
              }}
              className="h-10 w-10 text-destructive border-destructive/20 hover:bg-destructive/10 bg-primary/5"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
            <Button
              size="icon"
              aria-label="Add savings goal"
              onClick={() => { setEditingId(null); form.reset(); setIsModalOpen(true); }}
              className="rounded-full shadow-lg shadow-primary/20 h-10 w-10"
            >
              <Plus className="h-5 w-5" />
            </Button>
          </div>
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
                      <Button variant="ghost" size="icon" aria-label={`Edit goal ${goal.label}`} onClick={() => handleEdit(goal)} className="h-8 w-8 rounded-full hover:bg-primary/10 text-primary"><Edit2 className="h-4 w-4" /></Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        aria-label={`Delete goal ${goal.label}`}
                        onClick={() => {
                          void (async () => {
                            if (!(await confirmDelete("savings goal", goal.label))) return;
                            await db.savingsGoals.delete(goal.id);
                          })();
                        }}
                        className="h-8 w-8 rounded-full hover:bg-destructive/10 text-destructive"
                      ><Trash2 className="h-4 w-4" /></Button>
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
            <div className="space-y-2 col-span-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label><ResettableInput label="Label" onResetValue={() => form.setValue("label", "")} {...form.register("label")} placeholder="e.g. Emergency Fund" className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Target Value</Label><ResettableInput label="Target Value" type="number" step="0.01" onResetValue={() => form.setValue("targetAmount", 0)} {...form.register("targetAmount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Current Stash</Label><ResettableInput label="Current Stash" type="number" step="0.01" onResetValue={() => form.setValue("currentAmount", 0)} {...form.register("currentAmount", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Monthly Fuel</Label><ResettableInput label="Monthly Fuel" type="number" step="0.01" onResetValue={() => form.setValue("monthlyContribution", 0)} {...form.register("monthlyContribution", { valueAsNumber: true })} className="bg-primary/5 border-none font-bold h-12" /></div>
            <div className="space-y-2"><Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Mission Deadline</Label><ResettableInput label="Mission Deadline" type="date" onResetValue={() => form.setValue("deadline", "")} {...form.register("deadline")} className="bg-primary/5 border-none font-bold h-12" /></div>
          </div>
          <Button type="submit" className="w-full h-12 uppercase font-black italic tracking-widest shadow-xl shadow-primary/20">{editingId ? "Update Plan" : "Commit to Map"}</Button>
        </form>
      </BeaconModal>
    </div>
  );
}
