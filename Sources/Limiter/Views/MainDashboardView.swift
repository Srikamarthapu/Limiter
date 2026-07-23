import SwiftUI

struct MainDashboardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        NavigationSplitView {
            List(AppSection.allCases, selection: Binding(
                get: { model.selectedSection },
                set: { model.selectedSection = $0 ?? .today }
            )) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationTitle("Limiter")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    StatusPill(
                        title: model.isProtectionPaused ? "Protection paused" : "Protection active",
                        systemImage: model.isProtectionPaused ? "pause.fill" : "checkmark.shield.fill",
                        isPositive: !model.isProtectionPaused
                    )
                    Text("\(model.enabledRuleCount) protected app\(model.enabledRuleCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }
                .padding(14)
                .background(.ultraThinMaterial)
            }
        } detail: {
            ZStack {
                AppBackground()
                switch model.selectedSection {
                case .today: TodayView()
                case .protectedApps: ProtectedAppsView()
                case .journal: JournalView()
                case .settings: SettingsContentView(isStandalone: false)
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    if model.isProtectionPaused {
                        Button("Resume protection", systemImage: "play.fill") {
                            model.resumeProtection()
                        }
                    } else {
                        Button("Pause protection", systemImage: "pause.fill") {
                            model.requestProtectionPause()
                        }
                    }
                    Button("Add apps", systemImage: "plus") {
                        model.addApplicationsUsingOpenPanel()
                    }
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack(alignment: .top) {
                    SectionHeader(
                        eyebrow: Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()),
                        title: greeting,
                        subtitle: model.protectionStatusText
                    )
                    Spacer()
                    StatusPill(
                        title: model.isProtectionPaused ? "Paused" : "Active",
                        systemImage: model.isProtectionPaused ? "pause.fill" : "checkmark.shield.fill",
                        isPositive: !model.isProtectionPaused
                    )
                }

                HStack(spacing: 16) {
                    MetricCard(
                        title: "Launches declined",
                        value: "\(model.declinedTodayCount)",
                        systemImage: "arrow.uturn.backward",
                        tint: palette.success
                    )
                    MetricCard(
                        title: "Intentional sessions",
                        value: "\(model.intentionalTodayCount)",
                        systemImage: "checkmark.seal",
                        tint: palette.amber
                    )
                    MetricCard(
                        title: "Allowed session time",
                        value: "\(model.allowedMinutesToday)m",
                        systemImage: "timer",
                        tint: palette.pine
                    )
                }

                SurfaceCard {
                    HStack(alignment: .top, spacing: 18) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(palette.amber.opacity(0.15))
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundStyle(palette.amber)
                        }
                        .frame(width: 52, height: 52)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What are you protecting time for?")
                                .font(.headline)
                            TextField("Set your current intention", text: Binding(
                                get: { model.preferences.currentIntention },
                                set: { model.preferences.currentIntention = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.title3)
                            Divider()
                            Text("Limiter will bring this back when a protected app opens.")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryInk)
                        }
                    }
                }

                if !model.activeSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active sessions")
                            .font(.title2.bold())
                        ForEach(model.activeSessions) { session in
                            ActiveSessionRow(session: session)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent choices")
                        .font(.title2.bold())
                    if model.reflections.isEmpty {
                        SurfaceCard {
                            EmptyStateView(
                                systemImage: "sparkles",
                                title: "Your first deliberate choice will appear here",
                                message: "Limiter records outcomes locally without claiming to know how much time you saved."
                            )
                        }
                    } else {
                        ForEach(model.reflections.prefix(4)) { record in
                            ReflectionRow(record: record)
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 1050)
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning." }
        if hour < 18 { return "Good afternoon." }
        return "Good evening."
    }
}

