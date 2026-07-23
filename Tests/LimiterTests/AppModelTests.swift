import AppKit
import Foundation
import SwiftData
import Testing
@testable import Limiter

@Suite("App model session grants")
@MainActor
struct AppModelTests {
    @Test("An intentional choice creates a bounded persistent grant")
    func createsBoundedGrant() throws {
        let schema = Schema([ProtectedApplication.self, ReflectionRecord.self, SessionRecord.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let suite = "LimiterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let controller = RecordingApplicationController()
        let model = AppModel(
            container: container,
            preferences: AppPreferences(defaults: defaults),
            monitor: RecordingMonitor(),
            applicationController: controller,
            loginItemManager: StubLoginItemManager(),
            clock: FixedClock(now: now)
        )
        let request = InterventionRequest(
            event: nil,
            bundleIdentifier: "com.example.Game",
            applicationName: "Game",
            applicationURL: URL(fileURLWithPath: "/Applications/Game.app"),
            beganAt: now.addingTimeInterval(-10),
            intendedTask: "Finish the report",
            selectedMinutes: 15
        )
        request.reason = .plannedBreak
        model.activeIntervention = request

        model.allowIntentionalSession()

        #expect(model.sessions.count == 1)
        #expect(model.sessions[0].grantExpiresAt == now.addingTimeInterval(15 * 60))
        #expect(model.sessions[0].status == .active)
        #expect(model.reflections.count == 1)
        #expect(model.reflections[0].decision == .continuedIntentionally)
        #expect(controller.revealedBundleIdentifier == "com.example.Game")
    }
}

private struct FixedClock: ClockProviding {
    let now: Date
}

@MainActor
private final class RecordingMonitor: ApplicationMonitoring {
    var onEvent: ((ApplicationEvent) -> Void)?
    func start() { }
    func stop() { }
}

@MainActor
private final class RecordingApplicationController: ApplicationControlling {
    var revealedBundleIdentifier: String?
    func contain(_ event: ApplicationEvent) { }
    func reveal(_ request: InterventionRequest) { revealedBundleIdentifier = request.bundleIdentifier }
    func terminateNormally(bundleIdentifier: String) { }
    func hide(bundleIdentifier: String) { }
}

@MainActor
private final class StubLoginItemManager: LoginItemManaging {
    var isEnabled = false
    var isAvailable = true
    var statusDescription = "Not enabled"
    func setEnabled(_ enabled: Bool) throws { isEnabled = enabled }
    func openSystemSettings() { }
}
