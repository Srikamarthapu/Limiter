# Privacy

Limiter is designed to work without a network service.

## Data stored locally

Limiter stores the following on the current Mac:

- protected application bundle identifiers, names, paths, enabled state, and default durations;
- the current intention entered by the user;
- reflection timestamps, reason category, optional note, decision, and selected allowance;
- intentional-session start, expiry, outcome, warning, and closing-grace state;
- preferences such as appearance, journal retention, warnings, onboarding, and pause state.

SwiftData stores rules and history in `~/Library/Application Support/Limiter/Limiter.store`. `UserDefaults` stores preferences. Reflection notes and intentions can be disabled, exported to CSV, cleared independently, or deleted with all Limiter data.

## Data Limiter does not collect

Limiter has no account, analytics, telemetry, advertising SDK, crash-reporting service, cloud sync, or application server. It does not read keystrokes, screen contents, browser history, documents, messages, contacts, location, microphone, or camera.

The application contains no runtime networking code or third-party dependency.

## App discovery and monitoring

During setup, Limiter reads standard application-bundle metadata such as display name, icon, path, and bundle identifier. While protection is active, it observes public macOS workspace launch, activation, and termination notifications. It does not inspect the contents of protected applications.

## Export and deletion

Journal export happens only after the user chooses a local destination. Limiter does not upload the export.

**Clear journal** removes reflection and session history while preserving app rules. **Delete all local data** removes app rules, history, current intention, and pause state and returns Limiter to onboarding.
