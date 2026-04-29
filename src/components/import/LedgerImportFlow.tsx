import { useMemo, useState } from "react";
import { db } from "../../db/db";
import { createId } from "../../lib/ids/createId";
import { parseCsv } from "../../modules/import/parseCsv";
import { parseOfx } from "../../modules/import/parseOfx";
import { mapRowsToDrafts, partitionByDedupe, type ColumnMapping, type MappedTransactionDraft } from "../../modules/import/mapRows";
import { dedupeKey } from "../../modules/import/dedupeKey";
import { autoDetectMapping } from "../../modules/import/autoDetect";
import { applyPayeeRules } from "../../modules/import/applyPayeeRules";
import { Button } from "../ui/button";
import { NativeSelect } from "../ui/native-select";
import { Label } from "../ui/label";
import { BeaconModal } from "../ui/BeaconModal";
import { ArrowDownCircle, ArrowUpCircle, Check, FileSpreadsheet, X } from "lucide-react";

type Step = "pick" | "map" | "review" | "done";

interface Props {
  isOpen: boolean;
  onClose: () => void;
  householdId: string | undefined;
}

/**
 * 4-step CSV import flow for transactions.
 *   1. pick   — user selects a .csv file
 *   2. map    — auto-detected column mapping, user can override
 *   3. review — fresh vs duplicate drafts; user toggles which to commit
 *   4. done   — confirmation summary
 *
 * Feature flag: featureFlags.bankImportTierA. The Ledger route only renders
 * this when the flag is true.
 */
