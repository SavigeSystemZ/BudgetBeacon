import React from "react";
import { cn } from "../../lib/utils";

interface PageHeaderProps {
  title: string;
  subtitle?: string;
  actions?: React.ReactNode;
  className?: string;
  titleClassName?: string;
}

export function PageHeader({ title, subtitle, actions, className, titleClassName }: PageHeaderProps) {
  return (
    <div className={cn("flex flex-col gap-2 md:flex-row md:items-center md:justify-between mb-8", className)}>
      <div>
        <h1 className={cn("text-4xl font-black tracking-tighter italic uppercase text-primary drop-shadow-sm", titleClassName)}>
          {title}
        </h1>
        {subtitle && <p className="text-muted-foreground font-medium">{subtitle}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}
