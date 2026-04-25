import React from "react";
import { Card } from "./card";
import { cn } from "../../lib/utils";

interface GlassCardProps extends React.HTMLAttributes<HTMLDivElement> {
  intensity?: "low" | "medium" | "high";
  hoverable?: boolean;
  children?: React.ReactNode;
}

export function GlassCard({ 
  intensity = "medium", 
  hoverable = false, 
  className, 
  children, 
  ...props 
}: GlassCardProps) {
  const blurClasses = {
    low: "backdrop-blur-md",
    medium: "backdrop-blur-xl",
    high: "backdrop-blur-3xl"
  };

  return (
    <Card 
      className={cn(
        "border-primary/10 bg-card/40 transition-all duration-300",
        blurClasses[intensity],
        hoverable && "hover:border-primary/30 hover:shadow-2xl hover:scale-[1.01] cursor-default",
        className
      )}
      {...props}
    >
      {children}
    </Card>
  );
}
