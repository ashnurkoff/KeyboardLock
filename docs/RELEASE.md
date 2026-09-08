# Release process

This checklist is for maintainers publishing KeyboardLock outside the Mac App Store. Contributor and CI builds do not need distribution credentials.

Apple requires directly distributed Mac software to use a Developer ID Application signature and recommends notarization so Gatekeeper can verify it. An Apple Development or ad-hoc signature is not a distribution signature.

## Prerequisites

- Active Apple Developer Program membership
- A `Developer ID Application` certificate installed in the login keychain
- Access to the matching Apple developer team
- Current Xcode and XcodeGen
- GitHub CLI authenticated for `ashnurkoff/KeyboardLock`
- A clean `main` branch with passing CI

Never commit certificates, private keys, app-specific passwords, App Store Connect keys, or keychain exports.

## 1. Choose and record the version

KeyboardLock uses semantic versioning.

1. Update `MARKETING_VERSION` in `project.yml`.
2. Increment `CURRENT_PROJECT_VERSION`.
3. Run `make generate` and commit the generated project changes.
4. Confirm release notes describe user-visible changes, fixes, privacy changes, and known limitations.

```bash
git status --short
make check
```

The working tree must be clean before archiving.

## 2. Configure notarization credentials

Store credentials in the macOS keychain once. Use an app-specific password or supported App Store Connect credentials:

```bash
xcrun notarytool store-credentials "KeyboardLock-notary" \
  --apple-id "YOUR_APPLE_ID" \
  --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD"
```

The profile stores credentials in Keychain; it must never become a repository file or GitHub Actions variable printed to logs.

## 3. Create a Developer ID archive

```bash
xcodegen generate

xcodebuild archive \
  -project KeyboardLock.xcodeproj \
  -scheme KeyboardLock \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath build/release/KeyboardLock.xcarchive \
  DEVELOPMENT_TEAM="YOUR_TEAM_ID" \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY="Developer ID Application"
```

The app is located at:

```text
build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app
```

Verify the signature and universal binary before uploading:

```bash
codesign --verify --deep --strict --verbose=2 \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app

codesign -dv --verbose=4 \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app

lipo -info \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app/Contents/MacOS/KeyboardLock
```

Confirm the signature authority is `Developer ID Application`, Hardened Runtime is enabled, a secure timestamp is present, and both `arm64` and `x86_64` are listed.

## 4. Submit for notarization

Create the upload archive:

```bash
ditto -c -k --keepParent \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app \
  build/release/KeyboardLock-notarization.zip
```

Submit it and wait for Apple's result:

```bash
xcrun notarytool submit build/release/KeyboardLock-notarization.zip \
  --keychain-profile "KeyboardLock-notary" \
  --wait
```

Do not continue unless the final status is `Accepted`. If it is rejected, retrieve the log using the submission ID:

```bash
xcrun notarytool log SUBMISSION_ID \
  --keychain-profile "KeyboardLock-notary" \
  build/release/notarization-log.json
```

Review every warning as well as every error.

## 5. Staple and validate the ticket

```bash
xcrun stapler staple \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app

xcrun stapler validate \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app

spctl --assess --type execute --verbose=4 \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app
```

Gatekeeper assessment must report acceptance and identify the Developer ID source.

## 6. Create the public artifact

Package the stapled app, not the earlier upload archive:

```bash
VERSION="1.0.0"

ditto -c -k --keepParent \
  build/release/KeyboardLock.xcarchive/Products/Applications/KeyboardLock.app \
  "build/release/KeyboardLock-${VERSION}.zip"

shasum -a 256 "build/release/KeyboardLock-${VERSION}.zip" \
  > "build/release/KeyboardLock-${VERSION}.zip.sha256"
```

Extract the ZIP on a clean test account or second Mac, verify Gatekeeper again, grant Accessibility access, and complete the manual safety checklist in [BUILDING.md](BUILDING.md).

## 7. Tag and publish

```bash
VERSION="1.0.0"

git tag -s "v${VERSION}" -m "KeyboardLock ${VERSION}"
git push origin "v${VERSION}"

gh release create "v${VERSION}" \
  "build/release/KeyboardLock-${VERSION}.zip" \
  "build/release/KeyboardLock-${VERSION}.zip.sha256" \
  --verify-tag \
  --title "KeyboardLock ${VERSION}" \
  --generate-notes
```

If signed Git tags are not configured, configure them before the first binary release rather than publishing an unsigned release tag.

## 8. Post-release verification

- Download the artifact from the public GitHub release.
- Verify its SHA-256 checksum.
- Confirm Gatekeeper accepts the downloaded copy.
- Confirm the app version and both architectures.
- Test lock, Touch ID cancel/success, mouse hold, timer expiry, and quit.
- Check that no credentials, archive internals, or notarization logs were attached.
- Update the README only after the notarized binary is publicly available.

## References

- [Apple: Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple: Signing Mac software with Developer ID](https://developer.apple.com/developer-id/)
