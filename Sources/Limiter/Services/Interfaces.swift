import AppKit
import Foundation

protocol ClockProviding {
    var now: Date { get }
}

struct SystemClock: ClockProviding {
    var now: Date { .now }
}

@MainActor
protocol ApplicationMonitoring: AnyObject {
    var onEvent: ((ApplicationEvent) -> Void)? { get set }
    func start()
    func stop()
}

@MainActor
protocol ApplicationControlling: AnyObject {
    func contain(_ event: ApplicationEvent)
    func reveal(_ request: InterventionRequest)
    func terminateNormally(bundleIdentifier: String)
    func hide(bundleIdentifier: String)
}

@MainActor
protocol ProtectionCoordinating: AnyObject {
    func handleApplicationEvent(_ event: ApplicationEvent)
    func returnToFocus()
    func allowIntentionalSession()
}

@MainActor
protocol LoginItemManaging: AnyObject {
    var isEnabled: Bool { get }
    var statusDescription: String { get }
    func setEnabled(_ enabled: Bool) throws
    func openSystemSettings()
}

@MainActor
protocol AppRuleRepository: AnyObject {
    func fetchRules() throws -> [ProtectedApplication]
    func save() throws
}

struct ProtectionPolicy {
    static let deniedBundleIdentifiers: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systempreferences",
        "com.apple.SystemSettings",
        "com.apple.loginwindow",
        "com.apple.SecurityAgent",
        "com.apple.UserNotificationCenter",
        "com.srikamarthapu.Limiter"
    ]

    func isProtectable(bundleIdentifier: String) -> Bool {
        !Self.deniedBundleIdentifiers.contains(bundleIdentifier)
    }

    func shouldIntercept(
        bundleIdentifier: String,
        ruleEnabled: Bool,
        grantExpiresAt: Date?,
        closingGraceUntil: Date?,
        protectionPaused: Bool,
        now: Date
    ) -> Bool {
        guard isProtectable(bundleIdentifier: bundleIdentifier), ruleEnabled, !protectionPaused else {
            return false
        }
        if let grantExpiresAt, grantExpiresAt > now { return false }
        if let closingGraceUntil, closingGraceUntil > now { return false }
        return true
    }
}

struct EventDeduplicator {
    private var lastHandledAt: [String: Date] = [:]

    mutating func shouldHandle(
        bundleIdentifier: String,
        at date: Date,
        window: TimeInterval = 1.25
    ) -> Bool {
        if let lastHandled = lastHandledAt[bundleIdentifier],
           date.timeIntervalSince(lastHandled) < window {
            return false
        }
        lastHandledAt[bundleIdentifier] = date
        return true
    }
}

struct JournalRetentionPolicy {
    func shouldDelete(recordedAt: Date, now: Date, retentionDays: Int) -> Bool {
        guard retentionDays > 0,
              let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: now)
        else { return false }
        return recordedAt < cutoff
    }
}
