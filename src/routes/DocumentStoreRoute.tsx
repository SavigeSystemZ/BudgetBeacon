import React, { useState } from "react";
import { useLiveQuery } from "dexie-react-hooks";
import { db } from "../db/db";
import { createId } from "../lib/ids/createId";
import { CardHeader, CardTitle, CardDescription, CardContent } from "../components/ui/card";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Label } from "../components/ui/label";
import { NativeSelect } from "../components/ui/native-select";
import { FileText, Upload, Trash2, Eye, ShieldCheck, Zap, Plus } from "lucide-react";
import { PageHeader } from "../components/layout/PageHeader";
import { GlassCard } from "../components/ui/GlassCard";
import { EmptyState } from "../components/ui/EmptyState";
import { BeaconModal } from "../components/ui/BeaconModal";
import { DemoBadge } from "../components/ui/DemoBadge";
import { featureFlags } from "../lib/flags/featureFlags";

export default function DocumentStoreRoute() {
  const documents = useLiveQuery(() => db.documents.toArray(), []);
  const households = useLiveQuery(() => db.households.toArray(), []);
  const persons = useLiveQuery(() => db.persons.toArray(), []);
  const householdId = households?.[0]?.id;
  const defaultPersonId = persons?.[0]?.id || "default-person";

  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState("other");
  const [fileLabel, setFileLabel] = useState("");
  const [uploadError, setUploadError] = useState<string | null>(null);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file || !householdId) return;

    setUploading(true);
    setUploadError(null);
    try {
      const reader = new FileReader();
      reader.onload = async (event) => {
        const blob = new Blob([event.target?.result as ArrayBuffer], { type: file.type });
        const now = new Date().toISOString();

        await db.documents.add({
          id: createId(),
          householdId,
          personId: defaultPersonId,
          label: fileLabel || file.name,
          category: selectedCategory,
          fileName: file.name,
          fileType: file.type,
          fileSize: file.size,
          data: blob,
          createdAt: now,
          updatedAt: now,
        });

        // Auto-extraction (Scavenge) is gated on featureFlags.ocrLocal — disabled until M6.

        setFileLabel("");
        setIsAddModalOpen(false);
        if (e.target) e.target.value = "";
      };
      reader.readAsArrayBuffer(file);
    } catch (err) {
      console.error(err);
      setUploadError("Failed to store document. Try again.");
    } finally {
      setUploading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (window.confirm("Permanently delete this document from local vault?")) await db.documents.delete(id);
  };

  if (!documents) return <div className="p-4 text-muted-foreground animate-pulse">Accessing The Vault...</div>;

  return (
    <div className="space-y-8 pb-20 animate-in fade-in slide-in-from-bottom-4 duration-700">
      <PageHeader 
        title="The Vault" 
        subtitle="Secure local document store and scavenging engine."
        actions={
          <Button size="icon" onClick={() => setIsAddModalOpen(true)} className="rounded-full shadow-lg shadow-primary/20 h-10 w-10">
            <Plus className="h-5 w-5" />
          </Button>
        }
      />

      {uploadError && (
        <div role="alert" className="mx-4 p-3 rounded-xl border border-destructive/40 bg-destructive/10 text-destructive text-sm">
          {uploadError}
        </div>
      )}

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
        <div className="space-y-6 lg:col-span-1">
          {/* Scavenge / OCR is disabled until M6 ships real Tesseract-backed extraction with per-field review. */}
          <GlassCard className="border-amber-400/20 bg-amber-400/5">
            <CardHeader className="pb-3 flex flex-row items-center gap-2">
              <Zap className="h-5 w-5 text-amber-400" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Document Extraction</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <DemoBadge milestone="M6">
                Real OCR + per-field review will land in M6.
              </DemoBadge>
              <p className="text-[10px] text-muted-foreground leading-relaxed">
                For now, the Vault stores documents safely; extraction into income / bill records remains manual via Pay Path and Income Pool.
              </p>
            </CardContent>
          </GlassCard>

          <GlassCard className="bg-primary/5 border-primary/20">
            <CardHeader className="pb-3 flex flex-row items-center gap-2">
              <ShieldCheck className="h-5 w-5 text-primary" />
              <CardTitle className="text-[10px] font-black uppercase tracking-widest">Vault Security</CardTitle>
            </CardHeader>
            <CardContent className="text-[10px] text-muted-foreground leading-relaxed">
              Documents are stored as local binary blobs. No cloud processing or external tracking occurs during Scavenge protocols.
            </CardContent>
          </GlassCard>
        </div>

        <div className="lg:col-span-3">
          {documents.length === 0 ? (
            <EmptyState 
              icon={FileText}
              title="Vault is Empty"
              description="Upload sensitive financial letters for secure offline access and agentic scavenging."
              action={<Button onClick={() => setIsAddModalOpen(true)} className="gap-2 px-8 uppercase font-black italic text-xs tracking-widest h-12"><Plus className="h-4 w-4" /> Vault New Document</Button>}
            />
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {documents.map((doc) => (
                <GlassCard hoverable key={doc.id} className="group overflow-hidden">
                  <CardHeader className="pb-3 flex flex-row items-center justify-between border-b border-primary/5 bg-primary/5">
                    <div className="flex items-center gap-3">
                      <div className="p-2 bg-primary/10 rounded-xl text-primary"><FileText className="h-5 w-5" /></div>
                      <div>
                        <CardTitle className="text-sm font-bold truncate max-w-[150px]">{doc.label}</CardTitle>
                        <CardDescription className="text-[9px] uppercase font-black text-primary tracking-widest">{doc.category}</CardDescription>
                      </div>
                    </div>
                    <Button variant="ghost" size="icon" onClick={() => handleDelete(doc.id)} className="h-8 w-8 text-destructive opacity-0 group-hover:opacity-100 transition-opacity"><Trash2 className="h-4 w-4" /></Button>
                  </CardHeader>
                  <CardContent className="pt-4 space-y-4">
                    <div className="flex items-center justify-between text-[9px] font-bold text-muted-foreground uppercase opacity-50">
                      <span>{doc.fileName}</span>
                      <span>{(doc.fileSize / 1024).toFixed(1)} KB</span>
                    </div>
                    <div className="flex gap-2">
                      <Button onClick={() => window.open(URL.createObjectURL(doc.data), "_blank")} size="sm" variant="outline" className="flex-1 gap-2 h-10 uppercase font-black italic text-[9px] tracking-widest border-primary/20">
                        <Eye className="h-3.5 w-3.5" /> View
                      </Button>
                      {featureFlags.ocrLocal && (
                        <Button size="sm" variant="outline" className="flex-1 gap-2 h-10 uppercase font-black italic text-[9px] tracking-widest border-primary/20 text-primary hover:bg-primary/10 transition-all">
                          <Zap className="h-3.5 w-3.5" /> Scavenge
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </GlassCard>
              ))}
            </div>
          )}
        </div>
      </div>

      <BeaconModal isOpen={isAddModalOpen} onClose={() => setIsAddModalOpen(false)} title="Vault Document">
        <div className="space-y-6">
          <div className="space-y-2">
            <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Label</Label>
            <Input value={fileLabel} onChange={(e) => setFileLabel(e.target.value)} placeholder="e.g. SSDI Award 2026" className="bg-primary/5 border-none font-bold h-12" />
          </div>
          <div className="space-y-2">
            <Label className="text-[10px] uppercase font-black tracking-widest opacity-70">Classification</Label>
            <NativeSelect value={selectedCategory} onChange={(e) => setSelectedCategory(e.target.value)} className="bg-primary/5 border-none font-bold h-12">
              <option value="award-letter">Award Letter</option>
              <option value="tax-form">Tax Form</option>
              <option value="bank-statement">Bank Statement</option>
              <option value="insurance-policy">Insurance Policy</option>
              <option value="other">Other</option>
            </NativeSelect>
          </div>
          <div className="p-8 rounded-3xl border-2 border-dashed border-primary/20 bg-primary/5 flex flex-col items-center justify-center gap-4 relative group hover:border-primary transition-all">
            <Upload className="h-10 w-10 text-primary opacity-20 group-hover:opacity-100 transition-opacity" />
            <p className="text-[10px] font-black uppercase text-muted-foreground group-hover:text-primary transition-colors">Select Local File</p>
            <Input type="file" onChange={handleFileUpload} disabled={uploading} className="absolute inset-0 opacity-0 cursor-pointer" />
          </div>
          <Button variant="ghost" onClick={() => setIsAddModalOpen(false)} className="w-full h-12 uppercase font-black italic tracking-widest">Cancel</Button>
        </div>
      </BeaconModal>
    </div>
  );
}
