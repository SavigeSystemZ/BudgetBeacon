# Integrations Strategy

Generated: 2026-04-25 (M0 truth reset). Phased plan to replace simulated advanced capabilities with real adapters — without overcommitting to vendors, leaking financial data, or letting AI silently mutate the database.

Cross-references: `PLAN.md`, `ROADMAP.md`, `docs/GUI_COMPLETION_MAP.md`, `FIXME.md`, `RISK_REGISTER.md`.

---

## Guiding principles

1. **Local-first by default.** Cloud features are always opt-in and labeled.
2. **Honesty over breadth.** A removed mock + a manual workflow beats a fake automation.
3. **Adapters, not hardcoded providers.** Every external integration sits behind an interface; the UI talks to the interface, not the vendor SDK.
4. **No silent writes.** AI and OCR proposals require explicit user confirmation.
5. **Feature-flag risky surfaces.** Anything not yet real is hidden or labeled, not pretending.
6. **Incremental commitment.** Tier A (file import) lands before Tier B (aggregator) before Tier C (institution direct).

---

## Integration domain 1: Bank connectivity

### Current reality
- `LedgerRoute.tsx:53-62` "Bank Sync" is `setTimeout` + 2 hardcoded transactions written to real db.
- No real connection to any institution.

### Why not production-real
- Direct bank APIs are institution-specific and rare for consumer accounts.
- Aggregator providers (Plaid, MX, Finicity, Akoya, TrueLayer) charge per-connection fees and have contractual minimums.
- Credentials stored anywhere on-device require strong threat model.

### Phased plan

#### Phase 1 (M5) — Tier A: file import
- File picker → CSV / QFX / OFX parsing → column mapping → dedupe (date + amount + payee) → review queue → user commits.
- No network. No credentials. Works for every bank that exports statements.
- Deliverable: Ledger gets a real "Import" button; mocked Bank Sync removed.

**Adapter shape:**
```ts
interface ImportAdapter {
  detect(file: File): Promise<'csv'|'qfx'|'ofx'|'unknown'>;
  parse(file: File): Promise<RawTransaction[]>;
}
```

#### Phase 2 (post-M9) — Tier B: aggregator (opt-in)
- Plaid Link (or MX Connect Widget) behind a clearly-labeled opt-in.
- Provider-abstracted: `BankProvider` interface; Plaid is one impl.
- Refresh tokens stored encrypted (via WebCrypto + user passphrase).
- **Decision gate:** Tier B is not committed until Tier A is in real household use and proven insufficient.

#### Phase 3 (deferred) — Tier C: institution-specific
- Only if a household-relevant bank exposes a usable consumer API. Rare.
- Implemented as additional `BankProvider` impls; never hardcoded into core.

### UI handling for degraded states
- Tier A always available — no "configured" state needed.
- Tier B / C: settings page shows connection status; failures surface as toast + retry; never silently re-mock.

### Security / privacy controls
- No raw bank credentials in JS storage. Tier B uses provider OAuth/Link flow only.
- Aggregator tokens encrypted at rest with user passphrase.
- No sending of transaction text to AI providers without redaction (see Domain 3).

### Validation
- M5 unit tests: CSV parser correctness on 3 sample files (Chase, BoA, generic).
- M5 integration test: round-trip import → dedupe → commit → re-import same file → no duplicates.

---

## Integration domain 2: Document OCR / extraction

### Current reality
- `DocumentStoreRoute.tsx:74-99` "Scavenge" returns hardcoded extraction and `applyScavengedData` writes it to real db without review.
- `LedgerRoute.tsx:65-78` "Scavenge Statements" is a similar mock.

### Why not production-real
- No OCR engine integrated.
- No confidence scoring.
- No review step.

### Phased plan

#### Phase 1 (M6) — local OCR + review
- Tesseract.js (browser-side, no network) for image / PDF-rasterized text.
- Output a structured `ExtractionDraft` per document with per-field confidence.
- Review UI: side-by-side document preview + extracted-fields editor + confidence indicator.
- Commit only on user click; provenance pointer (`documentId`) stored on every created record.

**Adapter shape:**
```ts
interface OcrProvider {
  extract(blob: Blob, hint?: 'paystub'|'bill'|'bank-statement'|'tax-form'): Promise<ExtractionDraft>;
}

interface ExtractionDraft {
  fields: Array<{ name: string; value: string|number; confidence: number; bbox?: BBox }>;
  raw: string;
}
```

#### Phase 2 (post-M9) — vision-LLM extraction (opt-in)
- For PDFs where Tesseract struggles: optional cloud vision model (Claude / GPT-4V).
- Same review-before-commit gate.
- Privacy: explicit consent per upload; never automatic.

