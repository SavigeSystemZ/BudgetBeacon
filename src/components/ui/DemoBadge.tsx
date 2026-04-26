import type { ReactNode } from "react";

interface DemoBadgeProps {
  /** Which milestone owns the real version (e.g. "M5", "M6", "M9"). */
  milestone?: string;
  /** Short explanation of what's not real yet. */
  children?: ReactNode;
}

/**
 * Visible, honest label for surfaces that exist in the UI but are not yet
 * a real implementation. Replaces the prior pattern of fake setTimeout +
 * hardcoded data presented as if it were live.
 *
 * Usage:
 *   <DemoBadge milestone="M5">Bank import is not connected yet.</DemoBadge>
 */
export function DemoBadge({ milestone, children }: DemoBadgeProps) {
  return (
    <div
      role="note"
      aria-label="Demo notice"
      style={{
        display: "inline-flex",
        alignItems: "center",
        gap: "0.5rem",
        padding: "0.4rem 0.75rem",
        borderRadius: "0.5rem",
        border: "1px dashed rgba(250, 204, 21, 0.5)",
        background: "rgba(250, 204, 21, 0.08)",
        color: "rgb(250, 204, 21)",
        fontSize: "0.75rem",
        fontFamily: "system-ui, sans-serif",
        lineHeight: 1.3,
      }}
    >
      <span
        style={{
          fontWeight: 600,
          letterSpacing: "0.05em",
          textTransform: "uppercase",
        }}
      >
        Demo{milestone ? ` · ${milestone}` : ""}
      </span>
      {children && <span style={{ opacity: 0.85 }}>{children}</span>}
    </div>
  );
}
