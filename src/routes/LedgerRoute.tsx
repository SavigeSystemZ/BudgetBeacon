import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { transactionSchema } from "../modules/ledger/ledger.schema";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { format, parseISO } from "date-fns";
import { cn } from "../lib/utils";

const formSchema = transactionSchema.omit({ id: true, householdId: true, createdAt: true, updatedAt: true });
type FormData = z.infer<typeof formSchema>;

export default function LedgerRoute() {
  const transactions = useLiveQuery(() => db.transactions.orderBy("date").reverse().toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);

  const householdId = households?.[0]?.id;

  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      amount: 0,
      date: new Date().toISOString().split("T")[0],
      payee: "",
      category: "food",
      type: "expense",
      notes: ""
    },
  });

  const onSubmit = async (data: FormData) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    
    await db.transactions.add({
      ...data,
      date: new Date(data.date).toISOString(), // Ensure ISO format
      id: createId(),
      householdId,
      createdAt: now,
      updatedAt: now,
    });
    form.reset({
      amount: 0,
      date: new Date().toISOString().split("T")[0],
      payee: "",
      category: "food",
      type: "expense",
      notes: ""
    });
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Delete this transaction?")) await db.transactions.delete(id);
  };

  if (!transactions) return <div className="p-4 text-muted-foreground">Loading Ledger...</div>;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Ledger</h1>
        <p className="text-muted-foreground">Log your actual daily spending and income.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Add Transaction</CardTitle>
          <CardDescription>Record an expense or additional income.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-6">
              <div className="space-y-2 lg:col-span-1">
                <Label>Type</Label>
                <NativeSelect {...form.register("type")}>
                  <option value="expense">Expense</option>
                  <option value="income">Income</option>
                </NativeSelect>
              </div>
              <div className="space-y-2 lg:col-span-1">
                <Label>Date</Label>
                <Input type="date" {...form.register("date")} />
              </div>
              <div className="space-y-2 lg:col-span-2">
                <Label>Payee / Source</Label>
                <Input {...form.register("payee")} placeholder="e.g. Target, Chevron" />
              </div>
              <div className="space-y-2 lg:col-span-1">
                <Label>Amount</Label>
                <Input type="number" step="0.01" {...form.register("amount", { valueAsNumber: true })} />
              </div>
              <div className="space-y-2 lg:col-span-1">
                <Label>Category</Label>
                <NativeSelect {...form.register("category")}>
                  <option value="housing">Housing</option>
                  <option value="utilities">Utilities</option>
                  <option value="food">Food</option>
                  <option value="transportation">Transportation</option>
                  <option value="personal">Personal / Fun</option>
                  <option value="subscriptions">Subscriptions</option>
                  <option value="medical">Medical</option>
                  <option value="other">Other</option>
                </NativeSelect>
              </div>
            </div>
            <Button type="submit" disabled={!householdId}>Save Transaction</Button>
          </form>
        </CardContent>
      </Card>

      <div className="space-y-4">
        <h2 className="text-xl font-semibold">Recent Transactions</h2>
        {transactions.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-white/20 dark:border-white/10 bg-background/20 backdrop-blur-xl p-8 text-center text-muted-foreground">
            No transactions logged yet. Start tracking your spending above.
          </div>
        ) : (
          <div className="space-y-3">
            {transactions.map((t) => (
              <Card key={t.id} className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="flex flex-col">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-lg">{t.payee}</span>
                    <span className="text-xs px-2 py-0.5 bg-secondary/50 rounded-full capitalize">{t.category}</span>
                  </div>
                  <span className="text-sm text-muted-foreground">{format(parseISO(t.date), "MMM do, yyyy")}</span>
                </div>
                <div className="flex items-center justify-between sm:justify-end gap-6 w-full sm:w-auto">
                  <span className={cn(
                    "text-xl font-bold",
                    t.type === "expense" ? "text-foreground" : "text-green-500"
                  )}>
                    {t.type === "expense" ? "-" : "+"}${t.amount.toFixed(2)}
                  </span>
                  <Button variant="ghost" size="sm" onClick={() => handleDelete(t.id)} className="text-destructive hover:bg-destructive/10 hover:text-destructive">Delete</Button>
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
