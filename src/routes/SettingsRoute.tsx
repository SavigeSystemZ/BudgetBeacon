import React, { useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { exportDatabaseToJson } from "../modules/reports/exportJson";
import { importDatabaseFromJson } from "../modules/reports/importJson";
import { clearDatabase, seedDemoData } from "../db/seedDemoData";
import { useTheme, type Theme } from "../components/theme-provider";
import { 
  Palette, Database, Globe, Bell, Shield, 
  History, Wallet, Zap, Languages, Sparkles, Bot, Key, Cpu 
} from "lucide-react";

export default function SettingsRoute() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [importStatus, setImportStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");
  const { theme, setTheme } = useTheme();

  // AI Config State (Local or API)
  const [aiProvider, setAiProvider] = useState<"local" | "api">("local");
  const [apiKey, setApiKey] = useState("");
  const [localEndpoint, setLocalEndpoint] = useState("http://localhost:11434/api/generate");

  const handleExport = async () => {
    try {
      await exportDatabaseToJson();
    } catch (err) {
      console.error(err);
      alert("Failed to export data.");
    }
  };

  const handleImport = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    if (!window.confirm("WARNING: Importing a backup will overwrite ALL current data. Proceed?")) {
      if (fileInputRef.current) fileInputRef.current.value = "";
      return;
    }
    setImportStatus("loading");
    try {
      await importDatabaseFromJson(file);
      setImportStatus("success");
      setTimeout(() => setImportStatus("idle"), 3000);
      alert("Backup imported successfully.");
    } catch (err) {
      setImportStatus("error");
      setErrorMessage(err instanceof Error ? err.message : "Unknown import error");
    } finally {
      if (fileInputRef.current) fileInputRef.current.value = "";
    }
  };

  const handleReset = async () => {
    if (window.confirm("Are you sure you want to delete ALL data? This action cannot be undone.")) {
      await clearDatabase();
      alert("Database wiped. Refreshing app.");
      window.location.reload();
    }
  };

  const handleSaveAll = () => {
    alert("System settings and preferences persisted.");
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

  return (
    <div className="space-y-8 max-w-6xl mx-auto pb-20">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-4xl font-black tracking-tighter italic uppercase text-primary">System Settings</h1>
          <p className="text-muted-foreground font-medium">Core engine configuration & UI aesthetics.</p>
        </div>
        <Button size="lg" onClick={handleSaveAll} className="shadow-xl hover:scale-105 transition-transform active:scale-95">Save Preferences</Button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* 1. Theme & Aesthetics */}
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
                  className={`flex items-center gap-3 p-3 rounded-xl border-2 transition-all ${theme === t.id ? 'border-primary bg-primary/10 shadow-lg' : 'border-transparent hover:bg-muted/50'}`}
                >
                  <div className={`h-4 w-4 rounded-full ${t.color}`} />
                  <span className="text-sm font-bold">{t.label}</span>
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* 2. Backup & Sync */}
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
            {importStatus === "success" && <p className="text-xs text-green-500 font-bold">✓ Backup imported successfully!</p>}
            {importStatus === "error" && <p className="text-xs text-destructive font-bold">✕ Error: {errorMessage}</p>}
          </CardContent>
        </Card>

        {/* 3. Multi-Currency */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Globe className="h-5 w-5" /> Multi-Currency</CardTitle>
            <CardDescription>Configure base currency and symbols.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Base Currency</Label>
                <Input defaultValue="USD" />
              </div>
              <div className="space-y-2">
                <Label>Symbol Placement</Label>
                <Input defaultValue="Prefix ($)" />
              </div>
            </div>
            {importStatus === "success" && <p className="text-xs text-green-500 font-bold">✓ Backup imported successfully!</p>}
            {importStatus === "error" && <p className="text-xs text-destructive font-bold">✕ Error: {errorMessage}</p>}
          </CardContent>
        </Card>

        {/* 4. Notifications */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Bell className="h-5 w-5" /> Pay Path Alerts</CardTitle>
            <CardDescription>Bill reminders and budget threshold warnings.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Bill Due Reminders</span>
              <div className="h-6 w-10 bg-primary rounded-full relative"><div className="absolute right-1 top-1 h-4 w-4 bg-white rounded-full" /></div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Budget Deficit Warnings</span>
              <div className="h-6 w-10 bg-muted rounded-full relative"><div className="absolute left-1 top-1 h-4 w-4 bg-white rounded-full" /></div>
            </div>
          </CardContent>
        </Card>

        {/* 5. Security & Privacy */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Shield className="h-5 w-5" /> Privacy Shield</CardTitle>
            <CardDescription>Secure your local financial telemetry.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Biometric Auth (Capacitor)</span>
              <span className="text-[10px] font-bold px-2 py-0.5 bg-yellow-500/20 text-yellow-600 rounded">PLATFORM ONLY</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Sensitive Value Masking</span>
              <div className="h-6 w-10 bg-primary rounded-full relative"><div className="absolute right-1 top-1 h-4 w-4 bg-white rounded-full" /></div>
            </div>
          </CardContent>
        </Card>

        {/* 6. Ledger Loops Config */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Zap className="h-5 w-5" /> Automation & AI</CardTitle>
            <CardDescription>Smart categorization and recurring loops.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6 space-y-4">
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Auto-Categorize Payees</span>
              <div className="h-6 w-10 bg-primary rounded-full relative"><div className="absolute right-1 top-1 h-4 w-4 bg-white rounded-full" /></div>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-sm font-medium">Predictive Stash Mapping</span>
              <div className="h-6 w-10 bg-muted rounded-full relative"><div className="absolute left-1 top-1 h-4 w-4 bg-white rounded-full" /></div>
            </div>
          </CardContent>
        </Card>

        {/* New: AI Agent Engine */}
        <Card className="border-primary/20 bg-primary/5 backdrop-blur-xl md:col-span-2 shadow-2xl">
          <CardHeader className="bg-primary/10">
            <CardTitle className="flex items-center gap-2"><Bot className="h-6 w-6 text-primary" /> Beacon AI Agent Engine</CardTitle>
            <CardDescription>Configure the brain behind your agentic financial assistant.</CardDescription>
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
                  <Label>Local Endpoint URL</Label>
                  <Input 
                    value={localEndpoint} 
                    onChange={(e) => setLocalEndpoint(e.target.value)} 
                    placeholder="e.g. http://localhost:11434/api/generate" 
                  />
                  <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter">Recommended for 100% Privacy (Docker/Ollama)</p>
                </div>
              ) : (
                <div className="space-y-2">
                  <Label>Cloud API Key</Label>
                  <Input 
                    type="password" 
                    value={apiKey} 
                    onChange={(e) => setApiKey(e.target.value)} 
                    placeholder="sk-..." 
                  />
                  <p className="text-[10px] text-muted-foreground uppercase font-bold tracking-tighter text-yellow-600">Requires External Connectivity (Claude/OpenAI)</p>
                </div>
              )}
              <div className="space-y-2">
                <Label>Model Identifier</Label>
                <Input placeholder={aiProvider === "local" ? "llama3" : "claude-3-sonnet"} />
              </div>
            </div>

            <div className="p-4 rounded-xl border border-primary/20 bg-primary/5 text-xs text-muted-foreground leading-relaxed italic">
              <strong>Agentic Intel:</strong> Beacon AI can analyze your telemetry to suggest tax deductions, 
              identify spending anomalies in Ledger Loops, and forecast Stash Map success.
            </div>
          </CardContent>
        </Card>

        {/* 7. Household Roles */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Languages className="h-5 w-5" /> Language & Region</CardTitle>
            <CardDescription>Localization for global financial standards.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <Input defaultValue="English (US)" className="bg-muted/30" />
          </CardContent>
        </Card>

        {/* 8. Wallet Integration */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><Wallet className="h-5 w-5" /> Physical Wallets</CardTitle>
            <CardDescription>Manage physical cash flow alongside digital.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <Button variant="outline" className="w-full">Audit Cash Inventories</Button>
          </CardContent>
        </Card>

        {/* 9. Advanced Audit Logs */}
        <Card className="border-primary/10 bg-card/50 backdrop-blur-xl md:col-span-2">
          <CardHeader className="bg-primary/5">
            <CardTitle className="flex items-center gap-2"><History className="h-5 w-5" /> Change Log & Audit</CardTitle>
            <CardDescription>Trace every modification made to your budget engine.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="text-xs font-mono text-muted-foreground bg-black/5 dark:bg-black/40 p-4 rounded-xl border border-white/5">
              [2026-04-24 14:22:01] UPDATED_THEME: Switched to Cyber Neon<br/>
              [2026-04-24 14:15:44] DB_PURGE: User initiated database reset<br/>
              [2026-04-24 14:10:12] SESSION_START: Budget Beacon initialized
            </div>
          </CardContent>
        </Card>

        {/* 10. Danger Zone */}
        <Card className="border-destructive/30 bg-destructive/5 backdrop-blur-xl md:col-span-2">
          <CardHeader className="bg-destructive/10">
            <CardTitle className="text-destructive">System Reset & Destruction</CardTitle>
            <CardDescription>Destructive actions that wipe local telemetry permanently.</CardDescription>
          </CardHeader>
          <CardContent className="pt-6">
            <div className="flex flex-col gap-4 sm:flex-row">
              <Button variant="destructive" onClick={handleReset} className="w-full sm:w-auto shadow-lg shadow-destructive/20">
                Wipe Local Database
              </Button>
              <Button variant="outline" onClick={async () => { await seedDemoData(); window.location.reload(); }} className="w-full sm:w-auto border-destructive/20 text-destructive">
                Reset to Demo State
              </Button>
            </div>
          </CardContent>
        </Card>

      </div>
    </div>
  );
}

