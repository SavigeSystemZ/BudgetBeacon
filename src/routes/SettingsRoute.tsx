import React, { useRef, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { exportDatabaseToJson } from "../modules/reports/exportJson";
import { importDatabaseFromJson } from "../modules/reports/importJson";
import { clearDatabase, seedDemoData } from "../db/seedDemoData";

export default function SettingsRoute() {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [importStatus, setImportStatus] = useState<"idle" | "loading" | "success" | "error">("idle");
  const [errorMessage, setErrorMessage] = useState("");

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

    if (!window.confirm("WARNING: Importing a backup will overwrite ALL current data in Budget Beacon. Proceed?")) {
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

  const handleSeed = async () => {
    if (window.confirm("This will inject demo data. Only works on an empty database. Proceed?")) {
      await seedDemoData();
      alert("Demo data seeded. Refreshing app.");
      window.location.reload();
    }
  };

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Settings</h1>
        <p className="text-muted-foreground">Manage your app data and configurations.</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Backup & Restore</CardTitle>
          <CardDescription>
            Because Budget Beacon is offline-first, your data is stored locally in this browser. Keep regular backups to avoid data loss.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 sm:flex-row">
            <Button onClick={handleExport} className="w-full sm:w-auto">
              Export Backup (JSON)
            </Button>
            
            <div className="relative w-full sm:w-auto">
              <input
                type="file"
                accept="application/json"
                ref={fileInputRef}
                className="hidden"
                onChange={handleImport}
              />
              <Button 
                variant="outline" 
                className="w-full" 
                onClick={() => fileInputRef.current?.click()}
                disabled={importStatus === "loading"}
              >
                {importStatus === "loading" ? "Importing..." : "Restore Backup"}
              </Button>
            </div>
          </div>
          
          {importStatus === "success" && <p className="text-sm text-green-600">Import successful!</p>}
          {importStatus === "error" && <p className="text-sm text-destructive">Error: {errorMessage}</p>}
        </CardContent>
      </Card>

      <Card className="border-destructive/30">
        <CardHeader>
          <CardTitle className="text-destructive">Danger Zone</CardTitle>
          <CardDescription>Destructive actions that cannot be undone without a backup.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex flex-col gap-4 sm:flex-row">
            <Button variant="destructive" onClick={handleReset} className="w-full sm:w-auto">
              Wipe Database
            </Button>
            <Button variant="outline" onClick={handleSeed} className="w-full sm:w-auto">
              Seed Demo Data
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
