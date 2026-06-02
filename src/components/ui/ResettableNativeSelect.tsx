import * as React from "react"
import { NativeSelect, type NativeSelectProps } from "./native-select"
import { Button } from "./button"
import { RotateCcw } from "lucide-react"
import { useDeleteConfirm } from "../../context/DeleteConfirmContext"

export interface ResettableNativeSelectProps extends NativeSelectProps {
  onResetValue?: () => void;
  label?: string;
}

export const ResettableNativeSelect = React.forwardRef<HTMLSelectElement, ResettableNativeSelectProps>(
  ({ className, onResetValue, label, children, ...props }, ref) => {
    const confirm = useDeleteConfirm();

    const handleReset = async (e: React.MouseEvent) => {
      e.preventDefault();
      const confirmed = await confirm("field reset", `Are you sure you want to clear the ${label || 'field'}?`);
      if (confirmed && onResetValue) {
        onResetValue();
      }
    };

    return (
      <div className="relative flex items-center w-full">
        <NativeSelect ref={ref} className={className} {...props}>
          {children}
        </NativeSelect>
        {onResetValue && (
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={handleReset}
            className="absolute right-6 h-8 w-8 text-muted-foreground hover:text-destructive"
            aria-label={`Reset ${label || 'field'}`}
          >
            <RotateCcw className="h-4 w-4" />
          </Button>
        )}
      </div>
    )
  }
)
ResettableNativeSelect.displayName = "ResettableNativeSelect"
