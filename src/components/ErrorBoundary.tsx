import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: (error: Error, reset: () => void) => ReactNode;
  scope?: string;
}

interface State {
  error: Error | null;
  info: ErrorInfo | null;
  copied: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null, info: null, copied: false };

  static getDerivedStateFromError(error: Error): State {
    return { error, info: null, copied: false };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // Boundary uses bare console.error intentionally — it must work even if
    // the logger module ever fails to load.
    console.error(`[ErrorBoundary${this.props.scope ? ":" + this.props.scope : ""}]`, error, info);
    this.setState({ info });
  }

  reset = () => this.setState({ error: null, info: null, copied: false });

  buildReport = (): string => {
    const { error, info } = this.state;
    if (!error) return "";
    const lines = [
      `Budget Beacon error report`,
      `Scope: ${this.props.scope ?? "root"}`,
      `When: ${new Date().toISOString()}`,
      `Where: ${typeof window !== "undefined" ? window.location.href : "n/a"}`,
      `User agent: ${typeof navigator !== "undefined" ? navigator.userAgent : "n/a"}`,
      ``,
      `Message: ${error.message}`,
      ``,
      `Stack:`,
      error.stack ?? "(no stack)",
    ];
    if (info?.componentStack) {
      lines.push("", "Component stack:", info.componentStack);
    }
    return lines.join("\n");
  };

  copyReport = async () => {
    const report = this.buildReport();
    if (!report) return;
    try {
      if (typeof navigator !== "undefined" && navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(report);
        this.setState({ copied: true });
        return;
      }
    } catch {
      // Fall through to textarea fallback for older WebViews / locked-down env.
    }
    try {
      const ta = document.createElement("textarea");
      ta.value = report;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      document.body.removeChild(ta);
      this.setState({ copied: true });
    } catch {
      // Last resort — leave copied=false so the UI doesn't lie about success.
    }
  };

  render() {
    const { error, copied } = this.state;
    if (!error) return this.props.children;

    if (this.props.fallback) return this.props.fallback(error, this.reset);

    return (
      <div
        role="alert"
        aria-live="assertive"
        className="m-6 rounded-xl border border-destructive/40 bg-card/90 p-6 text-card-foreground shadow-lg backdrop-blur-sm"
      >
        <h2 className="m-0 text-lg font-semibold text-destructive">
          Something broke{this.props.scope ? ` in ${this.props.scope}` : ""}.
        </h2>
        <p className="mt-2 text-sm text-muted-foreground">
          The app caught a render error and stopped this section from crashing the whole UI.
          Your data is safe.
        </p>
        <pre className="mt-3 max-h-40 overflow-x-auto rounded-md bg-background/60 p-3 text-xs text-foreground/90">
          {error.message}
        </pre>
        <div className="mt-4 flex flex-wrap gap-2">
          <button
            type="button"
            onClick={this.reset}
            className="inline-flex items-center rounded-md border border-border bg-background/50 px-3 py-1.5 text-sm font-medium text-foreground hover:bg-background/80 focus:outline-none focus:ring-2 focus:ring-ring"
          >
            Try again
          </button>
          <button
            type="button"
            onClick={this.copyReport}
            aria-live="polite"
            className="inline-flex items-center rounded-md border border-border bg-background/50 px-3 py-1.5 text-sm font-medium text-foreground hover:bg-background/80 focus:outline-none focus:ring-2 focus:ring-ring"
          >
            {copied ? "Report copied ✓" : "Copy report"}
          </button>
        </div>
      </div>
    );
  }
}
