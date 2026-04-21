# Rust CLI Tool Blueprint

Use this for performant command-line tools with strong typing and release binary packaging.

## Expected repo shape

```
src/
  main.rs
  cli.rs
  commands/
tests/
Cargo.toml
```

## Baseline stack

- Rust stable
- `clap` for argument parsing
- `cargo test` and `cargo build --release`

## Validation commands

- Format: `cargo fmt --check`
- Lint: `cargo clippy --all-targets --all-features -- -D warnings`
- Unit tests: `cargo test`
- Build: `cargo build --release`

## First milestone suggestion

1. Ship one command with clear help text.
2. Verify exit codes and error formatting.
3. Produce a release binary.
