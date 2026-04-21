import { useLiveQuery } from "dexie-react-hooks";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { z } from "zod";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { billSchema, debtSchema } from "../modules/pay-path/pay-path.schema";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";

const billFormSchema = billSchema.omit({ id: true, householdId: true, ownerPersonId: true, createdAt: true, updatedAt: true });
type BillFormData = z.infer<typeof billFormSchema>;

const debtFormSchema = debtSchema.omit({ id: true, householdId: true, ownerPersonId: true, createdAt: true, updatedAt: true });
type DebtFormData = z.infer<typeof debtFormSchema>;

export default function PayPathRoute() {
  const bills = useLiveQuery(() => db.bills.toArray(), []);
  const debts = useLiveQuery(() => db.debts.toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);

  const householdId = households?.[0]?.id;

  const billForm = useForm({
    resolver: zodResolver(billFormSchema),
    defaultValues: { label: "", category: "housing", amount: 0, frequency: "monthly", autopay: false, isEssential: true },
  });

  const debtForm = useForm({
    resolver: zodResolver(debtFormSchema),
    defaultValues: { label: "", category: "credit-card", balance: 0, minimumPayment: 0, priority: "medium" },
  });

  const onBillSubmit = async (data: BillFormData) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    await db.bills.add({ ...data, id: createId(), householdId, createdAt: now, updatedAt: now });
    billForm.reset();
  };

  const onDebtSubmit = async (data: DebtFormData) => {
    if (!householdId) return;
    const now = new Date().toISOString();
    await db.debts.add({ ...data, id: createId(), householdId, createdAt: now, updatedAt: now });
    debtForm.reset();
  };

  const handleDeleteBill = async (id: string) => {
    if (window.confirm("Delete this bill?")) await db.bills.delete(id);
  };

  const handleDeleteDebt = async (id: string) => {
    if (window.confirm("Delete this debt?")) await db.debts.delete(id);
  };

  if (!bills || !debts) return <div className="p-4 text-muted-foreground">Loading Pay Path data...</div>;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Pay Path</h1>
        <p className="text-muted-foreground">Manage your required bills and debt minimums here.</p>
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Bills Section */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Add Bill</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={billForm.handleSubmit(onBillSubmit)} className="space-y-4">
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <Label>Label</Label>
                    <Input {...billForm.register("label")} placeholder="e.g. Rent" />
                  </div>
                  <div className="space-y-2">
                    <Label>Amount</Label>
                    <Input type="number" step="0.01" {...billForm.register("amount", { valueAsNumber: true })} />
                  </div>
                  <div className="space-y-2">
                    <Label>Category</Label>
                    <NativeSelect {...billForm.register("category")}>
                      <option value="housing">Housing</option>
                      <option value="utilities">Utilities</option>
                      <option value="food">Food</option>
                      <option value="transportation">Transportation</option>
                      <option value="insurance">Insurance</option>
                      <option value="subscriptions">Subscriptions</option>
                      <option value="medical">Medical</option>
                      <option value="other">Other</option>
                    </NativeSelect>
                  </div>
                  <div className="space-y-2">
                    <Label>Frequency</Label>
                    <NativeSelect {...billForm.register("frequency")}>
                      <option value="monthly">Monthly</option>
                      <option value="annual">Annual</option>
                    </NativeSelect>
                  </div>
                </div>
                <Button type="submit" disabled={!householdId}>Add Bill</Button>
              </form>
            </CardContent>
          </Card>

          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Active Bills</h2>
            {bills.map((bill) => (
              <Card key={bill.id}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base flex justify-between">
                    <span>{bill.label}</span>
                    <span className="text-muted-foreground">${bill.amount} / {bill.frequency}</span>
                  </CardTitle>
                </CardHeader>
                <CardContent className="pt-0">
                  <Button variant="destructive" size="sm" onClick={() => handleDeleteBill(bill.id)}>Delete</Button>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Debts Section */}
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Add Debt</CardTitle>
            </CardHeader>
            <CardContent>
              <form onSubmit={debtForm.handleSubmit(onDebtSubmit)} className="space-y-4">
                <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div className="space-y-2">
                    <Label>Label</Label>
                    <Input {...debtForm.register("label")} placeholder="e.g. Chase Card" />
                  </div>
                  <div className="space-y-2">
                    <Label>Balance</Label>
                    <Input type="number" step="0.01" {...debtForm.register("balance", { valueAsNumber: true })} />
                  </div>
                  <div className="space-y-2">
                    <Label>Minimum Payment</Label>
                    <Input type="number" step="0.01" {...debtForm.register("minimumPayment", { valueAsNumber: true })} />
                  </div>
                  <div className="space-y-2">
                    <Label>Category</Label>
                    <NativeSelect {...debtForm.register("category")}>
                      <option value="credit-card">Credit Card</option>
                      <option value="loan">Loan</option>
                      <option value="auto">Auto</option>
                      <option value="student">Student</option>
                    </NativeSelect>
                  </div>
                </div>
                <Button type="submit" disabled={!householdId}>Add Debt</Button>
              </form>
            </CardContent>
          </Card>

          <div className="space-y-4">
            <h2 className="text-xl font-semibold">Active Debts</h2>
            {debts.map((debt) => (
              <Card key={debt.id}>
                <CardHeader className="pb-2">
                  <CardTitle className="text-base flex justify-between">
                    <span>{debt.label}</span>
                    <span className="text-muted-foreground">Min: ${debt.minimumPayment}</span>
                  </CardTitle>
                  <CardDescription>Balance: ${debt.balance}</CardDescription>
                </CardHeader>
                <CardContent className="pt-0">
                  <Button variant="destructive" size="sm" onClick={() => handleDeleteDebt(debt.id)}>Delete</Button>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