struct ActiveSessionRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    let session: SessionRecord

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        let remaining = max(0, Int(session.grantExpiresAt.timeIntervalSince(model.now)))
        SurfaceCard {
            HStack(spacing: 14) {
                AppIconView(
                    path: model.protectedApplications.first(where: { $0.bundleIdentifier == session.bundleIdentifier })?.applicationPath,
                    size: 42
                )
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.applicationName)
                        .font(.headline)
                    Text("Ends at \(session.grantExpiresAt.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }
                Spacer()
                Text(Self.format(seconds: remaining))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(palette.amber)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(session.applicationName), \(remaining / 60) minutes remaining")
    }

    static func format(seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

struct ProtectedAppsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @State private var searchText = ""
    @State private var sheet: AppPickerSheet?

    private enum AppPickerSheet: String, Identifiable {
        case picker
        var id: String { rawValue }
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        eyebrow: "Rules",
                        title: "Protected apps",
                        subtitle: "Each selected app gets the same deliberate pause, with its own sensible default."
                    )
                    Spacer()
                    Button("Browse installed apps", systemImage: "square.grid.2x2") {
                        sheet = .picker
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }

                if model.protectedApplications.isEmpty {
                    SurfaceCard {
                        EmptyStateView(
                            systemImage: "plus.app",
                            title: "No apps protected yet",
                            message: "Add a game or distracting app to begin. Limiter excludes system-critical processes."
                        )
                    }
                } else {
                    VStack(spacing: 12) {
                        ForEach(model.protectedApplications) { application in
                            protectedAppCard(application, palette: palette)
                        }
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 1000)
        }
        .sheet(item: $sheet) { _ in
            VStack(spacing: 0) {
                HStack {
                    Text("Choose protected apps")
                        .font(.title2.bold())
                    Spacer()
                    Button("Done") { sheet = nil }
                        .keyboardShortcut(.defaultAction)
                }
                .padding(20)
                Divider()
                AppSelectionList(searchText: $searchText)
                    .padding(20)
            }
            .frame(width: 650, height: 620)
            .background(palette.background)
        }
    }

    private func protectedAppCard(_ application: ProtectedApplication, palette: LimiterPalette) -> some View {
        SurfaceCard {
            HStack(spacing: 16) {
                AppIconView(path: application.applicationPath, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(application.name)
                        .font(.title3.weight(.semibold))
                    Text(application.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }
                Spacer()
                Picker("Default", selection: Binding(
                    get: { application.defaultSessionMinutes },
                    set: { model.updateRule(application, minutes: $0) }
                )) {
                    ForEach([5, 10, 15, 30], id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 130)
                Toggle("Protected", isOn: Binding(
                    get: { application.isEnabled },
                    set: { model.updateRule(application, enabled: $0) }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                Button(role: .destructive) {
                    model.removeProtectedApplication(application)
                } label: {
                    Image(systemName: "trash")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .foregroundStyle(palette.danger)
                .help("Remove \(application.name) from Limiter")
                .accessibilityLabel("Remove \(application.name)")
            }
        }
    }
}

struct JournalView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @State private var confirmClear = false

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .bottom) {
                    SectionHeader(
                        eyebrow: "Local journal",
                        title: "Choices, not judgment.",
                        subtitle: "Your reasons and outcomes stay on this Mac. Use them to notice patterns, not to score yourself."
                    )
                    Spacer()
                    Button("Export CSV", systemImage: "square.and.arrow.up") { model.exportJournal() }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(model.reflections.isEmpty)
                    Button("Clear", systemImage: "trash", role: .destructive) { confirmClear = true }
                        .buttonStyle(SecondaryButtonStyle())
                        .disabled(model.reflections.isEmpty)
                }

                if model.reflections.isEmpty {
                    SurfaceCard {
                        EmptyStateView(
                            systemImage: "book.closed",
                            title: "No reflections yet",
                            message: "Once Limiter catches a protected app, your deliberate choice will appear here."
                        )
                    }
                } else {
                    ForEach(model.reflections) { record in
                        ReflectionRow(record: record)
                    }
                }
            }
            .padding(30)
            .frame(maxWidth: 960)
        }
        .confirmationDialog("Clear the local journal?", isPresented: $confirmClear) {
            Button("Clear journal", role: .destructive) { model.clearJournal() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently deletes reflections and session history, but keeps your protected-app rules.")
        }
        .foregroundStyle(palette.ink)
    }
}

struct ReflectionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let record: ReflectionRecord

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: record.decision == .returnedToFocus ? "arrow.uturn.backward.circle.fill" : "timer.circle.fill")
                    .font(.title2)
                    .foregroundStyle(record.decision == .returnedToFocus ? palette.success : palette.amber)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 7) {
                    HStack {
                        Text(record.applicationName)
                            .font(.headline)
                        Spacer()
                        Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    Text(record.decision == .returnedToFocus
                         ? "Returned to focus"
                         : "Opened intentionally for \(record.allowanceMinutes ?? 0) minutes")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(record.decision == .returnedToFocus ? palette.success : palette.amber)
                    Label(record.reason.title, systemImage: record.reason.systemImage)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                    if !record.intendedTask.isEmpty {
                        Text("Intention: \(record.intendedTask)")
                            .font(.subheadline)
                    }
                    if !record.note.isEmpty {
                        Text(record.note)
                            .font(.subheadline)
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
            }
        }
    }
}
