import { describe, it, expect } from "vitest";
import { downsamplePayoffTrajectory } from "./trajectoryDownsample";

describe("downsamplePayoffTrajectory", () => {
  it("returns a shallow copy when already short", () => {
    const pts = [
      { month: 1, totalBalance: 1000 },
      { month: 2, totalBalance: 900 },
    ];
    const d = downsamplePayoffTrajectory(pts, 10);
    expect(d).toHaveLength(2);
    expect(d[0]).toEqual(pts[0]);
    expect(d).not.toBe(pts);
  });

  it("preserves the last point when downsampling a long series", () => {
    const pts = Array.from({ length: 200 }, (_, i) => ({
      month: i + 1,
      totalBalance: 10000 - i * 40,
    }));
    const d = downsamplePayoffTrajectory(pts, 20);
    expect(d.length).toBeLessThanOrEqual(21);
    expect(d[d.length - 1]).toEqual(pts[pts.length - 1]);
  });

  it("does not duplicate the last point when the stride already lands on it", () => {
    const pts = [
      { month: 1, totalBalance: 100 },
      { month: 2, totalBalance: 80 },
      { month: 3, totalBalance: 60 },
      { month: 4, totalBalance: 40 },
      { month: 5, totalBalance: 0 },
    ];
    const d = downsamplePayoffTrajectory(pts, 3);
    expect(d[d.length - 1]).toEqual({ month: 5, totalBalance: 0 });
    expect(d.filter((p) => p.month === 5)).toHaveLength(1);
  });
});
