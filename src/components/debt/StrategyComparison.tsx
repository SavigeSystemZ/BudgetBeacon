import { useMemo, useState } from "react";
import { CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { GlassCard } from "../ui/GlassCard";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Button } from "../ui/button";
import { compareStrategies, type SimDebt, type PayoffResult } from "../../modules/debt-strategy/payoffSimulator";
import { downsamplePayoffTrajectory } from "../../modules/debt-strategy/trajectoryDownsample";
import { Crown, Award } from "lucide-react";

interface Props {
  debts: SimDebt[];
}

const fmt = (n: number) =>
  n.toLocaleString("en-US", { style: "currency", currency: "USD", maximumFractionDigits: 0 });

const monthsLabel = (m: number) => {
  if (m <= 0) return "0 mo";
  if (m < 12) return `${m} mo`;
  const years = Math.floor(m / 12);
  const rem = m % 12;
  return rem === 0 ? `${years} yr` : `${years} yr ${rem} mo`;
};

const EXTRA_PRESETS = [0, 50, 100, 250, 500, 1000] as const;
const EXTRA_RANGE_MAX = 3000;
const TRAJECTORY_CHART_MAX_POINTS = 72;
const TRAJECTORY_W = 200;
const TRAJECTORY_H = 44;
const TRAJECTORY_PAD = 4;

function PayoffTrajectorySparkline({
  trajectory,
  months,
}: {
  trajectory: { month: number; totalBalance: number }[];
  months: number;
}) {
  if (trajectory.length === 0) return null;
  if (trajectory.length < 2) {
    return (
      <p className="text-[9px] font-bold text-muted-foreground uppercase tracking-tighter mt-2 pt-2 border-t border-primary/10">
        Single-step payoff — no curve
      </p>
    );
  }

  const pts = downsamplePayoffTrajectory(trajectory, TRAJECTORY_CHART_MAX_POINTS);
  const balances = pts.map((p) => p.totalBalance);
  const minB = Math.min(...balances);
  const maxB = Math.max(...balances);
  const spread = Math.max(maxB - minB, 1);
  const xSpan = Math.max(pts.length - 1, 1);

  const coords = pts.map((p, i) => {
    const x = TRAJECTORY_PAD + (i / xSpan) * (TRAJECTORY_W - 2 * TRAJECTORY_PAD);
    const y = TRAJECTORY_PAD + (1 - (p.totalBalance - minB) / spread) * (TRAJECTORY_H - 2 * TRAJECTORY_PAD);
    return `${x.toFixed(1)},${y.toFixed(1)}`;
  });

  return (
    <svg
      width="100%"
      height={TRAJECTORY_H}
      viewBox={`0 0 ${TRAJECTORY_W} ${TRAJECTORY_H}`}
      className="mt-2 text-primary"
      role="img"
      aria-label={`Combined remaining balance trend over about ${months} months (downsampled for display)`}
    >
      <polyline fill="none" stroke="currentColor" strokeWidth="2" vectorEffect="non-scaling-stroke" className="opacity-85" points={coords.join(" ")} />
    </svg>
  );
}

