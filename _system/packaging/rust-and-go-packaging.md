# Rust and Go Packaging Notes

- Build deterministic release binaries in CI.
- Use `cargo-deb`, `cargo-rpm`, or `goreleaser` when native packages are needed.
- Keep generated service units, environment files, and package metadata separate from the binary itself.
