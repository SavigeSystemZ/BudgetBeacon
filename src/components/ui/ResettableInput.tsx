import * as React from "react"
import { Input } from "./input"
import { Button } from "./button"
import { RotateCcw } from "lucide-react"
import { useDeleteConfirm } from "../../context/DeleteConfirmContext"

export interface ResettableInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  onResetValue?: () => void;
  label?: string;
}

export const ResettableInput = React.forwardRef<HTMLInputElement, ResettableInputProps>(
  ({ className, onResetValue, label, ...props }, ref) => {
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
        <Input ref={ref} className={className} {...props} />
        {onResetValue && (
          <Button
            type="button"
            variant="ghost"
            size="icon"
            onClick={handleReset}
            className="absolute right-1 h-8 w-8 text-muted-foreground hover:text-destructive"
            aria-label={`Reset ${label || 'field'}`}
          >
            <RotateCcw className="h-4 w-4" />
          </Button>
        )}
      </div>
    )
  }
)
ResettableInput.displayName = "ResettableInput"
