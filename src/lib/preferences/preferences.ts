/**
 * Typed localStorage-backed preferences.
 *
 * Lightweight layer for user-toggleable UI settings that don't need to live in
 * Dexie (theme is handled by theme-provider; AI provider config goes to the
 * aiConfig Dexie table). M2/M3 baseline; M4 may migrate this to a Dexie
 * `preferences` table if multi-device sync requires it.
 */
const STORAGE_KEY = "budget-beacon:preferences:v1";

export interface Preferences {
  billDueReminders: boolean;
  budgetDeficitWarnings: boolean;
  sensitiveValueMasking: boolean;
  autoCategorizePayees: boolean;
  predictiveStashMapping: boolean;
}

export const defaultPreferences: Preferences = {
  billDueReminders: true,
  budgetDeficitWarnings: false,
  sensitiveValueMasking: true,
  autoCategorizePayees: false,
  predictiveStashMapping: false,
};

export function loadPreferences(): Preferences {
  if (typeof window === "undefined") return defaultPreferences;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultPreferences;
    const parsed = JSON.parse(raw);
    // Merge with defaults so newly added preference keys get the default.
    return { ...defaultPreferences, ...parsed };
  } catch {
    return defaultPreferences;
  }
}

export function savePreferences(prefs: Preferences): void {
  if (typeof window === "undefined") return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(prefs));
  } catch (err) {
    console.error("[preferences] save failed:", err);
  }
}
