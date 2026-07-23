# Release process

## Local verification

```bash
swift test
./scripts/package-app.sh 0.1.1
lipo -archs ~/Library/Caches/LimiterBuild/Limiter.app/Contents/MacOS/Limiter
codesign --verify --deep --strict --verbose=2 ~/Library/Caches/LimiterBuild/Limiter.app
hdiutil verify dist/Limiter-0.1.1.dmg
shasum -a 256 -c dist/Limiter-0.1.1.dmg.sha256
```

The application must contain both `arm64` and `x86_64` architectures. Test onboarding, a real protected app, a deliberate session, expiry, pause protection, login-item recovery, dark mode, keyboard navigation, and VoiceOver before tagging.

## GitHub release

Update `CFBundleShortVersionString` in `Resources/Info.plist`, commit, then tag:

```bash
git tag v0.1.1
git push origin main --tags
```

The release workflow runs tests, builds the universal app on APFS-backed runner storage, creates an ad-hoc signed DMG and checksum, and publishes both to GitHub Releases.

## Deferred production signing

Developer ID signing and Apple notarization require a paid Apple Developer Program account. If added later, keep the hardened runtime, replace the ad-hoc identity in the package script, notarize the DMG with `notarytool`, staple the ticket, and verify with `spctl` before release.