### UI handling for degraded states
- If no OCR provider configured: upload still works; "Extract" button shows "OCR not configured — see Settings."
- If extraction confidence < threshold for any field: that field is highlighted and requires explicit user confirmation.

### Security / privacy controls
- Phase 1 is fully local — no network.
- Phase 2 sends document content to provider only with per-upload consent.

### Validation
- M6 test: known sample paystub → extraction → expected field values within tolerance.
- M6 manual QA: upload bill PDF → extract → confidence ≥ 0.7 on amount field.

---

## Integration domain 3: AI assistant

### Current reality
- `BeaconChatbot.tsx:44-62` is `setTimeout` + canned `if/else`.
- `aiConfig` Dexie table exists but Settings AI Config form doesn't write to it (`SettingsRoute.tsx:241-266`).

### Why not production-real
- No provider abstraction.
- No persistent config.
- No prompt strategy.
- No write-confirmation pattern.

### Phased plan

#### Phase 1 (M3) — wire config persistence
- Settings AI Config form writes to `aiConfig` table.
- Validation: ping configured endpoint; report success/failure.
- No actual chat behavior changes yet.

#### Phase 2 (M7) — local provider integration
- Default provider: local Ollama (or any OpenAI-compatible endpoint user supplies).
- Adapter shape:
```ts
interface AiProvider {
  id: string;
  isLocal: boolean;
  chat(messages: ChatMessage[], opts?: { tools?: Tool[] }): AsyncIterable<ChatChunk>;
}
```
- Chatbot reads from `aiConfig`; if no provider configured, shows "Configure AI in Settings" instead of fake responses.

#### Phase 3 (M7) — cloud provider opt-in
- Anthropic / OpenAI as additional `AiProvider` impls.
- Settings UI clearly distinguishes local vs cloud.
- Default is local.

#### Phase 4 (post-M9) — action proposals with confirmation
- AI may propose actions ("Categorize 12 transactions as Groceries?", "Add bill detected in document X?").
- Every proposal renders as a diff preview with Accept / Reject buttons.
- No write happens until user accepts.
- All accepted actions logged to a new `aiActionLog` table for audit.

### UI handling for degraded states
- No provider configured: chatbot disabled with helpful "Configure" link.
- Provider errors: toast with retry; conversation persists.

### Security / privacy controls
- Local provider: data never leaves device.
- Cloud provider: warning banner on Settings; redaction of payee names + amounts unless explicit "Share full data" toggle on.
- Never send full database; send only the relevant slice for the question.
- Conversation history stored locally in `chatMessages`; option to clear.

### Validation
- M7 test: configured provider → real response; missing provider → graceful "configure" message.
- M7 test: action proposal flow → reject → no db change; accept → exact diff applied.

---

## Integration domain 4: Credit snapshot / fetch

### Current reality
- `CreditRoute.tsx:57-74` "Bank Fetch" and "Free Credit Check" are `Math.random` score generators.
- Manual snapshot entry is real and works.

### Why not production-real
- Consumer-facing credit bureau APIs are gated, paid, and identity-verified. Realistically unavailable to a household app.

### Phased plan

#### Phase 1 (M3 or M8) — remove mocks, lean on manual
- Delete the two fake-fetch buttons.
- Keep manual snapshot entry as the honest baseline.
- Add reminder cadence ("Snapshot last entered 47 days ago — update?").

#### Phase 2 (deferred indefinitely) — third-party widgets
- Could embed a free-credit-monitoring iframe (Credit Karma, etc.) as an external link out, never as an in-app fetch.

### UI handling
- "How to get your score" link to Annual Credit Report / bureau direct.
- Manual entry is primary, not secondary.

### Security / privacy controls
- Never store SSN or identity data in app.

### Validation
- Manual.

---

## Integration domain 5: Device sync (Beacon Bridge)

### Current reality
- `BeaconBridgeRoute.tsx:21, 28-37` simulates a "Partner's Phone" pairing and writes a fake `syncLogs` row.

### Why not production-real
- Real P2P sync requires either signaling server (WebRTC) or paired discovery (BLE / mDNS) — non-trivial.
- Conflict resolution model not yet defined.

### Phased plan

#### Phase 1 (M9) — signed export/import bundle
- "Send to other device" → produces a signed JSON bundle (HMAC with shared passphrase).
- Other device imports bundle → preview diff → merge or replace.
- Manual delivery (USB, AirDrop, email-to-self) — no network required.

