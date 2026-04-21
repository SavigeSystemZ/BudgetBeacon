import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { creditSnapshotSchema } from "../modules/credit/credit.schema";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { format, parseISO } from "date-fns";

const formSchema = creditSnapshotSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type FormData = z.infer<typeof formSchema>;

export default function CreditRoute() {
  const snapshots = useLiveQuery(() => db.creditSnapshots.orderBy("snapshotDate").reverse().toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);

  const householdId = households?.[0]?.id;

  const form = useForm({
    resolver: zodResolver(formSchema),
    defaultValues: { score: 700, bureauOrSource: "Experian", model: "FICO 8", snapshotDate: new Date().toISOString().split("T")[0], notes: "" },
  });

  const onSubmit = async (data: FormData) => {
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
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Delete this snapshot?")) await db.creditSnapshots.delete(id);
  };

  if (!snapshots) return <div className="p-4 text-muted-foreground">Loading Credit Snapshots...</div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Credit Snapshot</h1>
        <p className="text-muted-foreground">Manually log your credit score to track health over time securely.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Log Credit Score</CardTitle>
          <CardDescription>Enter your score from your bank or a free bureau report.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-4">
              <div className="space-y-2">
                <Label>Score</Label>
                <Input type="number" {...form.register("score", { valueAsNumber: true })} />
              </div>
              <div className="space-y-2">
                <Label>Source / Bureau</Label>
                <Input {...form.register("bureauOrSource")} placeholder="e.g. Experian, Chase" />
              </div>
              <div className="space-y-2">
                <Label>Model</Label>
                <Input {...form.register("model")} placeholder="e.g. FICO 8" />
              </div>
              <div className="space-y-2">
                <Label>Date</Label>
                <Input type="date" {...form.register("snapshotDate")} />
              </div>
            </div>
            <Button type="submit" disabled={!householdId}>Save Snapshot</Button>
          </form>
        </CardContent>
      </Card>

      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Snapshot History</h2>
        {snapshots.length === 0 ? (
          <div className="rounded-xl border border-dashed p-8 text-center text-muted-foreground">
            No credit score snapshots recorded yet.
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
            {snapshots.map((snap) => (
              <Card key={snap.id}>
                <CardHeader className="pb-2">
                  <div className="flex justify-between items-center">
                    <CardTitle className="text-3xl font-bold">{snap.score}</CardTitle>
                    <span className="text-xs text-muted-foreground bg-secondary px-2 py-1 rounded-md">{snap.bureauOrSource}</span>
                  </div>
                  <CardDescription className="text-xs">
                    {format(parseISO(snap.snapshotDate), "MMM do, yyyy")} • {snap.model || "Unknown Model"}
                  </CardDescription>
                </CardHeader>
                <CardContent className="pt-4">
                  <Button variant="destructive" size="sm" onClick={() => handleDelete(snap.id)}>Delete</Button>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>

      <Card className="bg-muted/30">
        <CardHeader>
          <CardTitle className="text-sm font-medium">Privacy Note</CardTitle>
        </CardHeader>
        <CardContent className="text-xs text-muted-foreground">
          Budget Beacon is 100% offline. We do not integrate with Plaid, Equifax, or any other automated system. You own your financial data.
        </CardContent>
      </Card>
    </div>
  );
}
