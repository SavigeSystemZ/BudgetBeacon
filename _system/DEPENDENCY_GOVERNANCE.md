# Dependency Governance

Every dependency is a liability. Each one increases attack surface, bundle size, maintenance burden, and upgrade risk.

## Core principles

- Prefer fewer, well-maintained dependencies over many small ones.
- Every new dependency must justify its inclusion against the cost of owning it.
- If a task can be done in under 50 lines with standard library features, do not add a dependency for it.
- Pin exact versions in lockfiles. Always commit lockfiles.

## Adding a dependency

Before adding a new package, answer:

1. **Necessity**: Can this be done with the standard library or existing dependencies?
2. **Quality**: Is the package actively maintained? When was the last release? Are issues addressed?
3. **Size**: What does it add to the bundle? Does it support tree shaking?
4. **Security**: Does it have known vulnerabilities? Has it had a history of supply chain issues?
5. **License**: Is the license compatible with the project (MIT, Apache-2.0, BSD are generally safe; GPL, AGPL, SSPL require legal review)?
6. **API stability**: Does it follow semver? Has it had breaking changes in recent major versions?
7. **Transitive depth**: How many transitive dependencies does it pull in?

If the answer to #1 is yes, stop. Write it yourself.

## Dependency categories

### Production dependencies

- Must be essential to runtime functionality.
- Must have a compatible license.
- Must be actively maintained or stability-proven.
- Prefer packages with zero or minimal transitive dependencies.

### Development dependencies

- Testing frameworks, linters, formatters, build tools.
- Keep separate from production dependencies.
- Still subject to security and license review.

### Peer dependencies

- Use for libraries that must share a single instance with the host (React, Vue, Angular).
- Document the supported version range clearly.

## Version management

- Use exact versions in lockfiles. Never rely on floating ranges in production.
- Update dependencies regularly (at least monthly) in small batches.
- Run the full test suite after every dependency update.
- Review changelogs before updating major versions.
- Never update all dependencies at once. Update in logical groups (build tools, runtime libs, test tools).

## Security

- Run `npm audit`, `pip audit`, `cargo audit`, or equivalent in CI on every build.
- Fail the build on critical or high severity vulnerabilities with no available fix.
- Subscribe to security advisories for critical dependencies.
- Verify package integrity via lockfile checksums.
- Never install packages from untrusted registries or direct Git URLs without pinning a commit hash.
- Audit new dependencies for typosquatting (similar names to popular packages).
- Review install scripts for new packages. Disable install scripts by default where the ecosystem supports it.

## Bundle and size hygiene

- Audit bundle size impact when adding frontend dependencies. Use tools like bundlephobia or webpack-bundle-analyzer.
- Prefer packages that support ES modules and tree shaking.
- Avoid packages that pull in large transitive trees for small functionality.
- Consider vendoring small, stable utilities instead of adding a dependency.
- Remove unused dependencies. Run depcheck, knip, or equivalent periodically.

## License compliance

- Maintain a list of approved licenses for the project.
- Run license checks in CI. Flag new licenses that have not been approved.
- Copyleft licenses (GPL, LGPL, AGPL) require legal review before use in proprietary or SaaS contexts.
- SSPL, BSL, and other source-available licenses are not open source. Treat as proprietary.
- Attribution requirements (Apache-2.0, BSD, MIT) must be satisfied in release artifacts.

## Replacement and removal

- When removing a dependency, verify no code still imports or references it.
- When replacing a dependency, do it in a single focused PR with before/after tests.
- Document the reason for replacement in the commit message.

## Monitoring

- Set up automated dependency update proposals (Dependabot, Renovate, or equivalent).
- Review and merge updates promptly. Stale update PRs accumulate risk.
- Track dependency age. A dependency with no updates in 2+ years is a risk signal.
- Track total dependency count over time. It should not grow unbounded.
