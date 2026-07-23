import AppKit
import Foundation
import Observation
import SwiftData
import UniformTypeIdentifiers

@MainActor
@Observable
final class AppModel: ProtectionCoordinating {
    let preferences: AppPreferences

    var selectedSection: AppSection = .today
    var protectedApplications: [ProtectedApplication] = []
    var reflections: [ReflectionRecord] = []
    var sessions: [SessionRecord] = []
    var installedApplications: [InstalledApplication] = []
    var isDiscoveringApplications = false
    var activeIntervention: InterventionRequest?
    var pauseRequest: PauseRequest?
    var sessionNotice: SessionNotice?
    var now: Date
    var demoCompleted = false
    var errorMessage: String?

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private let monitor: ApplicationMonitoring
    @ObservationIgnored private let applicationController: ApplicationControlling
    @ObservationIgnored private let discoveryService: AppDiscoveryService
    @ObservationIgnored private let loginItemManager: LoginItemManaging
    @ObservationIgnored private let policy = ProtectionPolicy()
    @ObservationIgnored private let clock: ClockProviding
    @ObservationIgnored private let overlayController = OverlayPanelController()
    @ObservationIgnored private var tickerTask: Task<Void, Never>?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var eventDeduplicator = EventDeduplicator()

    init(
        container: ModelContainer,
        preferences: AppPreferences = AppPreferences(),
        monitor: ApplicationMonitoring = WorkspaceApplicationMonitor(),
        applicationController: ApplicationControlling = AppKitApplicationController(),
        discoveryService: AppDiscoveryService = AppDiscoveryService(),
        loginItemManager: LoginItemManaging = LoginItemManager(),
        clock: ClockProviding = SystemClock()
    ) {
        self.context = ModelContext(container)
        self.preferences = preferences
        self.monitor = monitor
        self.applicationController = applicationController
        self.discoveryService = discoveryService
        self.loginItemManager = loginItemManager
        self.clock = clock
        self.now = clock.now
        self.monitor.onEvent = { [weak self] event in
            self?.handleApplicationEvent(event)
        }
        refreshData()
    }

    var isProtectionPaused: Bool {
        preferences.isProtectionPaused(at: now)
    }

    var protectionStatusText: String {
        if isProtectionPaused {
            if preferences.pausedIndefinitely { return "Paused until you resume" }
            if let pausedUntil = preferences.pausedUntil {
                return "Paused until \(pausedUntil.formatted(date: .omitted, time: .shortened))"
            }
            return "Paused"
        }
        return preferences.onboardingCompleted ? "Protection is active" : "Finish setup to start protection"
    }

    var enabledRuleCount: Int {
        protectedApplications.filter(\.isEnabled).count
    }

    var activeSessions: [SessionRecord] {
        sessions.filter { $0.status == .active && $0.grantExpiresAt > now }
    }

    var declinedTodayCount: Int {
        reflections.filter {
            Calendar.current.isDateInToday($0.createdAt) && $0.decision == .returnedToFocus
        }.count
    }

    var intentionalTodayCount: Int {
        reflections.filter {
            Calendar.current.isDateInToday($0.createdAt) && $0.decision == .continuedIntentionally
        }.count
    }

