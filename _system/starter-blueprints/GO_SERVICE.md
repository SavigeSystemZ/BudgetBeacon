# Go Service Blueprint

Use this for HTTP APIs, workers, or daemons written in Go.

## Expected repo shape

```
cmd/
internal/
pkg/ (optional)
tests/
go.mod
```

## Baseline stack

- Go 1.22+
- `cmd/` entrypoints
- `internal/` for service internals
- `go test ./...` as the minimum quality gate

## Validation commands

- Format: `gofmt -w .`
- Unit tests: `go test ./...`
- Build: `go build ./...`

## First milestone suggestion

1. Ship one entrypoint under `cmd/`.
2. Add a health or smoke path if it is a service.
3. Confirm release build works for the target platform.
