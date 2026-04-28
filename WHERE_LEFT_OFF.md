# Where Left Off — 2026-04-28 (M7 substantial close)

> **Status: M7 closed (read-only).** Real AI assistant via local Ollama or OpenAI-compatible cloud, grounded in real db aggregates. Tool-use / action proposals deferred to M7.2. M0–M7 are honest, tested, committed.

## What just happened (this session)

Two milestones landed back-to-back:

### M6 — Vault + OCR (already in working tree, validated and shipped)
- `src/modules/ocr/` — `OcrProvider` interface, Tesseract.js wrapper (browser-side, no network), regex field extractor, `applyExtractionToDb` committing to incomeSources/bills/taxRecords with documentId provenance
- `VaultExtractionReview` modal: per-field confidence + edit, no auto-commit
- `featureFlags.ocrLocal = true`. Audit baseline updated to setTimeout=5 (legit OnboardingWizard auto-dismiss)

### M7 — AI Assistant Real Integration ✨ NEW
- **`src/modules/ai/types.ts`** — `AiProvider` interface, `ChatMessage` / `ChatOptions`, `AiProviderError`
- **`src/modules/ai/ollamaProvider.ts`** — talks to `/api/chat`, `stream: false`, normalizes endpoint forms (rewrites legacy `/api/generate` → `/api/chat`)
- **`src/modules/ai/openAiCompatibleProvider.ts`** — POSTs `/v1/chat/completions` with Bearer auth. Works with OpenAI, Groq, Together, OpenRouter, LM Studio, llama.cpp, vLLM
- **`src/modules/ai/providerFactory.ts`** — `resolveActiveProvider()` reads aiConfig and returns the right provider or `{provider: null, reason}`
- **`src/modules/ai/contextBuilder.ts`** — `buildAssistantContext()` runs the budget engine + stability index, returns a system prompt that grounds the model in real numbers (no hallucinated income/bills)
- **`src/components/BeaconChatbot.tsx`** — rewritten. Status indicator (Local / Cloud / Not configured), real `provider.chat()` call with last 8 turns of history, AbortController + Stop button, surfaced error state, honest no-provider fallback that cites real db aggregates instead of canned replies
- **`src/modules/ai/ai.test.ts`** — 16 new tests: URL normalization (Ollama + OpenAI), response shape parsing, network error wrapping, missing-key guard, factory resolution for all 4 cases (local with/without endpoint, api with/without key)
- **`featureFlags.aiAssistantLocal` and `aiAssistantCloud` flipped to true**

### Roadmap docs
- `ROADMAP.md` updated with M6 ✅ and M7 ✅ states
- `TODO.md` queues M7.2 (streaming, tool-use, health-check) as parallel small slices and reorders main path: M8 → M9 → M10 → M11 → M12
- `PLAN.md` active slice now points at M8

## Honest state of the app

### Real
- 15 routes. Dexie v4 with 18 tables. Real CRUD on every entity.
- Backup format v3 (covers all tables incl. documents Blob via base64).
- Real CSV exports per entity + JSON full backup. Restore with diff preview.
- Real CSV import for Ledger.
- Real OCR for Vault (Tesseract.js, per-field confidence, edit-before-commit, documentId provenance).
- **Real AI assistant.** Local Ollama default; cloud opt-in via OpenAI-compatible endpoint. System prompt grounded in real db. No fake replies.
- 87 unit tests across budget engine, stash-map, frequency, base64, csv, dedupe, mapper, partition, stability index, backup round-trip, OCR field extraction, applyExtraction routing, AI URL normalization, AI provider response parsing, AI factory resolution.
- Error boundaries (root + per-route). Audit-controls regression tool.

### Still mocked / unbuilt
- **Tax Taxi forms** — 2-field placeholder. M8 owns.
- **Beacon Bridge route** — old single-button mock. M9 swaps it for "Sync coming in M10" panel; M10/M11 rebuild against the real CRDT transport.
- **Auth, multi-device sync, joint households** — none of this exists. M10 + M11. Architecture in `docs/SYNC_AND_DUAL_ACCOUNT_ARCHITECTURE.md`. **Three sign-off gates** still open: transport choice / passphrase model / relay green-light.
- **AI tool-use / action proposals** — assistant is read-only. M7.2 will add a confirmation-modal flow for proposed db writes.

## Where to pick up next (in priority order)

1. **M8 — Tax / Credit / Debt deepening.** Tax Taxi proper form fields or honest manual labeling (currently 2 placeholder inputs). Avalanche vs snowball comparison. Mission Control cross-module rebuild.
2. **M9 — Android / Web polish.** Real-device APK smoke, safe-area pass, Capacitor version pin, code-split the 1.1 MB main bundle (React.lazy each route), Beacon Bridge "Coming in M10" stub.
3. **M10 — Auth + Sync.** *Blocked on user sign-off* (transport / passphrase / relay).

**Parallel small slices any session can pick up:**
- **M7.2 streamed token rendering** — both Ollama (`stream: true` JSONL) and OpenAI-compatible (`text/event-stream`) support it. The abstraction is ready; just need to add an async iterable variant.
- **M7.2 tool-use** — structured action proposals (e.g. "Add $1450 SSDI income"). Confirmation modal before any db write.
- **M7.2 provider health-check** — "Test connection" button in Settings → AI Configuration.

## Build / sync state
- `npm test` — **87 passed** (verified 2026-04-28)
- `npm run typecheck` — clean
- `npm run audit:controls` — baseline `setTimeout=5 mathRandom=0 alert=0 emptyOnClick=0`
- `npm run build` — clean (1.1 MB main bundle; chunk-split queued for M9)

## How to test the assistant locally

```bash
# Install Ollama, then:
ollama pull llama3.2
ollama serve

# In Budget Beacon:
# Settings → AI Configuration → Provider: Local → Endpoint: http://localhost:11434 → Model: llama3.2 → Save
# Open the chatbot. Ask "Analyze my budget."
```

## Hard rules for the next agent

1. **Do not start M10 code without user sign-off** on transport (A/B/C), passphrase model, and relay deployment.
2. **Do not regress audit-controls counts.** New legit UX timer? Update `tools/audit-controls.baseline.json` in the same commit and explain why.
3. **Do not silently delete the Beacon Bridge route.** Stub it; rebuild in M10.
4. **Do not add silent db writes from the chatbot.** The assistant is read-only until M7.2 ships explicit confirmation UI.
5. **Stable IDs (`createId()` UUIDs) and per-record `personId` are load-bearing for M10 + M11.** Don't drop either.
