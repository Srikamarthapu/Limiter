import AppKit
import Foundation
import Observation
import SwiftData

enum ReflectionReason: String, Codable, CaseIterable, Identifiable {
    case plannedBreak
    case specificTask
    case connect
    case habit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plannedBreak: "A planned break"
        case .specificTask: "A specific task"
        case .connect: "Connect with someone"
        case .habit: "Habit / not sure"
        }
    }

    var systemImage: String {
        switch self {
        case .plannedBreak: "cup.and.saucer"
        case .specificTask: "scope"
        case .connect: "person.2"
        case .habit: "arrow.trianglehead.2.clockwise.rotate.90"
        }
    }
}

enum ReflectionDecision: String, Codable {
    case returnedToFocus
    case continuedIntentionally
}

enum SessionStatus: String, Codable {
    case active
    case completedEarly
    case closingGrace
    case expired
}

enum AppearancePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum AppSection: String, CaseIterable, Identifiable {
    case today
    case protectedApps
    case journal
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: "Today"
        case .protectedApps: "Protected Apps"
        case .journal: "Journal"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .protectedApps: "shield.lefthalf.filled"
        case .journal: "book.closed"
        case .settings: "gearshape"
        }
    }
}

@Model
final class ProtectedApplication {
    @Attribute(.unique) var bundleIdentifier: String
    var name: String
    var applicationPath: String
    var isEnabled: Bool
    var defaultSessionMinutes: Int
    var createdAt: Date

    init(
        bundleIdentifier: String,
        name: String,
        applicationPath: String,
        isEnabled: Bool = true,
        defaultSessionMinutes: Int = 15,
        createdAt: Date = .now
    ) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.applicationPath = applicationPath
        self.isEnabled = isEnabled
        self.defaultSessionMinutes = defaultSessionMinutes
        self.createdAt = createdAt
    }
}

@Model
final class ReflectionRecord {
    var id: UUID
    var bundleIdentifier: String
    var applicationName: String
    var createdAt: Date
    var reasonRawValue: String
    var note: String
    var intendedTask: String
    var decisionRawValue: String
    var allowanceMinutes: Int?

    init(
        bundleIdentifier: String,
        applicationName: String,
        createdAt: Date = .now,
        reason: ReflectionReason,
        note: String,
        intendedTask: String,
        decision: ReflectionDecision,
        allowanceMinutes: Int?
    ) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.createdAt = createdAt
        self.reasonRawValue = reason.rawValue
        self.note = note
        self.intendedTask = intendedTask
        self.decisionRawValue = decision.rawValue
        self.allowanceMinutes = allowanceMinutes
    }

    var reason: ReflectionReason {
        ReflectionReason(rawValue: reasonRawValue) ?? .habit
    }

    var decision: ReflectionDecision {
        ReflectionDecision(rawValue: decisionRawValue) ?? .returnedToFocus
    }
}

@Model
final class SessionRecord {
    var id: UUID
    var bundleIdentifier: String
    var applicationName: String
    var startedAt: Date
    var grantExpiresAt: Date
    var endedAt: Date?
    var plannedMinutes: Int
    var statusRawValue: String
    var warningShown: Bool
    var closingGraceUntil: Date?

    init(
        bundleIdentifier: String,
        applicationName: String,
        startedAt: Date,
        grantExpiresAt: Date,
        plannedMinutes: Int,
        status: SessionStatus = .active
    ) {
        self.id = UUID()
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.startedAt = startedAt
        self.grantExpiresAt = grantExpiresAt
        self.endedAt = nil
        self.plannedMinutes = plannedMinutes
        self.statusRawValue = status.rawValue
        self.warningShown = false
        self.closingGraceUntil = nil
    }

    var status: SessionStatus {
        get { SessionStatus(rawValue: statusRawValue) ?? .expired }
        set { statusRawValue = newValue.rawValue }
    }
}

struct InstalledApplication: Identifiable, Hashable, Sendable {
    var id: String { bundleIdentifier }
    let bundleIdentifier: String
    let name: String
    let url: URL
}

enum ApplicationEventKind: String, Sendable {
    case launched
    case activated
    case terminated
}

@MainActor
struct ApplicationEvent {
    let kind: ApplicationEventKind
    let application: NSRunningApplication

    var bundleIdentifier: String? { application.bundleIdentifier }
    var applicationName: String { application.localizedName ?? "Application" }
    var applicationURL: URL? { application.bundleURL }
}

enum InterventionStage: Int, CaseIterable {
    case pause
    case duration
    case confirm
}

@MainActor
@Observable
final class InterventionRequest: Identifiable {
    let id = UUID()
    let event: ApplicationEvent?
    let bundleIdentifier: String
    let applicationName: String
    let applicationURL: URL?
    let beganAt: Date
    let isDemo: Bool
    var stage: InterventionStage = .pause
    var reason: ReflectionReason = .habit
    var note = ""
    var intendedTask: String
    var selectedMinutes: Int
    var customMinutes = 20

    init(
        event: ApplicationEvent?,
        bundleIdentifier: String,
        applicationName: String,
        applicationURL: URL?,
        beganAt: Date,
        intendedTask: String,
        selectedMinutes: Int,
        isDemo: Bool = false
    ) {
        self.event = event
        self.bundleIdentifier = bundleIdentifier
        self.applicationName = applicationName
        self.applicationURL = applicationURL
        self.beganAt = beganAt
        self.intendedTask = intendedTask
        self.selectedMinutes = selectedMinutes
        self.isDemo = isDemo
    }

    func pauseSecondsRemaining(at date: Date) -> Int {
        max(0, 10 - Int(date.timeIntervalSince(beganAt)))
    }
}

enum PauseDuration: String, CaseIterable, Identifiable {
    case fifteenMinutes
    case oneHour
    case indefinitely

    var id: String { rawValue }

    var title: String {
        switch self {
        case .fifteenMinutes: "15 minutes"
        case .oneHour: "1 hour"
        case .indefinitely: "Until I resume"
        }
    }

    var interval: TimeInterval? {
        switch self {
        case .fifteenMinutes: 15 * 60
        case .oneHour: 60 * 60
        case .indefinitely: nil
        }
    }
}

@MainActor
@Observable
final class PauseRequest: Identifiable {
    let id = UUID()
    let beganAt: Date
    let wantsQuit: Bool
    var reason = ""
    var duration: PauseDuration = .fifteenMinutes

    init(beganAt: Date, wantsQuit: Bool) {
        self.beganAt = beganAt
        self.wantsQuit = wantsQuit
    }

    func secondsRemaining(at date: Date) -> Int {
        max(0, 30 - Int(date.timeIntervalSince(beganAt)))
    }
}

enum SessionNoticeKind {
    case warning
    case expired
}

struct SessionNotice: Identifiable {
    let id = UUID()
    let kind: SessionNoticeKind
    let applicationName: String
    let message: String
}
