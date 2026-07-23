import Foundation
import Testing
@testable import Limiter

@Suite("Protection policy")
struct ProtectionPolicyTests {
    private let policy = ProtectionPolicy()
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("Enabled rules intercept without a grant")
    func enabledRuleIntercepts() {
        #expect(policy.shouldIntercept(
            bundleIdentifier: "com.example.Game",
            ruleEnabled: true,
            grantExpiresAt: nil,
            closingGraceUntil: nil,
            protectionPaused: false,
            now: now
        ))
    }

    @Test("A current session grant bypasses interception")
    func currentGrantAllowsActivation() {
        #expect(!policy.shouldIntercept(
            bundleIdentifier: "com.example.Game",
            ruleEnabled: true,
            grantExpiresAt: now.addingTimeInterval(60),
            closingGraceUntil: nil,
            protectionPaused: false,
            now: now
        ))
    }

    @Test("Expired grants are gated again")
    func expiredGrantIntercepts() {
        #expect(policy.shouldIntercept(
            bundleIdentifier: "com.example.Game",
            ruleEnabled: true,
            grantExpiresAt: now.addingTimeInterval(-1),
            closingGraceUntil: nil,
            protectionPaused: false,
            now: now
        ))
    }

    @Test("Closing grace and explicit pauses are honored")
    func graceAndPauseAllowActivation() {
        #expect(!policy.shouldIntercept(
            bundleIdentifier: "com.example.Game",
            ruleEnabled: true,
            grantExpiresAt: nil,
            closingGraceUntil: now.addingTimeInterval(120),
            protectionPaused: false,
            now: now
        ))
        #expect(!policy.shouldIntercept(
            bundleIdentifier: "com.example.Game",
            ruleEnabled: true,
            grantExpiresAt: nil,
            closingGraceUntil: nil,
            protectionPaused: true,
            now: now
        ))
    }

    @Test("Critical macOS apps and Limiter cannot be protected")
    func systemAppsAreDenied() {
        #expect(!policy.isProtectable(bundleIdentifier: "com.apple.finder"))
        #expect(!policy.isProtectable(bundleIdentifier: "com.apple.SystemSettings"))
        #expect(!policy.isProtectable(bundleIdentifier: "com.srikamarthapu.Limiter"))
        #expect(policy.isProtectable(bundleIdentifier: "com.roblox.RobloxPlayer"))
    }

    @Test("Repeated launch and activation events are deduplicated per app")
    func eventDeduplication() {
        var deduplicator = EventDeduplicator()
        let firstGameEvent = deduplicator.shouldHandle(bundleIdentifier: "com.example.Game", at: now)
        let repeatedGameEvent = deduplicator.shouldHandle(
            bundleIdentifier: "com.example.Game",
            at: now.addingTimeInterval(0.4)
        )
        let otherAppEvent = deduplicator.shouldHandle(
            bundleIdentifier: "com.example.Chat",
            at: now.addingTimeInterval(0.4)
        )
        let laterGameEvent = deduplicator.shouldHandle(
            bundleIdentifier: "com.example.Game",
            at: now.addingTimeInterval(1.3)
        )

        #expect(firstGameEvent)
        #expect(!repeatedGameEvent)
        #expect(otherAppEvent)
        #expect(laterGameEvent)
    }

    @Test("Journal retention deletes only records older than the selected window")
    func journalRetention() {
        let retention = JournalRetentionPolicy()
        #expect(retention.shouldDelete(
            recordedAt: now.addingTimeInterval(-31 * 24 * 60 * 60),
            now: now,
            retentionDays: 30
        ))
        #expect(!retention.shouldDelete(
            recordedAt: now.addingTimeInterval(-29 * 24 * 60 * 60),
            now: now,
            retentionDays: 30
        ))
        #expect(!retention.shouldDelete(
            recordedAt: now.addingTimeInterval(-365 * 24 * 60 * 60),
            now: now,
            retentionDays: 0
        ))
    }
}
