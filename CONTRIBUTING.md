# Contributing

Thanks for helping make distraction more deliberate.

## Development

1. Use macOS 14 or later with Xcode 16.4 or later.
2. Create a focused branch from `main`.
3. Run `swift test` before submitting a pull request.
4. Run `./scripts/package-app.sh` when changing packaging, bundle metadata, app icon, or login behavior.

Keep the runtime dependency-free unless a dependency solves a demonstrated problem that cannot reasonably be handled with Apple frameworks. Limiter must remain local-only and must not add analytics, telemetry, advertising, accounts, or an application server.

## Product invariants

- Never force-quit another app.
- Never claim unbypassable enforcement.
- Preserve the escape route to pause, quit, and uninstall.
- Do not request invasive permissions to improve interception.
- Do not shame the user or make medical-treatment claims.
- Do not estimate “time saved” from a declined launch.
- Keep reflection text out of logs and diagnostics.

## Style

Use Swift 6 concurrency checking, SwiftUI-native state, small composed views, semantic theme colors, SF Symbols, keyboard accessibility, VoiceOver labels, and Reduced Motion support. New behavior should have deterministic tests around its policy boundary.
