/**
 * Native status-bar integration for the Android (Capacitor) build.
 *
 * capacitor.config.ts sets `StatusBar.overlaysWebView: true`, so the WebView
 * draws *under* the status bar and the app is responsible for (a) padding its
 * top chrome by `env(safe-area-inset-top)` (done in the shell CSS) and
 * (b) choosing status-bar icon colour that contrasts the current theme.
 *
 * All calls are no-ops on web/desktop (guarded by Capacitor.isNativePlatform),
 * and the status-bar plugin is imported dynamically so the web/Electron bundle
 * never pulls native code.
 */
import { Capacitor } from "@capacitor/core";

let cachedNative: boolean | null = null;

function isNative(): boolean {
  if (cachedNative === null) {
    try {
      cachedNative = Capacitor.isNativePlatform();
    } catch {
      cachedNative = false;
    }
  }
  return cachedNative;
}

/** Luminance of the resolved theme background — theme-name agnostic. */
function backgroundIsDark(): boolean {
  try {
    const sample =
      getComputedStyle(document.body).backgroundColor ||
      getComputedStyle(document.documentElement).backgroundColor;
    const parts = sample.match(/[\d.]+/g);
    if (!parts || parts.length < 3) return true; // default to dark UI
    const [r, g, b] = parts.map(Number);
    // Rec. 601 relative luminance, 0..1
    const lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return lum < 0.5;
  } catch {
    return true;
  }
}

let configured = false;

/** Idempotent one-time native chrome setup. */
async function ensureConfigured(): Promise<void> {
  if (configured) return;
  configured = true;
  try {
    const { StatusBar } = await import("@capacitor/status-bar");
    await StatusBar.setOverlaysWebView({ overlay: true });
  } catch {
    /* plugin unavailable — ignore */
  }
}

/**
 * Sync the status-bar icon style to the current theme. Safe to call on every
 * theme change; no-op off-device.
 */
export async function syncStatusBar(): Promise<void> {
  if (!isNative()) return;
  await ensureConfigured();
  try {
    const { StatusBar, Style } = await import("@capacitor/status-bar");
    // Capacitor semantics: Style.Dark = dark background -> light icons;
    // Style.Light = light background -> dark icons.
    await StatusBar.setStyle({ style: backgroundIsDark() ? Style.Dark : Style.Light });
  } catch {
    /* plugin unavailable — ignore */
  }
}
