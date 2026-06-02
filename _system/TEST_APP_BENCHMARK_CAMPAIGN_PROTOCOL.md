# Test App Benchmark Campaign Protocol

This protocol defines the **benchmark campaign infrastructure** — test-app scaffolding, archetype/profile coverage matrix, gate execution model, and evidence layout. For the **regression bar that gates app-builder contract or prompt changes**, see `APP_BUILDER_REGRESSION_AND_BENCHMARK_PROTOCOL.md`.

Campaign root (external): `~/.MyAppZ/_AIAST_TEST_APPS/`

Core scripts:
- `bootstrap/create-test-app-campaign.sh`
- `bootstrap/run-test-app-benchmark-matrix.sh`
- `_TEMPLATE_FACTORY/smoke-test-app-campaign.sh`

Campaign validates scaffold profile routing, archetype packs, runtime separation,
permission repair boundaries, validation autopilot, fleet state, context
recording, and quality scoring.

`run-test-app-benchmark-matrix.sh` supports:
- planning/provisioning mode (default)
- executable cell mode via `--execute` for per-cell gate outcomes and timing
- isolated execution: each executed cell scaffolds its own repo under the
  external campaign root before running profile, archetype, awareness/strict,
  and quality gates
- scoped runs via `--profiles`, `--archetypes`, `--mode`, and `--limit-cells`
- transient cell repos by default; add `--apply` to retain the scaffolded cell
  repos for inspection

Execution reports must stay in maintainer evidence paths when run from the
master source tree; benchmark cell repos must stay outside the installable
template boundary.
