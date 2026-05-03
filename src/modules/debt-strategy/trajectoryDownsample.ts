/**
 * Downsample payoff trajectory for lightweight SVG / sparkline rendering.
 * Preserves endpoints so the chart still reflects payoff completion.
 */
export function downsamplePayoffTrajectory<T extends { month: number; totalBalance: number }>(
  points: T[],
  maxPoints: number,
): T[] {
  if (points.length <= maxPoints) return [...points];
  const step = Math.ceil(points.length / maxPoints);
  const out: T[] = [];
  for (let i = 0; i < points.length; i += step) {
    out.push(points[i]);
  }
  const last = points[points.length - 1];
  const tail = out[out.length - 1];
  if (tail.month !== last.month || tail.totalBalance !== last.totalBalance) {
    out.push(last);
  }
  return out;
}
