/**
 * Budget Beacon — production-safe logger.
 *
 * In `import.meta.env.DEV` (vite dev / vitest) every level forwards to the
 * matching `console` method. In a production build the logger no-ops unless
 * the URL query string carries `?debug=1`, in which case it forwards to
 * `console.warn` / `.error` (`info` / `log` stay silent).
 *
 * The point is a hygiene gate, not a logging framework: code that previously
 * called `console.log` at module-load time would land in the user's devtools
 * forever. `logger.info(...)` keeps prod bundles quiet by default but lets a
 * support session enable verbose output without a rebuild.
 */

const isDev = ((): boolean => {
  try {
    return Boolean((import.meta as ImportMeta & { env?: { DEV?: boolean } }).env?.DEV);
  } catch {
    return false;
  }
})();

const isDebugFlagOn = ((): boolean => {
  if (typeof window === "undefined") return false;
  try {
    return new URLSearchParams(window.location.search).get("debug") === "1";
  } catch {
    return false;
  }
})();

const verbose = isDev || isDebugFlagOn;

type LogArgs = unknown[];

function noop(): void {}

export const logger = {
  log: verbose ? (console.log.bind(console) as (...args: LogArgs) => void) : noop,
  info: verbose ? (console.info.bind(console) as (...args: LogArgs) => void) : noop,
  warn: verbose ? (console.warn.bind(console) as (...args: LogArgs) => void) : noop,
  // Errors are always surfaced — silent failures are worse than noisy ones.
  error: console.error.bind(console) as (...args: LogArgs) => void,
};