export function StrategyComparison({ debts }: Props) {
  const [extra, setExtra] = useState(100);

  const result = useMemo(() => {
    if (!debts.length) return null;
    return compareStrategies(debts, extra);
  }, [debts, extra]);

  const sliderValue = Math.min(extra, EXTRA_RANGE_MAX);

  if (!debts.length) {
    return (
      <GlassCard className="border-primary/10">
        <CardHeader>
          <CardTitle className="text-[10px] font-black uppercase tracking-widest text-primary">Payoff strategy</CardTitle>
          <CardDescription className="text-[10px]">Add at least one debt with a balance to compare strategies.</CardDescription>
        </CardHeader>
      </GlassCard>
    );
  }

  if (!result) return null;

  const winner: "avalanche" | "snowball" =
    result.avalanche.totalInterestPaid <= result.snowball.totalInterestPaid ? "avalanche" : "snowball";
  const interestSavedVsMinimum = (r: PayoffResult) => result.minimum.totalInterestPaid - r.totalInterestPaid;

  return (
    <GlassCard intensity="high" className="border-primary/20">
      <CardHeader className="border-b border-primary/10 bg-primary/5">
        <CardTitle className="flex items-center gap-2 text-[12px] font-black uppercase tracking-widest text-primary">
          <Crown className="h-4 w-4" /> Payoff Strategy Comparison
        </CardTitle>
        <CardDescription className="text-[10px]">
          Avalanche pays the highest-APR debt first (mathematically optimal). Snowball pays the smallest-balance first (motivational).
          Both run against your real debt rows.
        </CardDescription>
      </CardHeader>
      <CardContent className="pt-6 space-y-6">
        <div className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="extra-monthly" className="text-[10px] font-black uppercase tracking-widest opacity-70">
              Extra monthly payment beyond minimums
            </Label>
            <Input
              id="extra-monthly"
              type="number"
              inputMode="decimal"
              min={0}
              step={25}
              value={extra}
              onChange={(e) => setExtra(Math.max(0, parseFloat(e.target.value) || 0))}
              className="bg-primary/5 border-none font-black h-12"
              aria-describedby="extra-presets-hint"
            />
            <p id="extra-presets-hint" className="text-[9px] text-muted-foreground font-bold uppercase tracking-widest">
              Type any amount or use presets / slider (slider caps at {fmt(EXTRA_RANGE_MAX)} for drag UX; higher values in the field).
            </p>
          </div>

          <div className="flex flex-wrap gap-2" role="group" aria-label="Extra payment presets">
            {EXTRA_PRESETS.map((amt) => (
              <Button
                key={amt}
                type="button"
                size="sm"
                variant={extra === amt ? "default" : "outline"}
                className="h-9 px-3 text-[10px] font-black uppercase tracking-tighter"
                aria-pressed={extra === amt}
                aria-label={`Set extra payment to ${fmt(amt)} per month`}
                onClick={() => setExtra(amt)}
              >
                {amt === 0 ? "Min only" : fmt(amt)}
              </Button>
            ))}
          </div>

          <div className="space-y-2">
            <Label htmlFor="extra-monthly-slider" className="text-[10px] font-black uppercase tracking-widest opacity-70">
              Quick scrub (0–{fmt(EXTRA_RANGE_MAX)})
            </Label>
            <input
              id="extra-monthly-slider"
              type="range"
              min={0}
              max={EXTRA_RANGE_MAX}
              step={25}
              value={sliderValue}
              onChange={(e) => setExtra(Number(e.target.value))}
              className="w-full h-2 accent-primary cursor-pointer"
              aria-valuemin={0}
              aria-valuemax={EXTRA_RANGE_MAX}
              aria-valuenow={sliderValue}
              aria-valuetext={
                extra > EXTRA_RANGE_MAX
                  ? `${fmt(extra)} extra per month; slider preview up to ${fmt(EXTRA_RANGE_MAX)}`
                  : `${fmt(extra)} extra per month`
              }
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <StrategyCard
            label="Minimums only"
            result={result.minimum}
            isWinner={false}
            isInfeasible={result.minimum.infeasible}
          />
          <StrategyCard
            label="Avalanche (highest APR first)"
            result={result.avalanche}
            isWinner={winner === "avalanche"}
            isInfeasible={result.avalanche.infeasible}
            savedVsMin={interestSavedVsMinimum(result.avalanche)}
          />
          <StrategyCard
            label="Snowball (smallest balance first)"
            result={result.snowball}
            isWinner={winner === "snowball"}
            isInfeasible={result.snowball.infeasible}
            savedVsMin={interestSavedVsMinimum(result.snowball)}
          />
        </div>

        <div className="text-[10px] text-muted-foreground leading-relaxed pt-3 border-t border-primary/5">
          {result.minimum.infeasible
            ? "⚠ Minimum payments do not currently cover monthly interest on at least one debt. Increase minimums or apply extra to keep balances from growing."
            : `Compared to paying minimums only, ${winner === "avalanche" ? "avalanche" : "snowball"} saves ${fmt(interestSavedVsMinimum(result[winner]))} in interest at ${fmt(extra)}/mo extra.`}
        </div>
      </CardContent>
    </GlassCard>
  );
}

function StrategyCard({
  label,
  result,
  isWinner,
  isInfeasible,
  savedVsMin,
}: {
  label: string;
  result: PayoffResult;
  isWinner: boolean;
  isInfeasible: boolean;
  savedVsMin?: number;
}) {
  return (
    <div className={`p-4 rounded-2xl border-2 ${isWinner ? "border-primary bg-primary/10" : "border-primary/10 bg-card/40"} space-y-2`}>
      <div className="flex items-center justify-between gap-2">
        <span className="text-[10px] font-black uppercase tracking-widest">{label}</span>
        {isWinner && <Award className="h-4 w-4 text-primary" />}
      </div>
      <div className="text-2xl font-black italic tracking-tighter">{monthsLabel(result.months)}</div>
      <div className="text-[10px] font-bold text-muted-foreground uppercase">
        Interest paid: {fmt(result.totalInterestPaid)}
      </div>
      <div className="text-[10px] font-bold text-muted-foreground uppercase">
        Total paid: {fmt(result.totalPaid)}
      </div>
      {savedVsMin !== undefined && savedVsMin > 0 && (
        <div className="text-[10px] font-black text-green-600">
          Saves {fmt(savedVsMin)} vs minimums
        </div>
      )}
      {isInfeasible && (
        <div role="alert" className="text-[10px] font-bold text-destructive">
          ⚠ Cannot fully pay off within projected horizon.
        </div>
      )}
      <PayoffTrajectorySparkline trajectory={result.trajectory} months={result.months} />
    </div>
  );
}
