import Foundation
import Observation

@MainActor
@Observable
final class AppPreferences {
    private enum Key {
        static let onboardingCompleted = "onboardingCompleted"
        static let currentIntention = "currentIntention"
        static let journalEnabled = "journalEnabled"
        static let journalRetentionDays = "journalRetentionDays"
        static let warningLeadSeconds = "warningLeadSeconds"
        static let appearance = "appearance"
        static let pausedUntil = "pausedUntil"
        static let pausedIndefinitely = "pausedIndefinitely"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var onboardingCompleted: Bool { didSet { defaults.set(onboardingCompleted, forKey: Key.onboardingCompleted) } }
    var currentIntention: String { didSet { defaults.set(currentIntention, forKey: Key.currentIntention) } }
    var journalEnabled: Bool { didSet { defaults.set(journalEnabled, forKey: Key.journalEnabled) } }
    var journalRetentionDays: Int { didSet { defaults.set(journalRetentionDays, forKey: Key.journalRetentionDays) } }
    var warningLeadSeconds: Int { didSet { defaults.set(warningLeadSeconds, forKey: Key.warningLeadSeconds) } }
    var appearance: AppearancePreference { didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) } }
    var pausedUntil: Date? { didSet { defaults.set(pausedUntil, forKey: Key.pausedUntil) } }
    var pausedIndefinitely: Bool { didSet { defaults.set(pausedIndefinitely, forKey: Key.pausedIndefinitely) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        onboardingCompleted = defaults.bool(forKey: Key.onboardingCompleted)
        currentIntention = defaults.string(forKey: Key.currentIntention) ?? ""
        journalEnabled = defaults.object(forKey: Key.journalEnabled) as? Bool ?? true
        journalRetentionDays = defaults.object(forKey: Key.journalRetentionDays) as? Int ?? 0
        warningLeadSeconds = defaults.object(forKey: Key.warningLeadSeconds) as? Int ?? 60
        appearance = AppearancePreference(rawValue: defaults.string(forKey: Key.appearance) ?? "system") ?? .system
        pausedUntil = defaults.object(forKey: Key.pausedUntil) as? Date
        pausedIndefinitely = defaults.bool(forKey: Key.pausedIndefinitely)
    }

    func isProtectionPaused(at date: Date) -> Bool {
        if pausedIndefinitely { return true }
        guard let pausedUntil else { return false }
        return pausedUntil > date
    }

    func pause(for duration: PauseDuration, at date: Date) {
        if let interval = duration.interval {
            pausedIndefinitely = false
            pausedUntil = date.addingTimeInterval(interval)
        } else {
            pausedIndefinitely = true
            pausedUntil = nil
        }
    }

    func resumeProtection() {
        pausedIndefinitely = false
        pausedUntil = nil
    }

    func resetToDefaults() {
        onboardingCompleted = false
        currentIntention = ""
        journalEnabled = true
        journalRetentionDays = 0
        warningLeadSeconds = 60
        appearance = .system
        resumeProtection()
    }
}
