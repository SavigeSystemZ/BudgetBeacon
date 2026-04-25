#!/usr/bin/env tsx
/**
 * Regression-prevention audit for mocked / dead controls.
 *
 * Counts occurrences of patterns that indicate fake or broken UI controls
 * across `src/routes/` and `src/components/`. Compares against a baseline
 * recorded at M2 close (2026-04-25). Exits non-zero if any count *increased*.
 *
 * Decreasing counts is fine — that means a milestone removed a mock.
 *
 * Usage:
 *   npm run audit:controls           # check against baseline
 *   npm run audit:controls -- --update   # update baseline (use after fixing mocks)
 *
 * Baseline file: tools/audit-controls.baseline.json
 */
import { readdirSync, readFileSync, statSync, writeFileSync, existsSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const REPO_ROOT = join(fileURLToPath(import.meta.url), "..", "..");
const SCAN_DIRS = ["src/routes", "src/components"];
const BASELINE_PATH = join(REPO_ROOT, "tools", "audit-controls.baseline.json");

type Counts = Record<string, number>;

const PATTERNS: Array<{ key: string; description: string; regex: RegExp }> = [
  {
    key: "setTimeout",
    description: "setTimeout calls (often used to fake async work)",
    regex: /\bsetTimeout\s*\(/g,
  },
  {
    key: "mathRandom",
    description: "Math.random calls (often used to fake values)",
    regex: /\bMath\.random\s*\(/g,
  },
  {
    key: "alert",
    description: "alert() calls (placeholder feedback instead of real action)",
    regex: /\balert\s*\(/g,
  },
  {
    key: "emptyOnClick",
    description: "Empty onClick handlers (e.g. onClick={() => {}})",
    regex: /onClick\s*=\s*\{\s*\(\s*\)\s*=>\s*\{\s*\}\s*\}/g,
  },
];

function listFiles(dir: string): string[] {
  const out: string[] = [];
  const abs = join(REPO_ROOT, dir);
  if (!existsSync(abs)) return out;
  const stack: string[] = [abs];
  while (stack.length) {
    const cur = stack.pop()!;
    for (const entry of readdirSync(cur)) {
      const full = join(cur, entry);
      const s = statSync(full);
      if (s.isDirectory()) stack.push(full);
      else if (/\.(ts|tsx)$/.test(entry) && !/\.test\.(ts|tsx)$/.test(entry)) out.push(full);
    }
  }
  return out;
}

function countAll(): { counts: Counts; perFile: Record<string, Counts> } {
  const files = SCAN_DIRS.flatMap(listFiles);
  const counts: Counts = Object.fromEntries(PATTERNS.map((p) => [p.key, 0]));
  const perFile: Record<string, Counts> = {};
  for (const file of files) {
    const text = readFileSync(file, "utf8");
    const fileCounts: Counts = {};
    for (const p of PATTERNS) {
      const matches = text.match(p.regex) ?? [];
      counts[p.key] += matches.length;
      if (matches.length > 0) fileCounts[p.key] = matches.length;
    }
    if (Object.keys(fileCounts).length > 0) {
      perFile[relative(REPO_ROOT, file)] = fileCounts;
    }
  }
  return { counts, perFile };
}

function loadBaseline(): Counts | null {
  if (!existsSync(BASELINE_PATH)) return null;
  try {
    return JSON.parse(readFileSync(BASELINE_PATH, "utf8")).counts as Counts;
  } catch {
    return null;
  }
}

function main() {
  const update = process.argv.includes("--update");
  const { counts, perFile } = countAll();

  console.log("Audit-controls scan (src/routes + src/components):");
  for (const p of PATTERNS) {
    console.log(`  ${p.key.padEnd(14)} ${counts[p.key]}   — ${p.description}`);
  }

  if (update) {
    writeFileSync(
      BASELINE_PATH,
      JSON.stringify({ updatedAt: new Date().toISOString(), counts, perFile }, null, 2) + "\n"
    );
    console.log(`\nBaseline updated → ${relative(REPO_ROOT, BASELINE_PATH)}`);
    return;
  }

  const baseline = loadBaseline();
  if (!baseline) {
    console.log(`\nNo baseline found. Recording current as baseline → ${relative(REPO_ROOT, BASELINE_PATH)}`);
    writeFileSync(
      BASELINE_PATH,
      JSON.stringify({ updatedAt: new Date().toISOString(), counts, perFile }, null, 2) + "\n"
    );
    return;
  }

  let regressed = false;
  for (const p of PATTERNS) {
    const cur = counts[p.key] ?? 0;
    const base = baseline[p.key] ?? 0;
    if (cur > base) {
      regressed = true;
      console.error(`✗ ${p.key}: increased ${base} → ${cur} (mock/dead-control regression)`);
    } else if (cur < base) {
      console.log(`✓ ${p.key}: decreased ${base} → ${cur} (mock removed — update baseline with --update)`);
    }
  }

  if (regressed) {
    console.error("\nFAIL — mock-control counts increased. Either fix the new mock or update the baseline intentionally.");
    process.exit(1);
  }
  console.log("\nOK — no regressions vs baseline.");
}

main();
