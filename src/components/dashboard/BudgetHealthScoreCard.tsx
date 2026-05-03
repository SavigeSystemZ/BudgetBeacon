import { CheckCircle, AlertCircle, XCircle, TrendingUp } from "lucide-react";
import { CardContent, CardHeader, CardTitle } from "../ui/card";
import { GlassCard } from "../ui/GlassCard";
import { Progress } from "../ui/progress";

export interface BudgetHealthScoreCardProps {
  /** Fraction of planned monthly income allocated to Stash Map (0–1+) */
  savingsRateFraction: number;
  /** Target savings rate as fraction of income, default 0.2 (20%) */
  targetSavingsFraction?: number;
  className?: string;
}

/**
 * Circular score + savings progress, adapted from donor "Budget Health Score" UI,
 * using Beacon tokens and Stash Map savings rate vs a configurable target.
 */
export function BudgetHealthScoreCard({
  savingsRateFraction,
  targetSavingsFraction = 0.2,
  className,
}: BudgetHealthScoreCardProps) {
  const savingsPercentOfIncome = savingsRateFraction * 100;
  const targetPercent = targetSavingsFraction * 100;
  const overallScore = Math.min(
    Math.round(targetSavingsFraction > 0 ? (savingsRateFraction / targetSavingsFraction) * 100 : 0),
    100
  );

  const scoreColor =
    overallScore >= 80 ? "text-emerald-500" : overallScore >= 60 ? "text-amber-500" : "text-destructive";

  const scoreLabel =
    overallScore >= 90
      ? "Excellent"
      : overallScore >= 80
        ? "Great"
        : overallScore >= 70
          ? "Good"
          : overallScore >= 60
            ? "Fair"
            : "Needs work";

  const ScoreIcon = overallScore >= 70 ? CheckCircle : overallScore >= 50 ? AlertCircle : XCircle;

  const progressTowardTarget = Math.min(Math.round((savingsRateFraction / targetSavingsFraction) * 100), 100);

  return (
    <GlassCard intensity="high" className={className}>
      <CardHeader className="pb-2">
        <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary flex items-center gap-2">
          <TrendingUp className="h-4 w-4" />
          Budget health score
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        <div className="flex flex-col items-center justify-center gap-4 sm:flex-row">
          <div className="relative h-32 w-32 shrink-0">
            <svg className="h-32 w-32 -rotate-90 transform" viewBox="0 0 128 128">
              <circle cx="64" cy="64" r="56" stroke="currentColor" strokeWidth="8" fill="none" className="text-border" />
              <circle
                cx="64"
                cy="64"
                r="56"
                stroke="currentColor"
                strokeWidth="8"
                fill="none"
                strokeDasharray={`${overallScore * 3.52} 352`}
                strokeLinecap="round"
                className={scoreColor}
              />
            </svg>
            <div className="absolute inset-0 flex flex-col items-center justify-center">
              <span className={`text-3xl font-black italic tracking-tighter ${scoreColor}`}>{overallScore}</span>
              <span className="text-[10px] font-bold uppercase tracking-widest text-muted-foreground">of 100</span>
            </div>
          </div>
          <div className="text-center sm:text-left">
            <div className={`flex items-center justify-center gap-2 sm:justify-start ${scoreColor}`}>
              <ScoreIcon className="h-5 w-5" />
              <span className="text-lg font-black italic tracking-tight">{scoreLabel}</span>
            </div>
            <p className="mt-1 text-xs text-muted-foreground">
              Stash rate vs {targetPercent.toFixed(0)}% of income target
            </p>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between text-xs font-bold uppercase tracking-widest text-muted-foreground">
            <span>Stash allocation</span>
            <span className={scoreColor}>{progressTowardTarget}%</span>
          </div>
          <Progress value={progressTowardTarget} className="h-2" />
          <p className="text-[10px] text-muted-foreground">
            {savingsPercentOfIncome.toFixed(1)}% of planned inflow → Stash Map (target {targetPercent.toFixed(0)}%)
          </p>
        </div>
      </CardContent>
    </GlassCard>
  );
}
