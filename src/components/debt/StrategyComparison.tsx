import { useMemo, useState } from "react";
import { CardContent, CardDescription, CardHeader, CardTitle } from "../ui/card";
import { GlassCard } from "../ui/GlassCard";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { compareStrategies, type SimDebt, type PayoffResult } from "../../modules/debt-strategy/payoffSimulator";
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

export function StrategyComparison({ debts }: Props) {
  const [extra, setExtra] = useState(100);

  const result = useMemo(() => {
    if (!debts.length) return null;
    return compareStrategies(debts, extra);
  }, [debts, extra]);

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
          />
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
    </div>
  );
}
