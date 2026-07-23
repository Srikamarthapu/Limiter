# Architecture

Limiter is a native Swift 6 macOS application built as a Swift Package executable and wrapped in a standard `.app` bundle by the release script. It targets macOS 14 and uses only Apple frameworks.

## Data flow

1. `WorkspaceApplicationMonitor` observes public `NSWorkspace` launch, activation, termination, and wake notifications.
2. `AppModel` matches the event against enabled `ProtectedApplication` rules and any active grant or closing grace.
3. `AppKitApplicationController` hides the app and requests normal termination for a new launch, or hides an already-running activation.
4. `OverlayPanelController` presents the SwiftUI reflection in a floating AppKit panel on the active display and Space.
5. Returning to focus keeps the target contained. Continuing creates a persisted `SessionRecord` before revealing or reopening the target.
6. The one-second coordinator tick sends a warning, expires grants, requests normal termination, and enforces the two-minute closing grace.

## State ownership

`AppModel` is the root `@Observable`, main-actor coordinator shared by the app window, menu bar, settings, and overlay panel. Feature-local input remains in observable request models or view state.

SwiftData persists the following in `~/Library/Application Support/Limiter/Limiter.store`:

- `ProtectedApplication`
- `ReflectionRecord`
- `SessionRecord`

`AppPreferences` persists small settings in `UserDefaults`. Active grants are SwiftData records, so restarting Limiter cannot accidentally turn a timed grant into an unlimited session.

## Test seams

System behavior is isolated behind `ApplicationMonitoring`, `ApplicationControlling`, `LoginItemManaging`, `ClockProviding`, and `AppRuleRepository`. Policy matching is a pure `ProtectionPolicy` value. Tests use an in-memory SwiftData container, fixed clock, and recording system adapters.

## Platform boundary

Family Controls and Managed Settings application shielding are unavailable to native macOS apps. Limiter does not use private APIs, process injection, event taps, Accessibility automation, a privileged daemon, or Endpoint Security. Interception is reactive and intentionally bypassable.
