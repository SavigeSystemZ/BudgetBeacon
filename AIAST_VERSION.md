# AIAST Version

- Current version: `1.23.0`
- Versioning policy: semantic versioning
- Install model: copied template per repo with explicit upgrade tooling
- Compatibility marker: `_system/aiaast-capabilities.json`

## Semver policy

- Major: breaking file-contract or upgrade-flow changes
- Minor: additive files, scripts, blueprints, docs, or bootstrap capabilities
- Patch: fixes, validation corrections, compatibility repairs, and documentation cleanup

## Compatibility markers

- Repo-local precedence manifest: `_system/instruction-precedence.json`
- Repo operating profile: `_system/repo-operating-profile.json`
- Installed version marker: `_system/.template-version`
- Install metadata marker: `_system/.template-install.json`
- Host prompt emitter: `bootstrap/emit-host-prompt.sh`
- Host bundle emitter: `bootstrap/emit-host-bundle.sh`
