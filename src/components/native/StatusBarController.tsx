import { useEffect } from "react";
import { useTheme } from "../theme-provider";
import { syncStatusBar } from "../../lib/native/statusBar";

/**
 * Renders nothing. Keeps the native Android status-bar icon style in sync with
 * the active theme. Must live inside <ThemeProvider>. No-op on web/desktop.
 */
export function StatusBarController() {
  const { theme } = useTheme();

  useEffect(() => {
    // Defer one frame so the theme class is applied to <html> and the
    // resolved background colour is readable before we sample luminance.
    const id = requestAnimationFrame(() => {
      void syncStatusBar();
    });
    return () => cancelAnimationFrame(id);
  }, [theme]);

  return null;
}