    var allowedMinutesToday: Int {
        let seconds = sessions
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0.0) { total, session in
                let end = min(session.endedAt ?? now, session.grantExpiresAt)
                return total + max(0, end.timeIntervalSince(session.startedAt))
            }
        return Int(seconds / 60)
    }

    var isLaunchAtLoginEnabled: Bool { loginItemManager.isEnabled }
    var launchAtLoginStatus: String { loginItemManager.statusDescription }

    func start() {
        guard !started else { return }
        started = true
        pruneJournal()
        monitor.start()
        tickerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                self.tick()
            }
        }
        Task { await discoverApplications() }
    }

    func stop() {
        monitor.stop()
        tickerTask?.cancel()
        tickerTask = nil
        started = false
    }

    func refreshData() {
        do {
            protectedApplications = try context.fetch(FetchDescriptor<ProtectedApplication>(
                sortBy: [SortDescriptor(\.name)]
            ))
            reflections = try context.fetch(FetchDescriptor<ReflectionRecord>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))
            sessions = try context.fetch(FetchDescriptor<SessionRecord>(
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            ))
        } catch {
            errorMessage = "Limiter could not load its local data: \(error.localizedDescription)"
        }
    }

    func discoverApplications() async {
        isDiscoveringApplications = true
        installedApplications = await discoveryService.discoverInstalledApplications()
        isDiscoveringApplications = false
    }

    func addApplications(_ applications: [InstalledApplication]) {
        for application in applications {
            guard policy.isProtectable(bundleIdentifier: application.bundleIdentifier) else { continue }
            if let existing = protectedApplications.first(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
                existing.name = application.name
                existing.applicationPath = application.url.path
                existing.isEnabled = true
            } else {
                context.insert(ProtectedApplication(
                    bundleIdentifier: application.bundleIdentifier,
                    name: application.name,
                    applicationPath: application.url.path
                ))
            }
        }
        saveAndRefresh()
    }

    func addApplicationsUsingOpenPanel() {
        let panel = NSOpenPanel()
        panel.title = "Choose applications to protect"
        panel.message = "Limiter identifies apps by bundle ID. No access to their files is requested."
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        guard panel.runModal() == .OK else { return }
        addApplications(discoveryService.applications(from: panel.urls))
    }

    func isProtected(_ application: InstalledApplication) -> Bool {
        protectedApplications.contains { $0.bundleIdentifier == application.bundleIdentifier }
    }

    func toggleProtectedApplication(_ application: InstalledApplication) {
        if let existing = protectedApplications.first(where: { $0.bundleIdentifier == application.bundleIdentifier }) {
            context.delete(existing)
            saveAndRefresh()
        } else {
            addApplications([application])
        }
    }

    func removeProtectedApplication(_ application: ProtectedApplication) {
        context.delete(application)
        saveAndRefresh()
    }

    func updateRule(_ application: ProtectedApplication, enabled: Bool? = nil, minutes: Int? = nil) {
        if let enabled { application.isEnabled = enabled }
        if let minutes { application.defaultSessionMinutes = min(60, max(1, minutes)) }
        saveAndRefresh()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
        } catch {
            errorMessage = "Open at Login could not be changed: \(error.localizedDescription)"
        }
    }

    func openLoginItemSettings() {
        loginItemManager.openSystemSettings()
    }

    func completeOnboarding() {
        preferences.onboardingCompleted = true
        selectedSection = .today
    }

    func resetOnboarding() {
        preferences.onboardingCompleted = false
        demoCompleted = false
    }

    func showDemoIntervention() {
        activeIntervention = InterventionRequest(
            event: nil,
            bundleIdentifier: "com.limiter.demo",
            applicationName: "Demo Arcade",
            applicationURL: nil,
            beganAt: now,
            intendedTask: preferences.currentIntention,
            selectedMinutes: 15,
            isDemo: true
        )
        presentOverlay(size: NSSize(width: 600, height: 720))
    }

    func handleApplicationEvent(_ event: ApplicationEvent) {
        guard let bundleIdentifier = event.bundleIdentifier else { return }

        if event.kind == .terminated {
            handleTermination(bundleIdentifier: bundleIdentifier)
            return
        }

        guard preferences.onboardingCompleted,
              bundleIdentifier != Bundle.main.bundleIdentifier,
              let rule = protectedApplications.first(where: {
                  $0.bundleIdentifier == bundleIdentifier && $0.isEnabled
              })
        else { return }

        let matchingSession = sessions.first {
            $0.bundleIdentifier == bundleIdentifier &&
                ($0.status == .active || $0.status == .closingGrace)
        }

        guard policy.shouldIntercept(
            bundleIdentifier: bundleIdentifier,
            ruleEnabled: rule.isEnabled,
            grantExpiresAt: matchingSession?.status == .active ? matchingSession?.grantExpiresAt : nil,
            closingGraceUntil: matchingSession?.closingGraceUntil,
            protectionPaused: isProtectionPaused,
            now: now
        ) else { return }

        guard eventDeduplicator.shouldHandle(bundleIdentifier: bundleIdentifier, at: now) else {
            return
        }

        if let newURL = event.applicationURL {
            rule.applicationPath = newURL.path
        }
        applicationController.contain(event)
        activeIntervention = InterventionRequest(
            event: event,
            bundleIdentifier: bundleIdentifier,
            applicationName: event.applicationName,
            applicationURL: event.applicationURL ?? URL(fileURLWithPath: rule.applicationPath),
            beganAt: now,
            intendedTask: preferences.currentIntention,
            selectedMinutes: rule.defaultSessionMinutes
        )
        saveAndRefresh()
        presentOverlay(size: NSSize(width: 600, height: 720))
    }

    func advanceIntervention() {
        guard let request = activeIntervention else { return }
        switch request.stage {
        case .pause:
            request.stage = .duration
        case .duration:
            request.stage = .confirm
        case .confirm:
            allowIntentionalSession()
        }
    }

    func goBackInIntervention() {
        guard let request = activeIntervention else { return }
        switch request.stage {
        case .pause: returnToFocus()
        case .duration: request.stage = .pause
        case .confirm: request.stage = .duration
        }
    }

    func returnToFocus() {
        guard let request = activeIntervention else { return }
        if request.isDemo {
            demoCompleted = true
        } else {
            insertReflection(for: request, decision: .returnedToFocus, allowanceMinutes: nil)
            applicationController.terminateNormally(bundleIdentifier: request.bundleIdentifier)
        }
        activeIntervention = nil
        dismissOverlayIfEmpty()
    }

    func allowIntentionalSession() {
        guard let request = activeIntervention else { return }
        let minutes = request.selectedMinutes == -1 ? request.customMinutes : request.selectedMinutes
        let clampedMinutes = min(60, max(1, minutes))
        if request.isDemo {
            demoCompleted = true
        } else {
            insertReflection(for: request, decision: .continuedIntentionally, allowanceMinutes: clampedMinutes)
            let session = SessionRecord(
                bundleIdentifier: request.bundleIdentifier,
                applicationName: request.applicationName,
                startedAt: now,
                grantExpiresAt: now.addingTimeInterval(TimeInterval(clampedMinutes * 60)),
                plannedMinutes: clampedMinutes
            )
            context.insert(session)
            try? context.save()
            refreshData()
            applicationController.reveal(request)
        }
        activeIntervention = nil
        dismissOverlayIfEmpty()
    }

    func requestProtectionPause(wantsQuit: Bool = false) {
        pauseRequest = PauseRequest(beganAt: now, wantsQuit: wantsQuit)
        presentOverlay(size: NSSize(width: 520, height: 460))
    }

    func cancelProtectionPause() {
        pauseRequest = nil
        dismissOverlayIfEmpty()
    }

    func confirmProtectionPause() {
        guard let request = pauseRequest,
              request.secondsRemaining(at: now) == 0,
              !request.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        preferences.pause(for: request.duration, at: now)
        let wantsQuit = request.wantsQuit
        pauseRequest = nil
        dismissOverlayIfEmpty()
        if wantsQuit {
            stop()
            NSApplication.shared.terminate(nil)
        }
    }

    func resumeProtection() {
        preferences.resumeProtection()
    }

    func dismissSessionNotice() {
        sessionNotice = nil
        dismissOverlayIfEmpty()
    }

    func exportJournal() {
        let panel = NSSavePanel()
        panel.title = "Export Limiter Journal"
        panel.nameFieldStringValue = "Limiter-Journal.csv"
        panel.allowedContentTypes = [.commaSeparatedText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try JournalExporter.csv(records: reflections).write(to: url, atomically: true, encoding: .utf8)
        } catch {
            errorMessage = "The journal could not be exported: \(error.localizedDescription)"
        }
    }

    func clearJournal() {
        for reflection in reflections { context.delete(reflection) }
        for session in sessions { context.delete(session) }
        saveAndRefresh()
    }

    func deleteAllLocalData() {
        for rule in protectedApplications { context.delete(rule) }
        clearJournal()
        preferences.resetToDefaults()
        demoCompleted = false
        saveAndRefresh()
    }

    private func insertReflection(
        for request: InterventionRequest,
        decision: ReflectionDecision,
        allowanceMinutes: Int?
    ) {
        let record = ReflectionRecord(
            bundleIdentifier: request.bundleIdentifier,
            applicationName: request.applicationName,
            createdAt: now,
            reason: request.reason,
            note: preferences.journalEnabled ? request.note : "",
            intendedTask: preferences.journalEnabled ? request.intendedTask : "",
            decision: decision,
            allowanceMinutes: allowanceMinutes
        )
        context.insert(record)
        try? context.save()
        refreshData()
    }

    private func handleTermination(bundleIdentifier: String) {
        var changed = false
        for session in sessions where session.bundleIdentifier == bundleIdentifier {
            switch session.status {
            case .active:
                session.endedAt = now
                session.status = .completedEarly
                changed = true
            case .closingGrace:
                session.status = .expired
                session.closingGraceUntil = nil
                changed = true
            case .completedEarly, .expired:
                break
            }
        }
        if changed { saveAndRefresh() }
    }

    private func tick() {
        now = clock.now

        if let pausedUntil = preferences.pausedUntil, pausedUntil <= now {
            preferences.resumeProtection()
        }

        var changed = false
        for session in sessions {
            if session.status == .active {
                let remaining = session.grantExpiresAt.timeIntervalSince(now)
                if remaining <= 0 {
                    session.endedAt = session.grantExpiresAt
                    session.status = .closingGrace
                    session.closingGraceUntil = now.addingTimeInterval(120)
                    applicationController.terminateNormally(bundleIdentifier: session.bundleIdentifier)
                    sessionNotice = SessionNotice(
                        kind: .expired,
                        applicationName: session.applicationName,
                        message: "Your intentional session has ended. Limiter asked the app to close normally and left two minutes for any save prompt."
                    )
                    presentOverlay(size: NSSize(width: 440, height: 240))
                    changed = true
                } else if remaining <= TimeInterval(preferences.warningLeadSeconds), !session.warningShown {
                    session.warningShown = true
                    sessionNotice = SessionNotice(
                        kind: .warning,
                        applicationName: session.applicationName,
                        message: "About \(max(1, Int(ceil(remaining / 60)))) minute remains in this intentional session."
                    )
                    presentOverlay(size: NSSize(width: 420, height: 220))
                    changed = true
                    Task { [weak self] in
                        try? await Task.sleep(for: .seconds(6))
                        guard let self, self.sessionNotice?.kind == .warning else { return }
                        self.dismissSessionNotice()
                    }
                }
            } else if session.status == .closingGrace,
                      let closingGraceUntil = session.closingGraceUntil,
                      closingGraceUntil <= now {
                applicationController.hide(bundleIdentifier: session.bundleIdentifier)
                session.status = .expired
                session.closingGraceUntil = nil
                changed = true
            }
        }
        if changed { saveAndRefresh() }
    }

    private func pruneJournal() {
        let retention = JournalRetentionPolicy()
        for reflection in reflections where retention.shouldDelete(
            recordedAt: reflection.createdAt,
            now: now,
            retentionDays: preferences.journalRetentionDays
        ) {
            context.delete(reflection)
        }
        for session in sessions where session.status != .active && retention.shouldDelete(
            recordedAt: session.startedAt,
            now: now,
            retentionDays: preferences.journalRetentionDays
        ) {
            context.delete(session)
        }
        saveAndRefresh()
    }

    private func saveAndRefresh() {
        do {
            try context.save()
            refreshData()
        } catch {
            errorMessage = "Limiter could not save its local data: \(error.localizedDescription)"
        }
    }

    private func presentOverlay(size: NSSize) {
        overlayController.present(model: self, size: size)
    }

    private func dismissOverlayIfEmpty() {
        if activeIntervention == nil && pauseRequest == nil && sessionNotice == nil {
            overlayController.dismiss()
        }
    }
}
