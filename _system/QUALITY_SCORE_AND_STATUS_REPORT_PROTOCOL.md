# Quality Score and Status Report Protocol

`bootstrap/score-quality-gates.sh` computes weighted quality categories and
returns score + label from `_system/QUALITY_SCORE_POLICY.json`.

Policy contract:

- policy `version` must be semantic version `MAJOR.MINOR.PATCH`
- supported major version is `1`
- `required_weight_keys` is the explicit score contract
- `weights` must match `required_weight_keys` exactly
- `expected_weight_sum` must equal the sum of all weights
- labels must be sorted from highest threshold to lowest and must include a
  final `min_score: 0` fallback

`bootstrap/emit-status-report.sh` emits machine-readable status reports
containing validation outcomes, quality score, and next-step guidance.
