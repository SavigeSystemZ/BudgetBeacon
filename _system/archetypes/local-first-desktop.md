# Archetype Pack: local-first-desktop

## App purpose
Desktop application optimized for offline/local workflows with optional sync.
## Required docs
- UX, Installer, LocalDataModel, Security, RecoveryGuide
## Required runtime surfaces
- desktop shell, local storage, sync adapter (optional)
## Recommended stack options
- Tauri/Electron + local DB
## Security/privacy posture
- local encryption for sensitive data, least privilege file access
## Installer expectations
- desktop install/repair/uninstall smoke
## Port policy
- loopback-only when local services are used
## Validation gates
- build/package/install/launch/render smoke
## UI/UX completion requirements
- keyboard support, clear status feedback, crash-safe autosave
## Platform expectations
- desktop-first Linux/Windows/macOS
## Fleet roles
- desktop-dev, package-steward, QA
## Prompt-pack hooks
- M17 + installer host validation protocol
## Benchmark/test-app scenario
- AIAST-Test-LocalDesktop
## Anti-patterns
- mandatory network dependency, unsafe local file permissions
