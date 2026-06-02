# Snapshot versioning and retention spec

This specification defines the in-house snapshot format and retention lifecycle.

## Archive format

- Core artifact: `tar.zst` using high compression profile.
- Recommended compression command:
  - `zstd -19 --long=31`
- Snapshot contains:
  - `app-runtime` tree
  - `app-meta` tree
  - selected `ops` context (logs/manifests metadata)

## Version identifier

Format:

`<app_semver>+snap.<YYYYMMDDTHHMMSSZ>-<shortsha>-<lane>`

Example:

`2.4.1+snap.20260506T210000Z-a1b2c3d-feat-auth`

## Snapshot classes

- `checkpoint`: frequent local restore points.
- `milestone`: release-candidate snapshot.
- `release`: immutable long-term artifact.

## Manifest schema (minimum)

- `snapshot_id`
- `class`
- `created_at_utc`
- `app_name`
- `operator`
- `lane`
- `runtime_git_sha`
- `meta_git_sha`
- `archive_relpath`
- `archive_sha256`
- `file_count`
- `tree_hashes` (runtime/meta roots at minimum)
- `restore_hint`

## Encryption and signing

- Encrypt before remote publish using `age` or `gpg`.
- Keep private keys outside repo trees.
- Maintain a hash-chained index in `snapshots/index/`.
- Verify checksums before restore.

## Retention baseline

- Checkpoints: keep 14 days.
- Milestones: keep 90 days.
- Releases: retain indefinitely or per policy.

## Restore service levels

- Dry-run verification command must complete without extraction side effects.
- Full restore must support isolated `restore-sandbox` destination.
- Restore process must verify manifest hash and archive hash before extraction.
