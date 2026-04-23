import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import { cn } from "../../lib/utils";
import React from "react";

interface MetricCardProps {
  title: string;
  value: number;
  description?: string;
  icon?: React.ReactNode;
  trend?: "up" | "down" | "neutral";
  trendValue?: string;
  isCurrency?: boolean;
  className?: string;
}

export function MetricCard({
  title,
  value,
  description,
  icon,
  trend,
  trendValue,
  isCurrency = true,
  className,
}: MetricCardProps) {
  const formattedValue = isCurrency
    ? `$${value.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`
    : value.toLocaleString();

  return (
    <Card className={cn("overflow-hidden group hover:-translate-y-1 hover:shadow-[0_8px_30px_rgb(0,0,0,0.12)] dark:hover:shadow-[0_8px_30px_rgba(255,255,255,0.05)] hover:border-primary/30", className)}>
      <CardHeader className="flex flex-row items-center justify-between pb-2 space-y-0">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        {icon && <div className="text-muted-foreground">{icon}</div>}
      </CardHeader>
      <CardContent>
        <div className="text-2xl font-bold">{formattedValue}</div>
        {(description || trendValue) && (
          <p className="text-xs text-muted-foreground mt-1 flex items-center gap-1">
            {trendValue && (
              <span
                className={cn(
                  "font-medium",
                  trend === "up" ? "text-green-600 dark:text-green-400" : "",
                  trend === "down" ? "text-destructive" : "",
                  trend === "neutral" ? "text-muted-foreground" : ""
                )}
              >
                {trend === "up" ? "↑" : trend === "down" ? "↓" : ""} {trendValue}
              </span>
            )}
            {description && <span>{description}</span>}
          </p>
        )}
      </CardContent>
    </Card>
  );
}
