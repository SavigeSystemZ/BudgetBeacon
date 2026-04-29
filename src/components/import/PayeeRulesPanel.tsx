import { useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db, type PayeeRule } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import { CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { NativeSelect } from "../ui/native-select";
import { GlassCard } from "../ui/GlassCard";
import { Plus, Trash2, Tags } from "lucide-react";

const CATEGORIES = [
  { value: "", label: "(no category change)" },
  { value: "housing", label: "Housing" },
  { value: "utilities", label: "Utilities" },
  { value: "food", label: "Food / Groceries" },
  { value: "transportation", label: "Transportation" },
  { value: "insurance", label: "Insurance" },
  { value: "subscriptions", label: "Subscriptions" },
  { value: "medical", label: "Medical" },
  { value: "other", label: "Other" },
];

interface Props {
  householdId: string | undefined;
}

/**
 * UI for managing payee normalization rules. Rules are applied during CSV
 * import (and any future bank-aggregator transactions). First-match wins;
 * order = creation order. The user can rename payees and assign categories.
 */
export function PayeeRulesPanel({ householdId }: Props) {
  const rules = useLiveQuery(
    () => (householdId ? db.payeeRules.where("householdId").equals(householdId).toArray() : []),
    [householdId],
  ) || [];

  const [pattern, setPattern] = useState("");
  const [matchType, setMatchType] = useState<"contains" | "exact">("contains");
  const [override, setOverride] = useState("");
  const [category, setCategory] = useState("");

  const handleAdd = async () => {
    if (!householdId) return;
    const trimmed = pattern.trim();
    if (!trimmed) return;
    const now = new Date().toISOString();
    const rule: PayeeRule = {
      id: createId(),
      householdId,
      pattern: trimmed,
      matchType,
      payeeOverride: override.trim() || undefined,
      category: category || undefined,
      createdAt: now,
      updatedAt: now,
    };
    await db.payeeRules.add(rule);
    setPattern("");
    setOverride("");
    setCategory("");
  };

  return (
    <GlassCard className="border-primary/10">
      <CardHeader className="bg-primary/5">
        <CardTitle className="flex items-center gap-2">
          <Tags className="h-5 w-5" /> Payee Rules
        </CardTitle>
        <CardDescription>
          Auto-categorize and rename merchants on every CSV import. First match wins; rules apply in creation order.
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6 space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="pr-pattern" className="text-[10px] uppercase font-black tracking-widest opacity-70">Match pattern</Label>
            <Input
              id="pr-pattern"
              value={pattern}
              onChange={(e) => setPattern(e.target.value)}
              placeholder='e.g. "amzn mktp" or "starbucks"'
              className="bg-primary/5 border-none font-bold h-12"
            />
            <p className="text-[10px] text-muted-foreground">Case-insensitive; punctuation ignored.</p>
          </div>
          <div className="space-y-2">
            <Label htmlFor="pr-match" className="text-[10px] uppercase font-black tracking-widest opacity-70">Match type</Label>
            <NativeSelect
              id="pr-match"
              value={matchType}
              onChange={(e) => setMatchType(e.target.value as "contains" | "exact")}
              className="bg-primary/5 border-none font-bold h-12"
            >
              <option value="contains">Contains</option>
              <option value="exact">Exact</option>
            </NativeSelect>
          </div>
          <div className="space-y-2">
            <Label htmlFor="pr-cat" className="text-[10px] uppercase font-black tracking-widest opacity-70">Category</Label>
            <NativeSelect
              id="pr-cat"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              className="bg-primary/5 border-none font-bold h-12"
            >
              {CATEGORIES.map((c) => (
                <option key={c.value} value={c.value}>{c.label}</option>
              ))}
            </NativeSelect>
          </div>
          <div className="space-y-2 md:col-span-2">
            <Label htmlFor="pr-override" className="text-[10px] uppercase font-black tracking-widest opacity-70">Rename payee to (optional)</Label>
            <Input
              id="pr-override"
              value={override}
              onChange={(e) => setOverride(e.target.value)}
              placeholder='e.g. "Amazon"'
              className="bg-primary/5 border-none font-bold h-12"
            />
          </div>
        </div>
        <Button onClick={handleAdd} disabled={!householdId || !pattern.trim()} className="gap-2">
          <Plus className="h-4 w-4" /> Add rule
        </Button>

        {rules.length > 0 && (
          <div className="space-y-2 pt-4 border-t border-primary/5">
            <h3 className="text-[10px] font-black uppercase tracking-widest opacity-70">Active rules ({rules.length})</h3>
            <ul className="space-y-2">
              {rules.map((r) => (
                <li key={r.id} className="flex items-center gap-3 p-3 rounded-xl bg-card/50 border border-primary/5">
                  <div className="flex-1 min-w-0">
                    <div className="text-[12px] font-black tracking-tight truncate">
                      <span className="text-primary">{r.matchType === "exact" ? "≡" : "⊃"}</span> {r.pattern}
                    </div>
                    <div className="text-[10px] text-muted-foreground truncate">
                      {r.payeeOverride && <>→ <span className="font-bold">{r.payeeOverride}</span></>}
                      {r.payeeOverride && r.category ? "  ·  " : ""}
                      {r.category && <span className="uppercase tracking-widest">{r.category}</span>}
                      {!r.payeeOverride && !r.category && <em>no overrides</em>}
                    </div>
                  </div>
                  <Button variant="ghost" size="icon" onClick={() => db.payeeRules.delete(r.id)} className="h-8 w-8 text-destructive shrink-0">
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </li>
              ))}
            </ul>
          </div>
        )}
      </CardContent>
    </GlassCard>
  );
}
