import { Component, type ErrorInfo, type ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: (error: Error, reset: () => void) => ReactNode;
  scope?: string;
}

interface State {
  error: Error | null;
}

export class ErrorBoundary extends Component<Props, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error(`[ErrorBoundary${this.props.scope ? ":" + this.props.scope : ""}]`, error, info);
  }

  reset = () => this.setState({ error: null });

  render() {
    const { error } = this.state;
    if (!error) return this.props.children;

    if (this.props.fallback) return this.props.fallback(error, this.reset);

    return (
      <div
        role="alert"
        style={{
          padding: "1.5rem",
          margin: "1.5rem",
          borderRadius: "0.75rem",
          border: "1px solid rgba(239, 68, 68, 0.4)",
          background: "rgba(15, 15, 20, 0.85)",
          color: "#f5f5f5",
          fontFamily: "system-ui, sans-serif",
        }}
      >
        <h2 style={{ marginTop: 0, color: "#f87171" }}>
          Something broke{this.props.scope ? ` in ${this.props.scope}` : ""}.
        </h2>
        <p style={{ opacity: 0.8 }}>
          The app caught a render error and stopped this section from crashing the whole UI.
          Your data is safe.
        </p>
        <pre
          style={{
            background: "rgba(0, 0, 0, 0.4)",
            padding: "0.75rem",
            borderRadius: "0.5rem",
            overflowX: "auto",
            fontSize: "0.75rem",
            maxHeight: "10rem",
          }}
        >
          {error.message}
        </pre>
        <button
          onClick={this.reset}
          style={{
            marginTop: "0.75rem",
            padding: "0.5rem 1rem",
            borderRadius: "0.5rem",
            border: "1px solid rgba(255,255,255,0.2)",
            background: "rgba(255,255,255,0.05)",
            color: "inherit",
            cursor: "pointer",
          }}
        >
          Try again
        </button>
      </div>
    );
  }
}
