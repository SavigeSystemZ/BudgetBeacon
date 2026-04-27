/**
 * Provider interface for document OCR / extraction. Per-field confidence
 * lives on each field so the UI can surface low-confidence values to the
 * user before they commit.
 *
 * Implementations: tesseractProvider (browser-side, no network).
 * Future: vision-LLM cloud provider behind featureFlags.ocrVisionCloud
 * (per docs/INTEGRATIONS_STRATEGY.md Domain 2 Phase 2).
 */
export type ExtractionFieldKind = "date" | "amount" | "payee" | "label" | "raw";

export interface ExtractedField {
  kind: ExtractionFieldKind;
  /** User-readable label (e.g. "Date", "Amount", "Payer"). */
  label: string;
  /** The extracted value. Numbers formatted as strings — the review UI parses on commit. */
  value: string;
  /** 0..1 confidence, or undefined if unknown. */
  confidence?: number;
}

export interface ExtractionDraft {
  providerId: string;
  /** Full unstructured OCR text, useful for the user as fallback. */
  rawText: string;
  /** Structured field guesses. May be empty if extractor found nothing. */
  fields: ExtractedField[];
  /** Per-document overall confidence (rough average of field confidences). */
  overallConfidence?: number;
}

export interface ExtractProgress {
  status: string;
  progress: number; // 0..1
}

export interface OcrProvider {
  id: string;
  isLocal: boolean;
  /** Run OCR + structured-field extraction on a Blob. */
  extract(
    blob: Blob,
    opts?: { hint?: "paystub" | "bill" | "bank-statement" | "tax-form"; onProgress?: (p: ExtractProgress) => void }
  ): Promise<ExtractionDraft>;
}
