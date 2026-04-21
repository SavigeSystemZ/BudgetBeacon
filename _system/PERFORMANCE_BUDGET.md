# Performance Budget

Performance is a feature. Users notice slowness before they notice most bugs.

## Core principles

- Measure first. Never optimize without profiling data or reproducible benchmarks.
- Optimize the critical path. The first meaningful paint and primary user action matter most.
- Set budgets early. A budget violated in development will be worse in production.
- Performance is a team constraint, not a cleanup task. Every change must stay within budget.

## Web frontend budgets

### Page load

- First Contentful Paint: under 1.5s on a 4G connection.
- Largest Contentful Paint: under 2.5s.
- Time to Interactive: under 3.5s.
- Cumulative Layout Shift: under 0.1.
- First Input Delay: under 100ms.
- Total blocking time: under 200ms.

### Bundle size

- Initial JavaScript bundle: under 200KB gzipped for a standard SPA.
- Per-route chunk: under 50KB gzipped.
- CSS: under 50KB gzipped total.
- Images: use modern formats (WebP, AVIF). Serve responsive sizes. Lazy-load below the fold.
- Fonts: subset to used characters. Preload critical fonts. Use `font-display: swap`.

### Runtime

- Animations: 60fps minimum. Use CSS transforms and opacity for GPU-accelerated animations. Avoid animating layout properties (width, height, top, left).
- List rendering: virtualize lists over 100 items.
- Re-renders: components should not re-render without meaningful state or prop changes. Use memoization where profiling shows benefit.
- Event handlers: debounce scroll, resize, and input handlers. Use passive listeners where applicable.
- Memory: no unbounded growth. Clean up listeners, subscriptions, and intervals on unmount.

## API and backend budgets

### Response time

- Read endpoints: p95 under 200ms.
- Write endpoints: p95 under 500ms.
- Complex queries or reports: p95 under 2s with progress indication.
- WebSocket or streaming: initial connection under 500ms. Message delivery under 50ms on LAN.

### Resource efficiency

- Database queries: no query should scan more rows than necessary. Use indexes for filtered and sorted queries. Explain plans for queries touching large tables.
- Connection pooling: always pool database and HTTP connections. Never open a connection per request.
- Payload size: paginate collections. Default page size 20-50. Maximum 100. Never return unbounded result sets.
- Serialization: avoid serializing entire object graphs. Return only the fields the client needs.
- Background work: move heavy computation, email sending, file processing, and third-party API calls to background jobs or queues.

### Caching strategy

- Cache static assets with long-lived headers and content-hash filenames.
- Cache API responses where freshness tolerance allows. Use ETags or Last-Modified headers.
- Cache database query results for read-heavy, write-rare data with explicit TTL and invalidation.
- Never cache user-specific or sensitive data in shared caches.
- Document cache invalidation rules next to the cache setup.

## Mobile and constrained environments

- Target the median device, not the developer machine. Test on mid-range hardware.
- Reduce JavaScript execution time. Ship less code.
- Use responsive images and lazy loading for bandwidth-constrained connections.
- Respect `prefers-reduced-motion` for animation and transition choices.
- Respect `Save-Data` header when available.

## Monitoring and regression prevention

- Track Core Web Vitals in production.
- Set up bundle size checks in CI. Fail the build if a budget is exceeded without an explicit override.
- Run lighthouse or equivalent in CI for critical pages.
- Profile memory usage during extended sessions. Watch for leaks.
- Log slow queries and slow endpoints. Alert on p95 regression.

## Optimization patterns

- Code splitting: split by route. Lazy-load non-critical features.
- Tree shaking: use ES modules. Avoid side-effect-heavy imports.
- Image optimization: compress, resize, and serve next-gen formats automatically.
- Prefetching: prefetch likely next navigations on hover or viewport proximity.
- Service workers: cache app shell and critical assets for instant repeat loads.
- Server-side rendering or static generation: use SSR/SSG for content-heavy pages where SEO and initial load matter.
- Database indexing: index columns used in WHERE, JOIN, ORDER BY. Remove unused indexes.
- Query optimization: use EXPLAIN. Eliminate N+1 patterns. Batch related queries.
- Compression: enable gzip or brotli for all text-based responses.
