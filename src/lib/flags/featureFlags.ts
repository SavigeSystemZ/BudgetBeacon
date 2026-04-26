/**
 * Feature flags for Budget Beacon.
 *
 * Each flag gates a UI surface that is not yet a real implementation.
 * Default `false` while the surface is mocked / not built; flip to `true`
 * in the milestone that ships the real version.
 *
 * See docs/INTEGRATIONS_STRATEGY.md for which flag belongs to which phase.
 *
 * NOTE: This is intentionally a static module (not a Dexie-backed setting).
 * Runtime user-toggleable flags can come later; for M3 the goal is to keep
 * fake surfaces off by default and label them "Demo" so the user is never
 * misled into thinking a fake button did real work.
 */
export const featureFlags = {
  // Bank import (M5 owns)
  bankImportTierA: true, // CSV file import + dedupe + review queue (M5 — QFX/OFX scaffolded later)
  bankAggregatorTierB: false, // Plaid / MX / Finicity opt-in
  bankInstitutionTierC: false, // Institution-specific direct APIs

  // Document OCR (M6 owns)
  ocrLocal: false, // Tesseract.js browser-side OCR + per-field confidence
  ocrVisionCloud: false, // Optional cloud vision-LLM extraction

  // AI assistant (M7 owns)
  aiAssistantLocal: false, // Local Ollama / OpenAI-compatible endpoint
  aiAssistantCloud: false, // Cloud provider (Anthropic, OpenAI) — opt-in only

  // Credit (M8 — manual entry is the long-term honest baseline; no real fetch planned)
  creditBureauFetch: false, // No realistic provider; likely permanently false

  // Sync (M9 owns)
  syncBundleExport: false, // Signed JSON bundle pairing
  syncLocalNetwork: false, // mDNS / Bonjour pairing
  syncWebRTC: false, // P2P over WebRTC

  // Reports (M4 owns)
  reportsRealExport: true, // CSV per entity + JSON backup shortcut (PDF still via window.print() in M4)

  // Insurance (M9 owns)
  insuranceMarketScrape: false, // No realistic provider; likely permanently false
} as const;

export type FeatureFlagKey = keyof typeof featureFlags;

export function isEnabled(flag: FeatureFlagKey): boolean {
  return featureFlags[flag];
}
