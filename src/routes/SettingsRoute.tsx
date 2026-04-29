import React, { useEffect, useRef, useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { db } from "../db/db";
import { exportDatabaseToJson } from "../modules/reports/exportJson";
import {
  parseBackupJson,
  applyBackupPayload,
  backupRowCounts,
  currentDbRowCounts,
  type BackupPayload,
  type BackupRowCounts,
} from "../modules/reports/importJson";
import { clearDatabase, seedDemoData } from "../db/seedDemoData";
import { useTheme, type Theme } from "../components/theme-provider";
import { loadPreferences, savePreferences, defaultPreferences, type Preferences } from "../lib/preferences/preferences";
import { DemoBadge } from "../components/ui/DemoBadge";
import { resolveProviderFromConfig } from "../modules/ai/providerFactory";
import { PayeeRulesPanel } from "../components/import/PayeeRulesPanel";
import {
  Palette, Database, Bell, Shield,
  History, Zap, Sparkles, Bot, Key, Cpu, Wifi, WifiOff, Loader2,
} from "lucide-react";

type Toggle = { key: keyof Preferences; label: string };

const NOTIFICATION_TOGGLES: Toggle[] = [
  { key: "billDueReminders", label: "Bill Due Reminders" },
  { key: "budgetDeficitWarnings", label: "Budget Deficit Warnings" },
];

const PRIVACY_TOGGLES: Toggle[] = [
  { key: "sensitiveValueMasking", label: "Sensitive Value Masking" },
];

const AUTOMATION_TOGGLES: Toggle[] = [
  { key: "autoCategorizePayees", label: "Auto-Categorize Payees" },
  { key: "predictiveStashMapping", label: "Predictive Stash Mapping" },
];

const AI_CONFIG_ID = "primary";

interface PendingImport {
  parsed: BackupPayload;
  backupCounts: BackupRowCounts;
  liveCounts: BackupRowCounts;
  filename: string;
}

export default function SettingsRoute() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [importStatus, setImportStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const [pendingImport, setPendingImport] = useState<PendingImport | null>(null);
  const { theme, setTheme } = useTheme();

  const [prefs, setPrefs] = useState<Preferences>(defaultPreferences);
  const [savedFlash, setSavedFlash] = useState(false);

  // AI Config state, hydrated from Dexie aiConfig table.
  const aiConfigRow = useLiveQuery(() => db.aiConfig.get(AI_CONFIG_ID), []);
  const householdId = useLiveQuery(() => db.households.toCollection().first().then((h) => h?.id), []);
  const [aiProvider, setAiProvider] = useState<"local" | "api">("local");
  const [apiKey, setApiKey] = useState("");
  const [localEndpoint, setLocalEndpoint] = useState("http://localhost:11434");
  const [model, setModel] = useState("");
  const [healthState, setHealthState] = useState<{ status: "idle" | "testing" | "ok" | "error"; message?: string }>({ status: "idle" });

  // Load preferences once on mount using useCallback to avoid state setter in effect.
  useEffect(() => {
    const prefs = loadPreferences();
    setPrefs(prefs);
  }, []);

  // Hydrate AI form state when Dexie row arrives.
  useEffect(() => {
    if (!aiConfigRow) return;
    setAiProvider(aiConfigRow.provider);
    setApiKey(aiConfigRow.apiKey ?? "");
    setLocalEndpoint(aiConfigRow.localEndpoint ?? "http://localhost:11434");
    setModel(aiConfigRow.model ?? "");
  }, [aiConfigRow]);

  const togglePref = (key: keyof Preferences) => {
    setPrefs((p) => ({ ...p, [key]: !p[key] }));
  };

  const handleExport = async () => {
    try {
      await exportDatabaseToJson();
    } catch (err) {
      console.error(err);
      setErrorMessage("Failed to export data. See console.");
      setImportStatus("error");
    }
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportStatus("loading");
    setErrorMessage("");
    try {
      const text = await file.text();
      const parsed = parseBackupJson(text);
      const backupCounts = backupRowCounts(parsed);
      const liveCounts = await currentDbRowCounts();
      setPendingImport({ parsed, backupCounts, liveCounts, filename: file.name });
      setImportStatus("idle");
    } catch (err) {
      setImportStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Backup file is invalid or corrupted.");
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const confirmImport = async () => {
    if (!pendingImport) return;
    setImportStatus("loading");
    try {
      await applyBackupPayload(pendingImport.parsed);
      setPendingImport(null);
      setImportStatus("success");
      window.setTimeout(() => setImportStatus("idle"), 3000);
    } catch (err) {
      setImportStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Failed to apply backup.");
    }
  };

  const cancelImport = () => {
    setPendingImport(null);
    setImportStatus("idle");
  };

  const handleReset = async () => {
    const ok = window.confirm(
      "Wipe the entire local database?\n\nExport a backup first if you might want it back. This cannot be undone."
    );
    if (!ok) return;
    await clearDatabase();
    window.location.reload();
  };

  const handleSaveAll = async () => {
    savePreferences(prefs);
    await db.aiConfig.put({
      id: AI_CONFIG_ID,
      provider: aiProvider,
      apiKey: aiProvider === "api" ? apiKey : undefined,
      localEndpoint: aiProvider === "local" ? localEndpoint : (aiProvider === "api" ? localEndpoint || undefined : undefined),
      model: model || undefined,
    });
    setSavedFlash(true);
    window.setTimeout(() => setSavedFlash(false), 2000);
  };

  const handleTestConnection = async () => {
    setHealthState({ status: "testing" });
    const { provider, reason } = resolveProviderFromConfig({
      id: AI_CONFIG_ID,
      provider: aiProvider,
      apiKey: aiProvider === "api" ? apiKey : undefined,
      localEndpoint: localEndpoint || undefined,
      model: model || undefined,
    });
    if (!provider) {
      setHealthState({
        status: "error",
        message: reason === "missing-endpoint"
          ? "Local endpoint is empty."
          : reason === "missing-api-key"
            ? "API key is empty."
            : "Provider not configured.",
      });
      return;
    }
    try {
      const reply = await provider.chat(
        [
          { role: "system", content: "Reply with just the word OK." },
          { role: "user", content: "ping" },
        ],
        { temperature: 0 },
      );
      setHealthState({ status: "ok", message: `Reachable. Reply: "${reply.slice(0, 40)}${reply.length > 40 ? "…" : ""}"` });
    } catch (err) {
      setHealthState({ status: "error", message: err instanceof Error ? err.message : "Unknown error." });
    }
  };

  const themes: { id: Theme; label: string; color: string }[] = [
    { id: "glass", label: "Deep Glass", color: "bg-blue-400" },
    { id: "oceanic", label: "Oceanic Drift", color: "bg-cyan-600" },
    { id: "cyber", label: "Cyber Neon", color: "bg-fuchsia-500" },
    { id: "forest", label: "Forest Whisper", color: "bg-emerald-700" },
    { id: "sunset", label: "Sunset Glow", color: "bg-orange-500" },
    { id: "midnight", label: "Midnight Sky", color: "bg-slate-950" },
    { id: "royal", label: "Royal Velvet", color: "bg-violet-700" },
    { id: "slate", label: "Slate Industrial", color: "bg-slate-500" },
    { id: "emerald", label: "Pure Emerald", color: "bg-green-500" },
    { id: "minimal", label: "Minimalist", color: "bg-white border" },
  ];

  const ToggleRow = ({ label, value, onClick }: { label: string; value: boolean; onClick: () => void }) => (
    <button
      type="button"
      onClick={onClick}
      className="w-full flex items-center justify-between py-2 hover:opacity-80 transition-opacity"
      aria-pressed={value}
      aria-label={`${label}: ${value ? "on" : "off"}`}
    >
      <span className="text-sm font-medium">{label}</span>
      <div className={`h-6 w-10 rounded-full relative transition-colors ${value ? "bg-primary" : "bg-muted"}`}>
        <div className={`absolute top-1 h-4 w-4 bg-white rounded-full transition-transform ${value ? "right-1" : "left-1"}`} />
      </div>
    </button>
  );

  return (
    <div className="space-y-8 max-w-6xl mx-auto pb-20" data-testid="settings-route">
      <div className="flex justify-between items-center gap-4 flex-wrap">
        <div>
          <h1 className="text-4xl font-black tracking-tighter italic uppercase text-primary">System Settings</h1>
          <p className="text-muted-foreground font-medium">Core engine configuration & UI aesthetics.</p>
        </div>
        <div className="flex items-center gap-3">
          {savedFlash && (
            <span role="status" className="text-xs font-bold text-green-500 uppercase tracking-widest">
              ✓ Saved
            </span>
          )}
          <Button size="lg" onClick={handleSaveAll} className="shadow-xl hover:scale-105 transition-transform active:scale-95">
            Save Preferences
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* Theme & Aesthetics */}
        <Card className="overflow-hidden border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Palette className="h-5 w-5" /> UI Aesthetics</CardTitle>
            <CardDescription>Switch between 10 unique visual experiences.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="grid grid-cols-2 gap-3">
              {themes.map((t) => (
                <button
                  key={t.id}
                  onClick={() => setTheme(t.id)}
                  className={`flex items-center gap-3 p-3 rounded-xl border-2 transition-all ${theme === t.id ? "border-primary bg-primary/10 shadow-lg" : "border-transparent hover:bg-muted/50"}`}
                >
                  <div className={`h-4 w-4 rounded-full ${t.color}`} />
                  <span className="text-sm font-bold">{t.label}</span>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* Backup & Restore */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Database className="h-5 w-5" /> Data Engine</CardTitle>
            <CardDescription>Offline-first local database management.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="flex flex-col gap-3">
              <Button onClick={handleExport} variant="outline" className="justify-start gap-2">
                <History className="h-4 w-4" /> Export Backup (JSON)
              </Button>
              <div className="relative">
                <input type="file" accept="application/json" ref={fileInputRef} className="hidden" onChange={handleImport} />
                <Button variant="outline" className="w-full justify-start gap-2" onClick={() => fileInputRef.current?.click()}>
                  <Sparkles className="h-4 w-4" /> Restore from JSON
                </Button>
              </div>
            </div>
            {importStatus === "loading" && <p role="status" className="text-xs text-muted-foreground font-bold">Reading backup…</p>}
            {importStatus === "success" && <p role="status" className="text-xs text-green-500 font-bold">✓ Backup imported successfully.</p>}
            {importStatus === "error" && <p role="alert" className="text-xs text-destructive font-bold">✕ {errorMessage}</p>}

            {pendingImport && (
              <RestoreDiffPanel
                pending={pendingImport}
                onConfirm={confirmImport}
                onCancel={cancelImport}
              />
            )}

            <p className="text-[10px] text-muted-foreground leading-relaxed pt-2 border-t border-primary/5">
              Backup format v3 covers all household data including uploaded documents (base64-encoded). Older v1 / v2 backups still validate on import.
            </p>
          </CardContent>
        </Card>

        {/* Payee rules */}
        <div className="md:col-span-2">
          <PayeeRulesPanel householdId={householdId} />
        </div>

        {/* Notifications */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Bell className="h-5 w-5" /> Pay Path Alerts</CardTitle>
            <CardDescription>Bill reminders and budget threshold warnings.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-3">
            {NOTIFICATION_TOGGLES.map((t) => (
              <ToggleRow key={t.key} label={t.label} value={prefs[t.key]} onClick={() => togglePref(t.key)} />
            ))}
            <p className="text-[10px] text-muted-foreground pt-2 border-t border-primary/5">
              Preferences saved locally. OS notification delivery lands in M9 (Capacitor on Android, native on Electron).
            </p>
          </CardContent>
        </Card>

        {/* Privacy */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Shield className="h-5 w-5" /> Privacy Shield</CardTitle>
            <CardDescription>Secure your local financial telemetry.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-3">
            <div className="flex items-center justify-between py-2">
              <span className="text-sm font-medium">Biometric Auth</span>
              <DemoBadge milestone="M9">Capacitor plugin pending.</DemoBadge>
            </div>
            {PRIVACY_TOGGLES.map((t) => (
              <ToggleRow key={t.key} label={t.label} value={prefs[t.key]} onClick={() => togglePref(t.key)} />
            ))}
          </CardContent>
        </Card>

        {/* Automation toggles (gated on real implementation) */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Zap className="h-5 w-5" /> Automation</CardTitle>
            <CardDescription>Smart categorization and predictive flows.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-3">
            {AUTOMATION_TOGGLES.map((t) => (
              <ToggleRow key={t.key} label={t.label} value={prefs[t.key]} onClick={() => togglePref(t.key)} />
            ))}
            <p className="text-[10px] text-muted-foreground pt-2 border-t border-primary/5">
              Toggles are persisted now; the underlying engines (M5 categorization, M8 predictive savings) will read these flags when they land.
            </p>
          </CardContent>
        </Card>

        {/* AI Agent Engine */}
        <Card className="border-primary/20 bg-primary/5 backdrop-blur-xl md:col-span-2 shadow-2xl">
          <CardHeader className="bg-primary/10">
            <div className="flex items-start justify-between gap-4 flex-wrap">
              <div>
                <CardTitle className="flex items-center gap-2"><Bot className="h-6 w-6 text-primary" /> Beacon AI Agent Engine</CardTitle>
                <CardDescription>Configure the brain behind the assistant. Persists to the local aiConfig table.</CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="pt-8 space-y-6">
            <div className="flex gap-4 p-1 bg-muted/50 rounded-xl w-fit">
              <Button
                variant={aiProvider === "local" ? "default" : "ghost"}
                size="sm"
                onClick={() => setAiProvider("local")}
                className="rounded-lg gap-2"
              >
                <Cpu className="h-4 w-4" /> Local LLM
              </Button>
              <Button
                variant={aiProvider === "api" ? "default" : "ghost"}
                size="sm"
                onClick={() => setAiProvider("api")}
                className="rounded-lg gap-2"
              >
                <Key className="h-4 w-4" /> Cloud API
              </Button>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {aiProvider === "local" ? (
                <div className="space-y-2">
                  <Label htmlFor="ai-local-endpoint">Local Endpoint URL</Label>
                  <Input
                    id="ai-local-endpoint"
                    value={localEndpoint}
                    onChange={(e) => setLocalEndpoint(e.target.value)}
                    placeholder="http://localhost:11434"
                  />
                  <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Recommended: Ollama on localhost. Run <code>ollama serve</code> first.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  <div className="space-y-2">
                    <Label htmlFor="ai-api-key">Cloud API Key</Label>
                    <Input
                      id="ai-api-key"
                      type="password"
                      value={apiKey}
                      onChange={(e) => setApiKey(e.target.value)}
                      placeholder="sk-..."
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="ai-base-url">Base URL (optional)</Label>
                    <Input
                      id="ai-base-url"
                      value={localEndpoint}
                      onChange={(e) => setLocalEndpoint(e.target.value)}
                      placeholder="https://api.openai.com (default)"
                    />
                    <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter text-yellow-600">Any OpenAI-compatible endpoint (Groq, Together, OpenRouter, LM Studio, llama.cpp).</p>
                  </div>
                </div>
              )}
              <div className="space-y-2">
                <Label htmlFor="ai-model">Model Identifier</Label>
                <Input
                  id="ai-model"
                  value={model}
                  onChange={(e) => setModel(e.target.value)}
                  placeholder={aiProvider === "local" ? "llama3.2" : "gpt-4o-mini"}
                />
              </div>
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <Button onClick={handleTestConnection} variant="outline" size="sm" className="gap-2" disabled={healthState.status === "testing"}>
                {healthState.status === "testing" ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : healthState.status === "ok" ? <Wifi className="h-3.5 w-3.5 text-green-500" /> : healthState.status === "error" ? <WifiOff className="h-3.5 w-3.5 text-destructive" /> : <Wifi className="h-3.5 w-3.5" />}
                Test Connection
              </Button>
              {healthState.status === "ok" && (
                <span role="status" className="text-[11px] font-bold text-green-600">✓ {healthState.message}</span>
              )}
              {healthState.status === "error" && (
                <span role="alert" className="text-[11px] font-bold text-destructive">✕ {healthState.message}</span>
              )}
            </div>

            <div className="p-4 rounded-xl border border-primary/20 bg-primary/5 text-xs text-muted-foreground leading-relaxed">
              <strong className="text-foreground">Privacy rule:</strong> Beacon Agent only ever sees an aggregated household snapshot (totals, counts, ratios) — never raw transactions, document blobs, or person-identifying detail. Cloud provider is opt-in via the toggle above; default is local-only.
            </div>
          </CardContent>
        </Card>

        {/* Danger Zone */}
        <Card className="border-destructive/30 bg-destructive/5 backdrop-blur-xl md:col-span-2">
          <CardHeader className="bg-destructive/10">
            <CardTitle className="text-destructive">System Reset & Destruction</CardTitle>
            <CardDescription>Destructive actions that wipe local data permanently. Export a backup first.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="flex flex-col gap-4 sm:flex-row">
              <Button variant="destructive" onClick={handleReset} className="w-full sm:w-auto shadow-lg shadow-destructive/20">
                Wipe Local Database
              </Button>
              <Button
                variant="outline"
                onClick={async () => {
                  if (window.confirm("Reset local data to the demo seed? This wipes current data first.")) {
                    await seedDemoData();
                    window.location.reload();
                  }
                }}
                className="w-full sm:w-auto border-destructive/20 text-destructive"
              >
                Reset to Demo State
              </Button>
            </div>
          </CardContent>
        </Card>

      </div>
    </div>
  );
}

const COUNT_LABELS: Array<{ key: keyof BackupRowCounts; label: string }> = [
  { key: "households", label: "Households" },
  { key: "persons", label: "People" },
  { key: "incomeSources", label: "Income sources" },
  { key: "bills", label: "Bills" },
  { key: "debts", label: "Debts" },
  { key: "savingsGoals", label: "Savings goals" },
  { key: "creditSnapshots", label: "Credit snapshots" },
  { key: "transactions", label: "Transactions" },
  { key: "subscriptions", label: "Subscriptions" },
  { key: "insuranceRecords", label: "Insurance policies" },
  { key: "documents", label: "Documents" },
  { key: "taxRecords", label: "Tax records" },
  { key: "taxForms", label: "Tax forms" },
  { key: "chatMessages", label: "Chat messages" },
];

function RestoreDiffPanel({
  pending,
  onConfirm,
  onCancel,
}: {
  pending: { parsed: BackupPayload; backupCounts: BackupRowCounts; liveCounts: BackupRowCounts; filename: string };
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const { backupCounts, liveCounts, filename, parsed } = pending;
  const totalIncoming = COUNT_LABELS.reduce((s, c) => s + (backupCounts[c.key] || 0), 0);
  const totalLive = COUNT_LABELS.reduce((s, c) => s + (liveCounts[c.key] || 0), 0);

  return (
    <div role="dialog" aria-label="Confirm restore" className="rounded-2xl border border-amber-400/30 bg-amber-400/5 p-5 space-y-4">
      <div>
        <h3 className="text-sm font-black uppercase italic tracking-tighter text-amber-500">Confirm Restore</h3>
        <p className="text-[11px] text-muted-foreground mt-1">
          From <strong className="text-foreground">{filename}</strong> · backup format v{parsed.version} · exported{" "}
          {parsed.exportedAt.split("T")[0]}.
        </p>
      </div>

      <p className="text-xs text-muted-foreground leading-relaxed">
        Importing will <strong className="text-amber-500">REPLACE all current data</strong> with the contents of this backup.
        Compare row counts before confirming:
      </p>

      <div className="grid grid-cols-3 gap-x-4 text-[10px] font-bold uppercase tracking-widest text-muted-foreground border-b border-primary/10 pb-1">
        <span>Table</span>
        <span className="text-right">Current</span>
        <span className="text-right">Backup</span>
      </div>
      <div className="max-h-56 overflow-y-auto space-y-1 text-xs">
        {COUNT_LABELS.map((c) => {
          const cur = liveCounts[c.key] ?? 0;
          const bak = backupCounts[c.key] ?? 0;
          const changed = cur !== bak;
          return (
            <div
              key={c.key}
              className={`grid grid-cols-3 gap-x-4 py-1 ${changed ? "text-foreground font-bold" : "opacity-60"}`}
            >
              <span>{c.label}</span>
              <span className="text-right tabular-nums">{cur}</span>
              <span className={`text-right tabular-nums ${changed ? (bak > cur ? "text-green-500" : bak < cur ? "text-destructive" : "") : ""}`}>{bak}</span>
            </div>
          );
        })}
      </div>
      <div className="grid grid-cols-3 gap-x-4 text-[10px] font-black uppercase tracking-widest border-t border-primary/10 pt-1">
        <span>Total rows</span>
        <span className="text-right tabular-nums">{totalLive}</span>
        <span className="text-right tabular-nums">{totalIncoming}</span>
      </div>

      <div className="flex gap-2 pt-2">
        <Button variant="outline" onClick={onCancel} className="flex-1">
          Cancel
        </Button>
        <Button onClick={onConfirm} className="flex-[2] bg-amber-500 hover:bg-amber-600 text-white">
          Replace data with backup
        </Button>
      </div>
    </div>
  );
}
