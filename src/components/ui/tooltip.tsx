import * as React from "react"
import { cn } from "../../lib/utils"

const TooltipProvider = ({ children }: { children: React.ReactNode }) => <>{children}</>

const Tooltip = ({ children }: { children: React.ReactNode; delayDuration?: number }) => {
  const [open, setOpen] = React.useState(false)
  return React.Children.map(children, (child) => {
    if (React.isValidElement(child)) {
      return React.cloneElement(child as React.ReactElement<any>, {
        onMouseEnter: () => setOpen(true),
        onMouseLeave: () => setOpen(false),
        className: cn((child.props as any).className, "relative"),
        "data-state": open ? "open" : "closed"
      })
    }
    return child
  })
}

const TooltipTrigger = ({ children }: { children: React.ReactNode; asChild?: boolean }) => {
  return <>{children}</>
}

const TooltipContent = ({ className, children }: { className?: string; children: React.ReactNode }) => {
  return (
    <div
      className={cn(
        "z-[100] overflow-hidden rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95 data-[state=closed]:animate-out data-[state=closed]:fade-out-0 data-[state=closed]:zoom-out-95",
        "absolute bottom-full left-1/2 -translate-x-1/2 mb-2",
        className
      )}
    >
      {children}
    </div>
  )
}

export { Tooltip, TooltipTrigger, TooltipContent, TooltipProvider }
