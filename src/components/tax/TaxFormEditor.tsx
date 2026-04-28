import { useState, useEffect } from "react";
import { db } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import { CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { GlassCard } from "../ui/GlassCard";
import { FileCheck } from "lucide-react";
import type { TaxFormDef } from "../../modules/tax/formDefs";

interface Props {
  def: TaxFormDef;
  year: number;
  personId: string;
  /** When set, edit an existing record instead of creating a new one. */
  existingId?: string;
  initialData?: Record<string, unknown>;
  onSaved: () => void;
  onCancel: () => void;
}

export function TaxFormEditor({ def, year, personId, existingId, initialData, onSaved, onCancel }: Props) {
  const [values, setValues] = useState<Record<string, string>>({});
  const [missing, setMissing] = useState<string[]>([]);

  useEffect(() => {
    const seed: Record<string, string> = {};
    for (const f of def.fields) {
      const raw = initialData?.[f.key];
      seed[f.key] = raw == null ? "" : String(raw);
    }
    setValues(seed);
    setMissing([]);
  }, [def, initialData]);

  const setField = (key: string, val: string) => {
    setValues((prev) => ({ ...prev, [key]: val }));
  };

  const handleSave = async () => {
    const missingFields = def.fields.filter((f) => f.required && !values[f.key]?.trim()).map((f) => f.key);
    if (missingFields.length) {
      setMissing(missingFields);
      return;
    }

    // Coerce numeric/currency fields to numbers; keep strings as-is.
    const data: Record<string, unknown> = {};
    for (const f of def.fields) {
      const raw = values[f.key]?.trim();
      if (raw === undefined || raw === "") continue;
      if (f.type === "number" || f.type === "currency") {
        const n = parseFloat(raw.replace(/[, $]/g, ""));
        data[f.key] = Number.isFinite(n) ? n : raw;
      } else {
        data[f.key] = raw;
      }
    }

    const now = new Date().toISOString();
    const id = existingId || createId();
    await db.taxForms.put({ id, year, type: def.code, data, updatedAt: now, personId });
    onSaved();
  };

  return (
    <GlassCard intensity="high" className="border-primary/20 shadow-2xl animate-in zoom-in-95">
      <CardHeader className="border-b border-primary/10 bg-primary/5">
        <div className="flex justify-between items-center">
          <div>
            <CardTitle className="text-2xl font-black uppercase italic tracking-tighter">{def.title}</CardTitle>
            <CardDescription className="text-[10px] font-bold uppercase tracking-widest">{def.description} • TY{year}</CardDescription>
          </div>
          <FileCheck className="h-10 w-10 text-primary opacity-20" />
        </div>
      </CardHeader>
      <CardContent className="pt-8 space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          {def.fields.map((f) => (
            <div key={f.key} className="space-y-2">
              <Label htmlFor={`tf-${f.key}`} className="text-[10px] font-black uppercase tracking-widest opacity-60 px-1">
                {f.label}{f.required ? <span className="text-destructive ml-1">*</span> : null}
              </Label>
              <Input
                id={`tf-${f.key}`}
                type={f.type === "number" || f.type === "currency" ? "number" : "text"}
                inputMode={f.type === "currency" || f.type === "number" ? "decimal" : "text"}
                step={f.type === "currency" ? "0.01" : undefined}
                value={values[f.key] || ""}
                onChange={(e) => setField(f.key, e.target.value)}
                placeholder={f.helper}
                className={`bg-primary/5 border-none font-black h-12 ${missing.includes(f.key) ? "ring-2 ring-destructive" : ""}`}
              />
              {missing.includes(f.key) && (
                <p role="alert" className="text-[10px] font-bold text-destructive">Required.</p>
              )}
            </div>
          ))}
        </div>
        <div className="pt-6 border-t border-primary/5 flex justify-end gap-3">
          <Button variant="ghost" onClick={onCancel} className="h-12 px-8 uppercase font-black italic text-xs tracking-widest">Cancel</Button>
          <Button onClick={handleSave} className="h-12 px-10 uppercase font-black italic text-xs tracking-widest shadow-xl shadow-primary/20">
            {existingId ? "Update form" : "Save form"}
          </Button>
        </div>
      </CardContent>
    </GlassCard>
  );
}