#### Phase 2 (post-M9) — local-network pairing
- Capacitor Bonjour / mDNS for device discovery on same Wi-Fi.
- File transfer via local HTTP server on one device.

#### Phase 3 (deferred) — WebRTC P2P
- Signaling via lightweight relay; data over WebRTC datachannel.
- Only after conflict-resolution model is solid.

### Conflict resolution model (must precede Phase 1)
- Per-record timestamp + device-id (`updatedAt`, `lastWriterDevice`).
- Last-writer-wins by default.
- Merge UI for explicit conflicts (same record, different fields, conflicting timestamps).

### UI handling
- "Last sync: never" / "Last sync: 2026-04-23 from Phone" status.
- Diff preview before commit.

### Security / privacy
- Bundles HMAC-signed with shared passphrase; rejected if signature invalid.
- Phase 3 WebRTC: TURN/STUN config user-supplied or default to no-TURN local-only.

### Validation
- M9 test: export from device A → import on device B → records identical.
- M9 test: conflicting edits → merge UI surfaces both → user picks → result correct.

---

## Integration domain 6: Export / import / reports

### Current reality
- `SettingsRoute.tsx:26-53` real JSON export/import.
- `ReportsRoute.tsx:35` Export is `alert()`.

### Why not production-real
- No schema versioning on JSON backup.
- No CSV report export.
- No PDF report.

### Phased plan

#### Phase 1 (M4) — versioned JSON + CSV reports
- JSON backup gets `schemaVersion` field; import migrates older versions.
- CSV exports per entity (transactions, bills, debts, goals).
- Round-trip integrity test.

#### Phase 2 (M4) — print-to-PDF reports
- Use `window.print()` with a dedicated print stylesheet for monthly household, debt, savings, tax-summary, document-inventory reports.

#### Phase 3 (post-M9) — generated PDF
- Optional jsPDF or PDF-lib if print-to-PDF proves insufficient.

### Security / privacy
- Backup includes everything; warn user before download about sensitivity.
- Optional passphrase-encrypted backup (Phase 3).

### Validation
- M4 round-trip: export → wipe → import → assert deep-equal across all tables.

---

## Integration domain 7: Tax document handling

### Current reality
- `TaxTaxiRoute.tsx:233-234` placeholder fields ("Entity / Payer", "Gross Telemetry").
- `taxRecords`, `taxTransactions`, `taxForms` Dexie tables exist.

### Why not production-real
- No real form schema.
- No calculation engine.
- No IRS-form generation.

### Phased plan

#### Phase 1 (M8) — manual draft assist
- Real fields: filer person, year, document type (W-2, 1099-NEC, 1099-INT, 1098, etc.), amounts, withholding, source.
- Save to `taxRecords` / `taxForms`.
- Honest label: "Manual draft — not a substitute for filing software."

#### Phase 2 (deferred) — annual packet export
- One-click "Export 2025 tax packet" → ZIP of all tax documents + summary CSV + linked Vault PDFs.

#### Phase 3 (deferred indefinitely) — actual form generation
- Out of scope for now. Real tax software is a separate domain.

### Validation
- M8: enter sample W-2 → save → reload → fields persist.

---

## Cross-cutting: feature-flag strategy

A simple `featureFlags` map in `aiConfig` (or new `featureFlags` table). Each integration gates its UI on the flag.

```ts
{
  bankImportTierA: true,           // M5 ships → on
  bankAggregatorTierB: false,      // off until vendor chosen
  ocrLocal: true,                  // M6 ships → on
  ocrVisionCloud: false,           // off by default
  aiLocal: false,                  // off until M7
  aiCloud: false,                  // off, opt-in
  syncBundleExport: true,          // M9 ships → on
  syncLocalNetwork: false,         // off
  syncWebRTC: false,               // off
}
```

Mocked surfaces removed before their feature flag is true → user sees "Coming in M_n" instead of fake behavior.

---

## Cross-cutting: validation & rollback

- Every integration adapter ships with: unit tests on the adapter, integration test on the happy-path, and one failure-mode test.
- Every integration that writes to db has a rollback path (review-before-commit OR audit log of writes).
- New adapters never replace existing manual-entry flows; they augment.

---

## Open decisions (do not resolve in M0)

1. Aggregator vendor (M5 Phase 2): Plaid vs MX vs Akoya. Defer until Tier A is proven insufficient.
2. Local AI runtime (M7): Ollama vs LM Studio vs llama.cpp directly. Defer until config persistence (M3) lands.
3. PDF strategy (M4 Phase 3): print-CSS only vs jsPDF. Try print-CSS first.
4. Sync passphrase UX (M9): per-bundle vs one-time pairing. Defer to M9 design.
