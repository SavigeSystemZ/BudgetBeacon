import { useState } from "react";
import { db } from "../../db/db";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { createId } from "../../lib/ids/createId";
import { Sparkles, Users } from "lucide-react";

interface OnboardingWizardProps {
  onComplete: () => void;
}

type Step = "welcome" | "household" | "persons" | "balances" | "complete";

export function OnboardingWizard({ onComplete }: OnboardingWizardProps) {
  const [step, setStep] = useState<Step>("welcome");
  const [householdName, setHouseholdName] = useState("My Household");
  const [currency, setCurrency] = useState("USD");
  const [persons, setPersons] = useState([{ name: "Primary Member", role: "primary" }]);
  const [startBalance, setStartBalance] = useState(0);
  const [isProcessing, setIsProcessing] = useState(false);

  const handleAddPerson = () => {
    setPersons([
      ...persons,
      { name: `Member ${persons.length + 1}`, role: "partner" as const },
    ]);
  };

  const handleUpdatePerson = (index: number, field: string, value: string) => {
    const updated = [...persons];
    (updated[index] as any)[field] = value;
    setPersons(updated);
  };

  const handleRemovePerson = (index: number) => {
    setPersons(persons.filter((_, i) => i !== index));
  };

  const handleComplete = async () => {
    setIsProcessing(true);
    try {
      const householdId = createId();
      const now = new Date().toISOString();

      // Create household
      await db.households.add({
        id: householdId,
        name: householdName,
        currency,
        createdAt: now,
        updatedAt: now,
      });

      // Create persons
      for (const person of persons) {
        await db.persons.add({
          id: createId(),
          householdId,
          name: person.name,
          role: person.role as "primary" | "partner" | "other",
          createdAt: now,
          updatedAt: now,
        });
      }

      // If user chose non-zero starting balance, create a seed transaction
      if (startBalance !== 0) {
        await db.transactions.add({
          id: createId(),
          householdId,
          date: now, // ISO datetime
          amount: Math.abs(startBalance),
          category: "transfer",
          type: startBalance > 0 ? "income" : "expense",
          payee: "Opening Balance",
          notes: "Starting balance for budget",
          createdAt: now,
          updatedAt: now,
        });
      }

      setStep("complete");
      setTimeout(onComplete, 2000);
    } catch (err) {
      console.error("Setup error:", err);
      setIsProcessing(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-gradient-to-br from-background via-background/95 to-background/80 backdrop-blur-xl z-50 flex items-center justify-center p-4 overflow-auto">
      <Card className="w-full max-w-2xl border-primary/20 shadow-2xl my-8">
        <CardHeader className="bg-gradient-to-r from-primary/10 to-primary/5">
          <div className="flex items-center gap-3">
            <Sparkles className="h-6 w-6 text-primary" />
            <div>
              <CardTitle>Budget Beacon Setup</CardTitle>
              <CardDescription>Configure your household budget in a few steps</CardDescription>
            </div>
          </div>
        </CardHeader>
        <CardContent className="pt-8 pb-8">
          {/* Welcome Step */}
          {step === "welcome" && (
            <div className="space-y-6">
              <div className="space-y-3">
                <h3 className="font-semibold text-lg">Welcome to Budget Beacon</h3>
                <p className="text-sm text-muted-foreground">
                  Let's set up your budget tracking. You can choose to start with zero balances or seed with an initial amount.
                </p>
              </div>
              <Button onClick={() => setStep("household")} className="w-full" size="lg">
                Get Started →
              </Button>
            </div>
          )}

          {/* Household Step */}
          {step === "household" && (
            <div className="space-y-6">
              <div className="space-y-4">
                <div>
                  <Label>Household Name</Label>
                  <Input
                    value={householdName}
                    onChange={(e) => setHouseholdName(e.target.value)}
                    placeholder="e.g., Smith Family"
                  />
                </div>
                <div>
                  <Label>Currency</Label>
                  <select
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value)}
                    className="flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                  >
                    <option value="USD">USD ($)</option>
                    <option value="EUR">EUR (€)</option>
                    <option value="GBP">GBP (£)</option>
                    <option value="CAD">CAD (C$)</option>
                    <option value="AUD">AUD (A$)</option>
                  </select>
                </div>
              </div>
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setStep("welcome")} className="flex-1">
                  ← Back
                </Button>
                <Button onClick={() => setStep("persons")} className="flex-1">
                  Next →
                </Button>
              </div>
            </div>
          )}

          {/* Persons Step */}
          {step === "persons" && (
            <div className="space-y-6">
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h4 className="font-semibold flex items-center gap-2">
                    <Users className="h-4 w-4" />
                    Household Members
                  </h4>
                  <Button variant="outline" size="sm" onClick={handleAddPerson}>
                    + Add
                  </Button>
                </div>
                <div className="space-y-3 max-h-64 overflow-y-auto">
                  {persons.map((person, idx) => (
                    <div key={idx} className="flex gap-2 p-3 bg-muted/50 rounded-lg border border-border/50">
                      <div className="flex-1 space-y-2">
                        <Input
                          placeholder="Name"
                          value={person.name}
                          onChange={(e) => handleUpdatePerson(idx, "name", e.target.value)}
                        />
                        <select
                          value={person.role}
                          onChange={(e) => handleUpdatePerson(idx, "role", e.target.value)}
                          className="flex h-9 w-full rounded-md border border-input bg-background px-3 py-1 text-sm"
                        >
                          <option value="primary">Primary</option>
                          <option value="partner">Partner</option>
                          <option value="other">Other</option>
                        </select>
                      </div>
                      {persons.length > 1 && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemovePerson(idx)}
                          className="self-center text-destructive"
                        >
                          ✕
                        </Button>
                      )}
                    </div>
                  ))}
                </div>
              </div>
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setStep("household")} className="flex-1">
                  ← Back
                </Button>
                <Button onClick={() => setStep("balances")} className="flex-1">
                  Next →
                </Button>
              </div>
            </div>
          )}

          {/* Balances Step */}
          {step === "balances" && (
            <div className="space-y-6">
              <div className="space-y-4">
                <div>
                  <Label>Starting Balance (Optional)</Label>
                  <p className="text-xs text-muted-foreground mb-2">
                    Enter an initial account balance. Leave as 0 to start fresh.
                  </p>
                  <Input
                    type="number"
                    value={startBalance}
                    onChange={(e) => setStartBalance(Number(e.target.value))}
                    placeholder="0.00"
                    step="0.01"
                  />
                </div>
                <div className="p-4 bg-primary/5 rounded-lg border border-primary/10 text-sm">
                  <p className="font-semibold mb-2">Zero Balance Strategy</p>
                  <p className="text-xs text-muted-foreground">
                    Start with $0 to manually build your budget line-by-line. This is recommended if you want to carefully track every transaction from the beginning.
                  </p>
                </div>
              </div>
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setStep("persons")} className="flex-1">
                  ← Back
                </Button>
                <Button
                  onClick={handleComplete}
                  disabled={isProcessing}
                  className="flex-1"
                >
                  {isProcessing ? "Setting up..." : "Create Household →"}
                </Button>
              </div>
            </div>
          )}

          {/* Complete Step */}
          {step === "complete" && (
            <div className="space-y-4 text-center">
              <div className="h-16 w-16 rounded-full bg-green-500/20 flex items-center justify-center mx-auto">
                <Sparkles className="h-8 w-8 text-green-500" />
              </div>
              <h3 className="font-semibold text-lg">Setup Complete!</h3>
              <p className="text-sm text-muted-foreground">
                Your household is ready. Opening Budget Beacon...
              </p>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
