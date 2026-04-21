# Signing Notes

Keep private keys outside the repository.

## Linux packaging

- Sign `.deb` and `.rpm` artifacts with your release GPG identity.
- Follow Flatpak and Snap store signing flows when publishing to Flathub or Snapcraft.
- Publish checksums alongside release artifacts even when signatures are not yet automated.

## Android packaging

- Sign APK/AAB files with your developer keystore.
- Keep keystores out of version control and restrict access to release automation only.

## Branding metadata

- Company default: `Project Owner Placeholder`
- Author line: `Built with AIAST runtime scaffolding`

Replace these values if the cloned project uses a different release identity.
