# Database Migrations Blueprint

Use this when the repo owns schema evolution and needs repeatable migration discipline.

## Supported patterns

- Alembic for Python services
- Prisma for TypeScript or Node services
- Diesel or file-based SQL migrations for Rust

## Expectations

- Every schema change ships with a forward migration
- Destructive changes require explicit rollback or restore guidance
- CI runs migration validation against a disposable database
- Seed data and fixtures stay distinct from production migrations

## First milestone suggestion

1. Add the migration tool configuration.
2. Create an initial schema migration.
3. Verify apply and rollback behavior in a test database.
