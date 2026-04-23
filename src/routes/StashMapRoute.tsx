import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { savingsGoalSchema } from "../modules/stash-map/stash-map.schema";
import { forecastSavingsGoal } from "../modules/stash-map/stash-map.calculations";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { cn } from "../lib/utils";
import { format, parseISO } from "date-fns";

const formSchema = savingsGoalSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type FormData = z.infer<typeof formSchema>;

export default function StashMapRoute() {
  const goals = useLiveQuery(() => db.savingsGoals.toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);

  const householdId = households?.[0]?.id;

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { label: "", targetAmount: 0, currentAmount: 0, monthlyContribution: 0, category: "emergency", priority: "medium", deadline: "" },
  });

  const onSubmit = async (data: FormData) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    
    // Sanitize empty date strings
    const sanitizedData = { ...data };
    if (!sanitizedData.deadline) {
      delete sanitizedData.deadline;
    } else {
      // Ensure it's a valid ISO string if the browser date picker just gives YYYY-MM-DD
      sanitizedData.deadline = new Date(sanitizedData.deadline).toISOString();
    }

    await db.savingsGoals.add({ ...sanitizedData, id: createId(), householdId, createdAt: now, updatedAt: now });
    form.reset();
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Delete this savings goal?")) await db.savingsGoals.delete(id);
  };

  if (!goals) return <div className="p-4 text-muted-foreground">Loading Stash Map data...</div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Stash Map</h1>
        <p className="text-muted-foreground">Plan and track your savings goals and deadlines.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Create Savings Goal</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
              <div className="space-y-2">
                <Label>Label</Label>
                <Input {...form.register("label")} placeholder="e.g. Vacation" />
              </div>
              <div className="space-y-2">
                <Label>Target Amount</Label>
                <Input type="number" step="0.01" {...form.register("targetAmount", { valueAsNumber: true })} />
              </div>
              <div className="space-y-2">
                <Label>Current Amount</Label>
                <Input type="number" step="0.01" {...form.register("currentAmount", { valueAsNumber: true })} />
              </div>
              <div className="space-y-2">
                <Label>Monthly Contribution</Label>
                <Input type="number" step="0.01" {...form.register("monthlyContribution", { valueAsNumber: true })} />
              </div>
              <div className="space-y-2">
                <Label>Deadline (Optional)</Label>
                <Input type="date" {...form.register("deadline")} />
              </div>
              <div className="space-y-2">
                <Label>Category</Label>
                <NativeSelect {...form.register("category")}>
                  <option value="emergency">Emergency</option>
                  <option value="vehicle">Vehicle</option>
                  <option value="home">Home</option>
                  <option value="vacation">Vacation</option>
                  <option value="debt-payoff">Debt Payoff</option>
                  <option value="holiday">Holiday</option>
                  <option value="other">Other</option>
                </NativeSelect>
              </div>
            </div>
            <Button type="submit" disabled={!householdId}>Add Goal</Button>
          </form>
        </CardContent>
      </Card>

      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Active Goals & Forecasts</h2>
        {goals.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-white/20 dark:border-white/10 bg-background/20 backdrop-blur-xl p-8 text-center text-muted-foreground">
            Create your first savings goal to see how long it will take.
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 lg:grid-cols-2 xl:grid-cols-3">
            {goals.map((goal) => {
              const progress = goal.targetAmount > 0 ? Math.min(100, (goal.currentAmount / goal.targetAmount) * 100) : 0;
              const forecast = forecastSavingsGoal(goal.targetAmount, goal.currentAmount, goal.monthlyContribution, goal.deadline);

              return (
                <Card key={goal.id} className={cn(forecast.status === "UNDERFUNDED" ? "border-destructive/50" : "")}>
                  <CardHeader className="pb-2">
                    <div className="flex justify-between items-start">
                      <CardTitle className="text-base">{goal.label}</CardTitle>
                      <span className={cn(
                        "text-[10px] font-bold px-2 py-0.5 rounded-full",
                        forecast.status === "ON_TRACK" ? "bg-green-100 text-green-700" :
                        forecast.status === "UNDERFUNDED" ? "bg-red-100 text-red-700" :
                        forecast.status === "FUNDED" ? "bg-blue-100 text-blue-700" : "bg-gray-100 text-gray-700"
                      )}>
                        {forecast.status.replace("_", " ")}
                      </span>
                    </div>
                    <CardDescription>${goal.currentAmount.toFixed(2)} / ${goal.targetAmount.toFixed(2)}</CardDescription>
                  </CardHeader>
                  <CardContent className="pb-4 space-y-3">
                    <div className="h-2 w-full bg-secondary rounded-full overflow-hidden">
                      <div className={cn("h-full", forecast.status === "UNDERFUNDED" ? "bg-destructive" : "bg-primary")} style={{ width: `${progress}%` }} />
                    </div>
                    <div className="text-sm space-y-1">
                      <div className="flex justify-between">
                        <span className="text-muted-foreground">Planned:</span>
                        <span className="font-medium">${goal.monthlyContribution}/mo</span>
                      </div>
                      
                      {forecast.projectedDate && forecast.status !== "FUNDED" && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Projected Finish:</span>
                          <span className="font-medium">{format(forecast.projectedDate, "MMM yyyy")}</span>
                        </div>
                      )}
                      
                      {goal.deadline && (
                        <div className="flex justify-between">
                          <span className="text-muted-foreground">Deadline:</span>
                          <span className="font-medium">{format(parseISO(goal.deadline), "MMM yyyy")}</span>
                        </div>
                      )}

                      {forecast.status === "UNDERFUNDED" && forecast.requiredMonthlyToHitDeadline !== null && (
                        <div className="flex justify-between text-destructive text-xs font-medium pt-1">
                          <span>Required to hit deadline:</span>
                          <span>${forecast.requiredMonthlyToHitDeadline.toFixed(2)}/mo</span>
                        </div>
                      )}
                    </div>
                  </CardContent>
                  <CardContent className="pt-0">
                    <Button variant="outline" size="sm" className="w-full text-destructive hover:bg-destructive/10 hover:text-destructive border-transparent hover:border-destructive/30" onClick={() => handleDelete(goal.id)}>Delete</Button>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
