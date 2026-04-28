import React, { useState } from "react";
import type { ExtractionDraft, ExtractedField } from "../../modules/ocr/types";
import { CardHeader, CardTitle, CardContent } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { GlassCard } from "../ui/GlassCard";
import { BeaconModal } from "../ui/BeaconModal";
import { CheckCircle2, Trash2, Zap } from "lucide-react";

export interface ExtractionReviewProps {
  isOpen: boolean;
  onClose: () => void;
  extraction: ExtractionDraft | null;
  documentId: string;
  onApprove: (fields: ExtractedField[], documentId: string) => Promise<void>;
  isApproving?: boolean;
}

/**
 * VaultExtractionReview — side-by-side document preview + per-field editor.
 *
 * Displays OCR extraction results with per-field confidence indicators.
 * User can edit values, mark fields as skip, or approve for commit to the db.
 * All edits are local to this component until "Approve & Commit" is clicked.
 */
export function VaultExtractionReview({
  isOpen,
  onClose,
  extraction,
  documentId,
  onApprove,
  isApproving,
}: ExtractionReviewProps) {
  const [editedFields, setEditedFields] = useState<ExtractedField[]>([]);
  const [skippedFieldIds, setSkippedFieldIds] = useState<Set<string>>(new Set());

  // Sync extraction into editable state when modal opens
  React.useEffect(() => {
    if (isOpen && extraction) {
      setEditedFields(extraction.fields);
      setSkippedFieldIds(new Set());
    }
  }, [isOpen, extraction]);

  if (!extraction) return null;

  const handleFieldChange = (index: number, newValue: string) => {
    const updated = [...editedFields];
    updated[index] = { ...updated[index], value: newValue };
    setEditedFields(updated);
  };

  const handleConfidenceChange = (index: number, newConfidence: number) => {
    const updated = [...editedFields];
    updated[index] = { ...updated[index], confidence: newConfidence };
    setEditedFields(updated);
  };

  const toggleSkip = (index: number) => {
    const newSkipped = new Set(skippedFieldIds);
    if (newSkipped.has(String(index))) {
      newSkipped.delete(String(index));
    } else {
      newSkipped.add(String(index));
    }
    setSkippedFieldIds(newSkipped);
  };

  const fieldsToApprove = editedFields.filter((_, i) => !skippedFieldIds.has(String(i)));

  const handleApprove = async () => {
    await onApprove(fieldsToApprove, documentId);
    onClose();
  };

  const confidenceColor = (conf?: number) => {
    if (!conf) return "text-muted-foreground";
    if (conf >= 0.9) return "text-green-500";
    if (conf >= 0.7) return "text-yellow-500";
    return "text-orange-500";
  };

  const confidenceLabel = (conf?: number) => {
    if (!conf) return "Unknown";
    return `${(conf * 100).toFixed(0)}%`;
  };

  return (
    <BeaconModal isOpen={isOpen} onClose={onClose} title="Review Extraction Results">
      <div className="space-y-6 max-h-[70vh] overflow-y-auto">
        {/* Header: extraction summary */}
        <div className="flex items-center gap-3 pb-4 border-b border-primary/10">
          <Zap className="h-5 w-5 text-amber-400" />
          <div className="flex-1">
            <div className="font-semibold text-sm">Extraction Results</div>
            <div className="text-[10px] text-muted-foreground">
              {extraction.fields.length} fields detected • Document ID: {documentId.slice(0, 8)}...
            </div>
          </div>
          <div className={`text-xs font-bold ${confidenceColor(extraction.overallConfidence)}`}>
            {confidenceLabel(extraction.overallConfidence)}
          </div>
        </div>

        {/* Raw text fallback */}
        {extraction.fields.length === 0 && extraction.rawText && (
          <GlassCard className="bg-amber-400/5 border-amber-400/20">
            <CardHeader className="pb-2">
              <CardTitle className="text-xs">Raw OCR Text (No Fields Detected)</CardTitle>
            </CardHeader>
            <CardContent>
              <pre className="text-[10px] text-muted-foreground bg-primary/5 p-3 rounded-lg overflow-auto max-h-40 font-mono whitespace-pre-wrap break-words">
                {extraction.rawText}
              </pre>
              <p className="text-[9px] text-muted-foreground mt-3">
                The extractor found no structured fields but preserved the raw text. You can manually enter key values below or skip this extraction.
              </p>
            </CardContent>
          </GlassCard>
        )}

        {/* Editable fields */}
        {editedFields.length > 0 && (
          <div className="space-y-4">
            <div className="text-xs font-bold uppercase tracking-widest opacity-70">Extracted Fields</div>
            {editedFields.map((field, idx) => {
              const isSkipped = skippedFieldIds.has(String(idx));
              return (
                <div
                  key={idx}
                  className={`p-4 rounded-xl border transition-all ${
                    isSkipped
                      ? "bg-muted/30 border-muted/30 opacity-50"
                      : "bg-primary/5 border-primary/20 hover:border-primary/40"
                  }`}
                >
                  <div className="flex items-start justify-between gap-3 mb-3">
                    <div className="flex-1">
                      <Label className="text-[10px] font-black uppercase tracking-widest opacity-70">
                        {field.label}
                      </Label>
                      <div className="text-[9px] text-muted-foreground mt-1 flex items-center gap-2">
                        <span>{field.kind.toUpperCase()}</span>
                        {field.confidence !== undefined && (
                          <span className={`font-semibold ${confidenceColor(field.confidence)}`}>
                            {confidenceLabel(field.confidence)}
                          </span>
                        )}
                      </div>
                    </div>
                    <Button
                      size="sm"
                      variant="ghost"
                      onClick={() => toggleSkip(idx)}
                      className="h-8 px-2 text-xs"
                    >
                      {isSkipped ? <Trash2 className="h-3.5 w-3.5" /> : <CheckCircle2 className="h-3.5 w-3.5" />}
                    </Button>
                  </div>

                  {!isSkipped && (
                    <div className="space-y-3">
                      <Input
                        value={field.value}
                        onChange={(e) => handleFieldChange(idx, e.target.value)}
                        placeholder={`Enter ${field.label.toLowerCase()}`}
                        className="bg-background border-primary/30 h-10 text-sm font-medium"
                      />

                      {field.confidence !== undefined && (
                        <div className="flex items-center gap-3">
                          <Label className="text-[9px] font-bold opacity-70 min-w-fit">Confidence</Label>
                          <input
                            type="range"
                            min="0"
                            max="100"
                            value={(field.confidence * 100).toFixed(0)}
                            onChange={(e) => handleConfidenceChange(idx, parseInt(e.target.value) / 100)}
                            className="flex-1 cursor-pointer"
                          />
                          <span className={`text-[9px] font-bold min-w-fit ${confidenceColor(field.confidence)}`}>
                            {confidenceLabel(field.confidence)}
                          </span>
                        </div>
                      )}
                    </div>
                  )}

                  {isSkipped && (
                    <div className="text-[9px] text-muted-foreground italic">This field will not be committed.</div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        {/* Info cards */}
        <div className="grid grid-cols-2 gap-3">
          <GlassCard className="p-3">
            <div className="text-[9px] font-black uppercase tracking-widest opacity-70">Provider</div>
            <div className="text-xs font-semibold mt-1">{extraction.providerId}</div>
          </GlassCard>
          <GlassCard className="p-3">
            <div className="text-[9px] font-black uppercase tracking-widest opacity-70">Fields</div>
            <div className="text-xs font-semibold mt-1">
              {fieldsToApprove.length} / {editedFields.length}
            </div>
          </GlassCard>
        </div>

        {/* Action buttons */}
        <div className="flex gap-3 pt-4 border-t border-primary/10">
          <Button variant="ghost" onClick={onClose} className="flex-1 h-10 uppercase font-black text-xs">
            Cancel
          </Button>
          <Button
            onClick={handleApprove}
            disabled={fieldsToApprove.length === 0 || isApproving}
            className="flex-1 h-10 gap-2 uppercase font-black text-xs bg-primary hover:bg-primary/90"
          >
            {isApproving ? (
              <>Approving...</>
            ) : (
              <>
                <CheckCircle2 className="h-3.5 w-3.5" />
                Approve & Commit
              </>
            )}
          </Button>
        </div>
      </div>
    </BeaconModal>
  );
}
