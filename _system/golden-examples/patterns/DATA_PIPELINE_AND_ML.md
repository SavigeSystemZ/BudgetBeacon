# Data Pipeline and ML Pattern

## Use when

- the application includes ETL, data transformation, or ML model serving
- feature engineering, training, or inference pipelines need structure
- data versioning or experiment tracking is part of the workflow
- batch and stream processing coexist in the architecture

## What to emulate

- pipeline stages as independent, testable units with clear input/output contracts
- data versioning for datasets and model artifacts with reproducible training runs
- feature stores that decouple feature engineering from model training and serving
- model serving with explicit latency budgets, fallback behavior, and A/B testing
- experiment tracking with metric logging, parameter recording, and artifact storage
- schema validation at pipeline boundaries to catch data drift early
- idempotent pipeline stages that can be safely retried or replayed
- monitoring for data quality, model drift, and prediction confidence

## What not to inherit

- monolithic notebooks promoted directly to production without modularization
- training pipelines that cannot reproduce results from recorded parameters
- feature engineering duplicated between training and serving paths
- ML models deployed without monitoring for prediction quality or data drift

## Adoption checklist

1. Document pipeline stages and data flow in `ARCHITECTURE_NOTES.md`.
2. Version datasets and model artifacts alongside code.
3. Add schema validation at every pipeline boundary.
4. Implement experiment tracking with parameter and metric logging.
5. Set latency and quality budgets for model serving in `PERFORMANCE_BUDGET.md`.
6. Add data drift and model quality monitoring.
7. Ensure training and serving use the same feature computation path.
