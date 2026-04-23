import * as React from "react"
import { cn } from "../../lib/utils"

export type NativeSelectProps = React.SelectHTMLAttributes<HTMLSelectElement>

const NativeSelect = React.forwardRef<HTMLSelectElement, NativeSelectProps>(
  ({ className, children, ...props }, ref) => {
    return (
      <select
        ref={ref}
        className={cn(
          "flex h-9 w-full items-center justify-between rounded-lg border border-white/20 dark:border-white/10 bg-background/40 dark:bg-background/20 backdrop-blur-xl px-3 py-1 text-sm shadow-sm transition-all duration-300 ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        {...props}
      >
        {children}
      </select>
    )
  }
)
NativeSelect.displayName = "NativeSelect"

export { NativeSelect }
