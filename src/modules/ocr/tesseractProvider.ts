import type { ExtractionDraft, OcrProvider } from "./types";
import { extractFields } from "./extractFields";

/**
 * Tesseract.js-backed OCR provider. Lazily imports the WASM-heavy library so
 * the main bundle isn't paying for it until the user actually triggers an
 * extraction. Local-only — no network round-trip after the worker is loaded.
 *
 * Performance note: Tesseract loads ~3-10 MB of WASM + language data on first
 * use. The lazy import keeps that off the critical path.
 */
export const tesseractProvider: OcrProvider = {
  id: "tesseract-local",
  isLocal: true,

  async extract(blob, opts) {
    const onProgress = opts?.onProgress;
    onProgress?.({ status: "loading-engine", progress: 0 });

    // Lazy import — only paid for when the user actually extracts.
    const tesseract = await import("tesseract.js");

    const url = URL.createObjectURL(blob);
    try {
      const result = await tesseract.recognize(url, "eng", {
        logger: (m: { status: string; progress: number }) => {
          onProgress?.({ status: m.status, progress: m.progress ?? 0 });
        },
      });

      const rawText = result.data.text || "";
      const overallConfidence =
        typeof result.data.confidence === "number" ? result.data.confidence / 100 : undefined;

      const fields = extractFields(rawText).map((f) =>
        f.confidence === undefined && overallConfidence !== undefined
          ? { ...f, confidence: overallConfidence }
          : f
      );

      onProgress?.({ status: "done", progress: 1 });

      const draft: ExtractionDraft = {
        providerId: "tesseract-local",
        rawText,
        fields,
        overallConfidence,
      };
      return draft;
    } finally {
      URL.revokeObjectURL(url);
    }
  },
};
