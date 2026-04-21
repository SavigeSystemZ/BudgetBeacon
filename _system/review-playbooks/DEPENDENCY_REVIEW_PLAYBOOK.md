# Dependency Review Playbook

## Review inputs

- changed lockfiles and package manifests
- `_system/DEPENDENCY_GOVERNANCE.md`
- `_system/PROJECT_PROFILE.md` (stack section)

## Review for

1. **Necessity**: Could this functionality be achieved with existing dependencies or standard library features?
2. **Maintenance health**: Is the package actively maintained? Last release date? Open issue count and responsiveness?
3. **Security**: Any known CVEs? History of supply chain incidents? Install scripts?
4. **License compatibility**: Is the license approved for the project? Any copyleft or source-available concerns?
5. **Size impact**: What does it add to bundle size? Does it tree-shake cleanly? Transitive dependency count?
6. **API stability**: Does it follow semver? History of breaking changes?
7. **Duplication**: Does it overlap with an existing dependency? Could an existing dependency serve the same purpose?
8. **Version pinning**: Are versions properly pinned in the lockfile? Is the lockfile committed?

## Must-fix findings

- Dependencies with critical or high CVEs and no available fix.
- Incompatible licenses (GPL, AGPL, SSPL) added without legal review.
- Missing lockfile or lockfile not committed.
- Duplicate dependencies serving the same purpose.
- Dependencies with malicious install scripts or known supply chain compromise history.

## Output format

```
## Dependency Review

### New dependencies
- package@version — justification, license, size impact, maintenance status

### Updated dependencies
- package@old → new — changelog reviewed, breaking changes: yes/no

### Must-fix
- [ ] finding

### Risk assessment
- supply chain risk: low/medium/high
- license risk: low/medium/high
- bundle impact: negligible/moderate/significant
```
