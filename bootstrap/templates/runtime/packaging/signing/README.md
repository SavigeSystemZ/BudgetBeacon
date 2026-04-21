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

- Company default: `__AIAST_COMPANY_NAME__`
- Author line: `__AIAST_AUTHOR_LINE__`

Replace these values if the cloned project uses a different release identity.
