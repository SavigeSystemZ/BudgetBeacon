import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { incomeSourceSchema } from "../modules/income/income.schema";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";

const formSchema = incomeSourceSchema.omit({ id: true, householdId: true, personId: true, createdAt: true, updatedAt: true });
type FormData = z.infer<typeof formSchema>;

export default function IncomeRoute() {
  const incomes = useLiveQuery(() => db.incomeSources.toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);

  const householdId = households?.[0]?.id; // Default to first household for MVP
  const personId = persons?.[0]?.id;

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: {
      label: "",
      amount: 0,
      frequency: "monthly",
      isActive: true,
    },
  });

  const onSubmit = async (data: FormData) => {
    if (!householdId) return; // Wait until demo data is seeded

    const now = new Date().toISOString();
    await db.incomeSources.add({
      ...data,
      id: createId(),
      householdId,
      personId,
      createdAt: now,
      updatedAt: now,
    });
    form.reset();
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Are you sure you want to delete this income source?")) {
      await db.incomeSources.delete(id);
    }
  };

  if (!incomes) return <div className="p-4 text-muted-foreground">Loading income data...</div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Income</h1>
        <p className="text-muted-foreground">Manage your household income streams here.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add Income Source</CardTitle>
          <CardDescription>Enter a new recurring income amount.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="label">Label (e.g., Tech Job)</Label>
                <Input id="label" {...form.register("label")} placeholder="Main Salary" />
                {form.formState.errors.label && (
                  <p className="text-sm text-destructive">{form.formState.errors.label.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="amount">Amount</Label>
                <Input id="amount" type="number" step="0.01" {...form.register("amount", { valueAsNumber: true })} />
                {form.formState.errors.amount && (
                  <p className="text-sm text-destructive">{form.formState.errors.amount.message}</p>
                )}
              </div>
              <div className="space-y-2">
                <Label htmlFor="frequency">Frequency</Label>
                <NativeSelect id="frequency" {...form.register("frequency")}>
                  <option value="weekly">Weekly</option>
                  <option value="biweekly">Bi-weekly</option>
                  <option value="semimonthly">Semi-monthly</option>
                  <option value="monthly">Monthly</option>
                  <option value="annual">Annual</option>
                  <option value="custom">Custom</option>
                </NativeSelect>
              </div>
            </div>
            <Button type="submit" disabled={!householdId}>Add Income</Button>
            {!householdId && <p className="text-xs text-muted-foreground mt-2">Waiting for household setup...</p>}
          </form>
        </CardContent>
      </Card>

      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Active Incomes</h2>
        {incomes.length === 0 ? (
          <div className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
            Add your first income source so Budget Beacon can calculate what you have available.
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {incomes.map((inc) => (
              <Card key={inc.id}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base flex justify-between">
                    <span>{inc.label}</span>
                    <span className="text-muted-foreground font-normal text-sm capitalize">{inc.frequency}</span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="pb-4">
                  <div className="text-2xl font-bold">${inc.amount.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</div>
                </CardContent>
                <CardContent className="pt-0">
                  <Button variant="destructive" size="sm" onClick={() => handleDelete(inc.id)}>Delete</Button>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
