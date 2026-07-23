import Foundation
import Testing
@testable import Limiter

@Suite("Preferences and private journal")
@MainActor
struct PreferencesAndExportTests {
    @Test("Pause durations expire and indefinite pauses resume")
    func pauseLifecycle() {
        let suite = "LimiterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        preferences.pause(for: .fifteenMinutes, at: now)
        #expect(preferences.isProtectionPaused(at: now.addingTimeInterval(899)))
        #expect(!preferences.isProtectionPaused(at: now.addingTimeInterval(901)))

        preferences.pause(for: .indefinitely, at: now)
        #expect(preferences.isProtectionPaused(at: now.addingTimeInterval(100_000)))
        preferences.resumeProtection()
        #expect(!preferences.isProtectionPaused(at: now))
    }

    @Test("Deleting local data resets every preference")
    func resetPreferences() {
        let suite = "LimiterTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = AppPreferences(defaults: defaults)

        preferences.onboardingCompleted = true
        preferences.currentIntention = "Finish the report"
        preferences.journalEnabled = false
        preferences.journalRetentionDays = 30
        preferences.warningLeadSeconds = 180
        preferences.appearance = .dark
        preferences.pause(for: .indefinitely, at: .now)

        preferences.resetToDefaults()

        #expect(!preferences.onboardingCompleted)
        #expect(preferences.currentIntention.isEmpty)
        #expect(preferences.journalEnabled)
        #expect(preferences.journalRetentionDays == 0)
        #expect(preferences.warningLeadSeconds == 60)
        #expect(preferences.appearance == .system)
        #expect(!preferences.pausedIndefinitely)
        #expect(preferences.pausedUntil == nil)
    }

    @Test("Journal CSV safely escapes user text")
    func csvEscapesText() {
        let record = ReflectionRecord(
            bundleIdentifier: "com.example.Game",
            applicationName: "Game, Deluxe",
            createdAt: Date(timeIntervalSince1970: 0),
            reason: .specificTask,
            note: "A \"quick\" check",
            intendedTask: "Write, test, ship",
            decision: .continuedIntentionally,
            allowanceMinutes: 10
        )
        let csv = JournalExporter.csv(records: [record])
        #expect(csv.contains("\"Game, Deluxe\""))
        #expect(csv.contains("\"A \"\"quick\"\" check\""))
        #expect(csv.contains("\"Write, test, ship\""))
        #expect(csv.contains("Continued intentionally"))
    }

    @Test("Intervention countdown is deterministic")
    func interventionCountdown() {
        let beganAt = Date(timeIntervalSince1970: 100)
        let request = InterventionRequest(
            event: nil,
            bundleIdentifier: "com.example.Game",
            applicationName: "Game",
            applicationURL: nil,
            beganAt: beganAt,
            intendedTask: "Finish the report",
            selectedMinutes: 15
        )
        #expect(request.pauseSecondsRemaining(at: beganAt) == 10)
        #expect(request.pauseSecondsRemaining(at: beganAt.addingTimeInterval(4.9)) == 6)
        #expect(request.pauseSecondsRemaining(at: beganAt.addingTimeInterval(12)) == 0)
    }

    @Test("Session timer uses stable minute-second formatting")
    func durationFormatting() {
        #expect(ActiveSessionRow.format(seconds: 0) == "0:00")
        #expect(ActiveSessionRow.format(seconds: 65) == "1:05")
        #expect(ActiveSessionRow.format(seconds: 3_599) == "59:59")
    }
}