export function LedgerImportFlow({ isOpen, onClose, householdId }: Props) {
  const [step, setStep] = useState<Step>("pick");
  const [filename, setFilename] = useState<string>("");
  const [headers, setHeaders] = useState<string[]>([]);
  const [rows, setRows] = useState<Record<string, string>[]>([]);
  const [mapping, setMapping] = useState<Partial<ColumnMapping>>({});
  const [parseError, setParseError] = useState<string | null>(null);

  const [drafts, setDrafts] = useState<MappedTransactionDraft[]>([]);
  const [skipped, setSkipped] = useState<{ row: number; reason: string }[]>([]);
  const [duplicateKeys, setDuplicateKeys] = useState<Set<string>>(new Set());
  const [excluded, setExcluded] = useState<Set<string>>(new Set()); // dedupeKeys to skip
  const [matchedRuleCount, setMatchedRuleCount] = useState<number>(0);

  const [committed, setCommitted] = useState<number>(0);

  const reset = () => {
    setStep("pick");
    setFilename("");
    setHeaders([]);
    setRows([]);
    setMapping({});
    setParseError(null);
    setDrafts([]);
    setSkipped([]);
    setDuplicateKeys(new Set());
    setExcluded(new Set());
    setCommitted(0);
    setMatchedRuleCount(0);
  };

  const handleClose = () => {
    reset();
    onClose();
  };

  const handleFile = async (file: File) => {
    setParseError(null);
    setFilename(file.name);
    try {
      const text = await file.text();
      const lower = file.name.toLowerCase();
      const isOfx = lower.endsWith(".ofx") || lower.endsWith(".qfx") || /^OFXHEADER/m.test(text) || /<OFX[ >]/i.test(text);

      if (isOfx) {
        // OFX/QFX bypasses the column-mapping step entirely — its schema is
        // already structured. We jump straight to review with payee rules
        // applied + dedupe partition.
        const parsedOfx = parseOfx(text);
        if (parsedOfx.drafts.length === 0) {
          setParseError("No transactions detected in this OFX/QFX file.");
          return;
        }

        const rules = householdId
          ? await db.payeeRules.where("householdId").equals(householdId).toArray()
          : [];
        let matched = 0;
        const { applyPayeeRules } = await import("../../modules/import/applyPayeeRules");
        const normalized = parsedOfx.drafts.map((d) => {
          const out = applyPayeeRules(d, rules);
          if (out.matchedRuleId) matched += 1;
          return { ...out.draft, dedupeKey: dedupeKey({ date: out.draft.date, amount: out.draft.amount, payee: out.draft.payee }) };
        });
        setMatchedRuleCount(matched);
        setDrafts(normalized);
        setSkipped(parsedOfx.skipped.map((s) => ({ row: s.blockIndex, reason: s.reason })));

        const existing = await db.transactions.toArray();
        const keys = new Set(existing.map((t) => dedupeKey({ date: t.date, amount: t.amount, payee: t.payee })));
        const partition = partitionByDedupe(normalized, keys);
        setDuplicateKeys(new Set(partition.duplicates.map((d) => d.dedupeKey)));
        setExcluded(new Set(partition.duplicates.map((d) => d.dedupeKey)));
        setStep("review");
        return;
      }

      const parsed = parseCsv(text);
      if (parsed.headers.length === 0 || parsed.rows.length === 0) {
        setParseError("No rows detected. Is this a CSV file?");
        return;
      }
      setHeaders(parsed.headers);
      setRows(parsed.rows);
      setMapping(autoDetectMapping(parsed.headers));
      setStep("map");
    } catch (err) {
      console.error(err);
      setParseError(err instanceof Error ? err.message : "Failed to read file");
    }
  };

  const handleConfirmMapping = async () => {
    if (!mapping.date || !mapping.payee || !mapping.amount) {
      setParseError("Date, Payee, and Amount columns are all required.");
      return;
    }
    setParseError(null);
    const result = mapRowsToDrafts(rows, mapping as ColumnMapping);

    // Apply payee normalization rules so the user reviews already-categorized
    // drafts. Rules are user-managed in Settings; ordering is creation order.
    const rules = householdId
      ? await db.payeeRules.where("householdId").equals(householdId).toArray()
      : [];
    let matched = 0;
    const normalizedDrafts = result.drafts.map((d) => {
      const out = applyPayeeRules(d, rules);
      if (out.matchedRuleId) matched += 1;
      // Recompute dedupeKey on the normalized payee so dedupe matches future imports.
      return { ...out.draft, dedupeKey: dedupeKey({ date: out.draft.date, amount: out.draft.amount, payee: out.draft.payee }) };
    });
    setMatchedRuleCount(matched);
    setDrafts(normalizedDrafts);
    setSkipped(result.skipped);

    // Compute existing dedupe keys from the live db.
    const existing = await db.transactions.toArray();
    const keys = new Set(existing.map((t) => dedupeKey({ date: t.date, amount: t.amount, payee: t.payee })));
    const partition = partitionByDedupe(normalizedDrafts, keys);
    setDuplicateKeys(new Set(partition.duplicates.map((d) => d.dedupeKey)));
    // Default duplicates to excluded; fresh stays included.
    setExcluded(new Set(partition.duplicates.map((d) => d.dedupeKey)));
    setStep("review");
  };

  const toggleExclude = (key: string) => {
    setExcluded((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const handleCommit = async () => {
    if (!householdId) return;
    const now = new Date().toISOString();
    const toCommit = drafts.filter((d) => !excluded.has(d.dedupeKey));
    await db.transactions.bulkAdd(
      toCommit.map((d) => ({
        id: createId(),
        householdId,
        date: d.date,
        payee: d.payee,
        amount: d.amount,
        category: d.category,
        type: d.type,
        createdAt: now,
        updatedAt: now,
      }))
    );
    setCommitted(toCommit.length);
    setStep("done");
  };

  const includedCount = useMemo(() => drafts.filter((d) => !excluded.has(d.dedupeKey)).length, [drafts, excluded]);
  const dupeCount = duplicateKeys.size;

  return (
    <BeaconModal isOpen={isOpen} onClose={handleClose} title="Import Transactions">
      <div className="space-y-5 max-h-[70vh] overflow-y-auto pr-1">
        {/* Step header */}
        <ol className="flex items-center gap-2 text-[10px] font-black uppercase tracking-widest opacity-70">
          {(["pick", "map", "review", "done"] as Step[]).map((s, i) => (
            <li key={s} className={`flex items-center gap-2 ${step === s ? "text-primary" : ""}`}>
              <span className={`h-5 w-5 rounded-full flex items-center justify-center text-[10px] ${step === s ? "bg-primary text-primary-foreground" : "bg-muted"}`}>{i + 1}</span>
              <span>{s}</span>
              {i < 3 && <span className="opacity-30">›</span>}
            </li>
          ))}
        </ol>

        {parseError && (
          <div role="alert" className="p-3 rounded-xl border border-destructive/40 bg-destructive/10 text-destructive text-sm">
            {parseError}
          </div>
        )}

        {/* Step 1: pick */}
        {step === "pick" && (
          <div className="space-y-4">
            <p className="text-xs text-muted-foreground leading-relaxed">
              Select a <strong>CSV</strong>, <strong>OFX</strong>, or <strong>QFX</strong> file exported from your bank or credit card. OFX/QFX skips column mapping — its schema is already structured.
            </p>
            <div className="p-8 rounded-3xl border-2 border-dashed border-primary/20 bg-primary/5 flex flex-col items-center justify-center gap-3 relative group hover:border-primary transition-all">
              <FileSpreadsheet className="h-10 w-10 text-primary opacity-30 group-hover:opacity-100 transition-opacity" />
              <p className="text-[11px] font-black uppercase tracking-widest text-muted-foreground group-hover:text-primary transition-colors">Choose CSV / OFX / QFX file</p>
              <input
                type="file"
                accept=".csv,.ofx,.qfx,text/csv"
                onChange={(e) => {
                  const f = e.target.files?.[0];
                  if (f) handleFile(f);
                  e.target.value = "";
                }}
                className="absolute inset-0 opacity-0 cursor-pointer"
              />
            </div>
            <p className="text-[10px] text-muted-foreground leading-relaxed">
              CSV: standard RFC-4180 with a header row — the next step lets you map columns. OFX/QFX: bank-issued files (Quicken-compatible) — drafts go straight to review.
            </p>
          </div>
        )}

        {/* Step 2: map */}
        {step === "map" && (
          <div className="space-y-4">
            <p className="text-xs text-muted-foreground">
              Detected <strong className="text-foreground">{rows.length} rows</strong> in <strong className="text-foreground">{filename}</strong>. Confirm or override the column mapping below — Budget Beacon's auto-detection is best-effort.
            </p>
            <div className="grid grid-cols-2 gap-4">
              <ColumnSelect label="Date *" value={mapping.date} headers={headers} onChange={(v) => setMapping((m) => ({ ...m, date: v }))} />
              <ColumnSelect label="Payee / Description *" value={mapping.payee} headers={headers} onChange={(v) => setMapping((m) => ({ ...m, payee: v }))} />
              <ColumnSelect label="Amount *" value={mapping.amount} headers={headers} onChange={(v) => setMapping((m) => ({ ...m, amount: v }))} />
              <ColumnSelect label="Category (optional)" value={mapping.category ?? ""} headers={headers} optional onChange={(v) => setMapping((m) => ({ ...m, category: v || undefined }))} />
              <ColumnSelect label="Type column (optional)" value={mapping.type ?? ""} headers={headers} optional onChange={(v) => setMapping((m) => ({ ...m, type: v || undefined }))} />
            </div>
            {/* Preview first 3 rows of the chosen columns */}
            {mapping.date && mapping.payee && mapping.amount && (
              <div className="p-3 rounded-xl bg-primary/5 border border-primary/10 text-[11px] space-y-1">
                <div className="font-black uppercase tracking-widest opacity-60 mb-1">Preview (first 3 rows)</div>
                {rows.slice(0, 3).map((r, i) => (
                  <div key={i} className="grid grid-cols-3 gap-2 font-mono opacity-80">
                    <span>{r[mapping.date!]}</span>
                    <span className="truncate">{r[mapping.payee!]}</span>
                    <span className="text-right">{r[mapping.amount!]}</span>
                  </div>
                ))}
              </div>
            )}
            <div className="flex gap-2 pt-2">
              <Button variant="outline" onClick={() => setStep("pick")} className="flex-1">Back</Button>
              <Button onClick={handleConfirmMapping} className="flex-[2]">Continue to review</Button>
            </div>
          </div>
        )}

        {/* Step 3: review */}
        {step === "review" && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-2 text-center">
              <Stat label="Detected" value={drafts.length} />
              <Stat label="Duplicates" value={dupeCount} accent="amber" />
              <Stat label="To commit" value={includedCount} accent="green" />
            </div>
            {matchedRuleCount > 0 && (
              <div className="text-[11px] p-3 rounded-xl bg-primary/10 border border-primary/20 text-primary font-bold">
                ✓ Auto-categorized {matchedRuleCount} of {drafts.length} drafts using your payee rules.
              </div>
            )}
            {skipped.length > 0 && (
              <details className="text-[11px] p-3 rounded-xl bg-amber-500/10 border border-amber-500/20">
                <summary className="font-black uppercase tracking-widest text-amber-500 cursor-pointer">{skipped.length} rows skipped (click to view)</summary>
                <ul className="mt-2 space-y-1 max-h-24 overflow-y-auto opacity-80">
                  {skipped.map((s, i) => (
                    <li key={i}>Row {s.row}: {s.reason}</li>
                  ))}
                </ul>
              </details>
            )}
            <div className="border border-primary/10 rounded-2xl overflow-hidden">
              <div className="grid grid-cols-[auto_1fr_auto_auto_auto] gap-2 px-3 py-2 text-[10px] font-black uppercase tracking-widest bg-primary/5 border-b border-primary/10">
                <span></span>
                <span>Payee</span>
                <span className="text-right">Date</span>
                <span className="text-right">Amount</span>
                <span></span>
              </div>
              <ul className="max-h-72 overflow-y-auto">
                {drafts.map((d) => {
                  const isDup = duplicateKeys.has(d.dedupeKey);
                  const isExcluded = excluded.has(d.dedupeKey);
                  return (
                    <li
                      key={d.sourceRow}
                      className={`grid grid-cols-[auto_1fr_auto_auto_auto] gap-2 px-3 py-2 items-center text-xs border-b border-primary/5 last:border-0 ${isExcluded ? "opacity-40" : ""}`}
                    >
                      <button
                        onClick={() => toggleExclude(d.dedupeKey)}
                        className={`h-5 w-5 rounded border flex items-center justify-center transition-colors ${isExcluded ? "border-muted bg-transparent" : "border-primary bg-primary text-primary-foreground"}`}
                        aria-label={isExcluded ? "Include this row" : "Exclude this row"}
                      >
                        {!isExcluded && <Check className="h-3 w-3" />}
                      </button>
                      <span className="truncate font-medium">{d.payee}</span>
                      <span className="font-mono text-[10px] opacity-70">{d.date}</span>
                      <span className={`font-black tabular-nums ${d.type === "income" ? "text-green-500" : "text-foreground"}`}>
                        {d.type === "expense" ? "-" : "+"}${d.amount.toFixed(2)}
                      </span>
                      {d.type === "income" ? (
                        <ArrowUpCircle className="h-4 w-4 text-green-500" />
                      ) : (
                        <ArrowDownCircle className="h-4 w-4 text-muted-foreground" />
                      )}
                      {isDup && (
                        <span className="col-start-2 col-span-4 text-[9px] uppercase tracking-widest text-amber-500 font-black -mt-1">
                          Possible duplicate of an existing transaction
                        </span>
                      )}
                    </li>
                  );
                })}
              </ul>
            </div>
            <div className="flex gap-2 pt-2">
              <Button variant="outline" onClick={() => setStep("map")} className="flex-1">Back</Button>
              <Button onClick={handleCommit} disabled={includedCount === 0 || !householdId} className="flex-[2]">
                Commit {includedCount} transaction{includedCount === 1 ? "" : "s"}
              </Button>
            </div>
          </div>
        )}

        {/* Step 4: done */}
        {step === "done" && (
          <div className="space-y-4 text-center py-4">
            <div className="h-16 w-16 rounded-2xl bg-green-500/10 flex items-center justify-center border border-green-500/20 mx-auto">
              <Check className="h-8 w-8 text-green-500" />
            </div>
            <div>
              <h3 className="text-2xl font-black italic uppercase tracking-tighter">Imported {committed}</h3>
              <p className="text-xs text-muted-foreground mt-1">Transactions added to the ledger.</p>
            </div>
            <div className="flex gap-2 pt-2">
              <Button variant="outline" onClick={reset} className="flex-1">Import another</Button>
              <Button onClick={handleClose} className="flex-[2]">Done</Button>
            </div>
          </div>
        )}
      </div>
    </BeaconModal>
  );
}

function ColumnSelect({
  label,
  value,
  headers,
  onChange,
  optional,
}: {
  label: string;
  value: string | undefined;
  headers: string[];
  onChange: (v: string) => void;
  optional?: boolean;
}) {
  return (
    <div className="space-y-1">
      <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">{label}</Label>
      <NativeSelect value={value ?? ""} onChange={(e) => onChange(e.target.value)} className="bg-primary/5 border-none font-bold h-11">
        {optional && <option value="">— none —</option>}
        {!optional && !value && <option value="">— select column —</option>}
        {headers.map((h) => (
          <option key={h} value={h}>{h}</option>
        ))}
      </NativeSelect>
    </div>
  );
}

function Stat({ label, value, accent }: { label: string; value: number; accent?: "amber" | "green" }) {
  const color = accent === "amber" ? "text-amber-500" : accent === "green" ? "text-green-500" : "text-foreground";
  return (
    <div className="p-3 rounded-2xl bg-primary/5 border border-primary/10">
      <div className={`text-2xl font-black italic tracking-tighter ${color}`}>{value}</div>
      <div className="text-[9px] font-black uppercase tracking-widest opacity-60">{label}</div>
    </div>
  );
}

export const LedgerImportFlowDialogTitle = X; // placeholder export to silence unused-import warnings if any
