import * as React from "react";
import { cn } from "../../lib/utils";

interface FormFieldProps {
  id: string;
  label: React.ReactNode;
  error?: React.ReactNode;
  hint?: React.ReactNode;
  required?: boolean;
  className?: string;
  children:
    | React.ReactElement<{
        id?: string;
        "aria-invalid"?: boolean;
        "aria-describedby"?: string;
        "aria-required"?: boolean;
      }>
    | ((p: {
        id: string;
        "aria-invalid": boolean;
        "aria-describedby"?: string;
        "aria-required"?: boolean;
      }) => React.ReactElement);
}

/**
 * Pairs a `<label htmlFor>` with a single form control and routes
 * `aria-invalid`, `aria-describedby`, and `aria-required` automatically.
 *
 * Two usage styles:
 *
 *   <FormField id="email" label="Email" error={errors.email?.message}>
 *     <input type="email" {...register('email')} />
 *   </FormField>
 *
 *   <FormField id="amount" label="Amount" error={...}>
 *     {(props) => <CurrencyInput {...register('amount')} {...props} />}
 *   </FormField>
 */
export function FormField({ id, label, error, hint, required, className, children }: FormFieldProps) {
  const errorId = `${id}-error`;
  const hintId = `${id}-hint`;
  const describedBy = [error ? errorId : null, hint ? hintId : null].filter(Boolean).join(" ") || undefined;
  const isInvalid = Boolean(error);

  const ariaProps = {
    id,
    "aria-invalid": isInvalid,
    "aria-describedby": describedBy,
    "aria-required": required,
  } as const;

  let control: React.ReactNode;
  if (typeof children === "function") {
    control = children(ariaProps);
  } else {
    control = React.cloneElement(children, ariaProps);
  }

  return (
    <div className={cn("space-y-1.5", className)}>
      <label
        htmlFor={id}
        className={cn(
          "text-sm font-medium leading-none",
          isInvalid ? "text-destructive" : "text-foreground",
        )}
      >
        {label}
        {required && (
          <span aria-hidden="true" className="ml-0.5 text-destructive">
            *
          </span>
        )}
      </label>

      {control}

      {hint && !error && (
        <p id={hintId} className="text-xs text-muted-foreground">
          {hint}
        </p>
      )}
      {error && (
        <p id={errorId} role="alert" className="text-xs font-medium text-destructive">
          {error}
        </p>
      )}
    </div>
  );
}
