# Performance Review Playbook

## Review inputs

- `_system/PROJECT_PROFILE.md` (validation commands, performance constraints)
- `_system/PERFORMANCE_BUDGET.md` (budgets and thresholds)
- `TEST_STRATEGY.md`
- touched hot paths, critical routes, or startup flows

## Review checklist

### Hot path impact

- [ ] Does the change touch a critical user path (first load, primary action, key data flow)?
- [ ] Is the change on a hot loop, frequently-called function, or render-critical path?
- [ ] Has before/after measurement been taken if the change affects a hot path?

### Computation and I/O

- [ ] No N+1 queries or repeated expensive operations inside loops.
- [ ] Database queries use appropriate indexes and avoid full table scans.
- [ ] File I/O, network calls, and other async operations are batched where possible.
- [ ] Heavy computation is offloaded from the main thread (UI) or request handler (API).

### Rendering and UI (frontend)

- [ ] No unnecessary re-renders caused by unstable references, inline objects, or missing memoization.
- [ ] Large lists use virtualization or pagination, not full DOM rendering.
- [ ] Images are optimized (lazy loading, proper format, appropriate size).
- [ ] Code splitting is used for non-critical routes and heavy components.

### Data and growth

- [ ] Collections have bounded sizes or pagination — no unbounded growth.
- [ ] Caches have eviction policies and size limits.
- [ ] Subscriptions, listeners, and timers are cleaned up on unmount or disconnect.
- [ ] Memory usage does not grow unboundedly over the session lifetime.

### Startup and build

- [ ] Startup time has not regressed (cold start, hot reload).
- [ ] Build time has not regressed significantly.
- [ ] Bundle size has not grown without justification.
- [ ] No heavy dependencies imported synchronously on startup when they could be lazy-loaded.

## Measurement guidance

When a change affects a hot path, measure with stack-appropriate tools:

- **Frontend**: Lighthouse performance score, Core Web Vitals (LCP, FID, CLS), bundle size via `webpack-bundle-analyzer` or `source-map-explorer`, React Profiler for component render time.
- **Backend API**: Request latency (P50, P95, P99), database query time via `EXPLAIN`, memory usage under load, throughput (requests/sec).
- **Python CLI**: `time` for wall-clock, `cProfile` or `py-spy` for profiling, memory via `tracemalloc`.
- **Build**: `time npm run build`, Vite build timing output, TypeScript `--diagnostics` flag.

Record baseline and post-change measurements in `WHERE_LEFT_OFF.md`.

## Must-fix findings

- touched path obviously regresses performance-critical behavior with measurement evidence
- blocking or synchronous work on interaction-critical flows (UI freeze, request timeout)
- new work scales poorly without justification (O(n^2) or worse where linear is possible)
- avoidable startup or build regression in a critical path
- unbounded collection or cache without eviction
- N+1 query pattern in a data access path

## Output format

For each finding, report:

- **Severity**: critical / moderate / low
- **Location**: file, function, or query
- **Finding**: what the performance issue is
- **Measurement**: before/after numbers (if available) or estimated impact
- **Recommendation**: specific optimization

Output in this order:

1. Critical regressions (measured or strongly evidenced)
2. Scalability risks (growth patterns that will degrade)
3. Optimization opportunities (not blocking but would improve performance)
4. Missing measurements that should be gathered before release
