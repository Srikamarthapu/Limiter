import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var step = 0
    @State private var stepDirection = 1
    @State private var searchText = ""

    private var palette: LimiterPalette { .resolve(colorScheme) }
    private let steps = ["Welcome", "Choose apps", "Your intention", "Session defaults", "Try the pause"]

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 230)
            Divider()
            VStack(spacing: 0) {
                ScrollView {
                    stepContent
                        .frame(maxWidth: 720, alignment: .leading)
                        .padding(42)
                        .id(step)
                        .transition(stepTransition)
                }
                Divider()
                footer
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(palette.surface)
            }
        }
        .background(palette.background)
        .animation(reduceMotion ? nil : LimiterMotion.standard, value: step)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(spacing: 11) {
                Image(systemName: "shield.checkered")
                    .font(.title2)
                    .foregroundStyle(palette.amber)
                Text("Limiter")
                    .font(.system(.title2, design: .rounded, weight: .bold))
            }

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, title in
                    HStack(spacing: 11) {
                        ZStack {
                            Circle()
                                .fill(index <= step ? palette.pine : palette.border)
                                .frame(width: 26, height: 26)
                            if index < step {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundStyle(index == step ? .white : palette.secondaryInk)
                            }
                        }
                        Text(title)
                            .font(.subheadline.weight(index == step ? .semibold : .regular))
                            .foregroundStyle(index <= step ? palette.ink : palette.secondaryInk)
                    }
                }
            }
            Spacer()
            Label("Private by design", systemImage: "lock.shield")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.success)
        }
        .padding(28)
        .background(palette.surface)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0: welcomeStep
        case 1: appSelectionStep
        case 2: intentionStep
        case 3: defaultsStep
        default: demoStep
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 28) {
            SectionHeader(
                eyebrow: "Welcome",
                title: "Make distraction deliberate.",
                subtitle: "Limiter adds a calm threshold between opening a distracting app and losing the next few hours."
            )

            SurfaceCard {
                VStack(spacing: 0) {
                    onboardingFeature(icon: "command", title: "Keep using Spotlight", message: "Open apps exactly as you do today.")
                    Divider().padding(.leading, 42)
                    onboardingFeature(icon: "eye.slash", title: "Nothing watches you", message: "No keystrokes, screen capture, account, or telemetry.")
                    Divider().padding(.leading, 42)
                    onboardingFeature(icon: "hand.raised", title: "You stay in control", message: "Pause, quit, or uninstall Limiter whenever you choose.")
                }
            }

            QuietPanel {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(palette.amber)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("A transparent user-space tool")
                            .font(.headline)
                        Text("Limiter reacts to normal app launches, hides or asks selected apps to close normally, and never force-quits them.")
                            .foregroundStyle(palette.secondaryInk)
                    }
                }
            }
        }
    }

    private var appSelectionStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            SectionHeader(
                eyebrow: "Choose apps",
                title: "What tends to pull you in?",
                subtitle: "Select games, social apps, or anything else you want Limiter to gate. System-critical apps are excluded."
            )
            AppSelectionList(searchText: $searchText)
                .frame(minHeight: 390)
        }
    }

    private var intentionStep: some View {
        VStack(alignment: .leading, spacing: 26) {
            SectionHeader(
                eyebrow: "Your intention",
                title: "What are you protecting time for?",
                subtitle: "Limiter will bring this intention back at the exact moment a distraction appears. You can change it any time."
            )
            SurfaceCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Current intention", systemImage: "target")
                        .font(.headline)
                    TextField("Finish my assignment, ship the feature, study for the exam…", text: Binding(
                        get: { model.preferences.currentIntention },
                        set: { model.preferences.currentIntention = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    Text("This is stored only on this Mac.")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                    Divider()
                    Label("You’ll see this sentence when a protected app opens.", systemImage: "arrow.turn.down.right")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryInk)
                }
            }
        }
    }

    private var defaultsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(
                eyebrow: "Defaults",
                title: "Set a sensible first limit.",
                subtitle: "You will still choose a duration each time. These values simply make the deliberate option faster."
            )
            VStack(spacing: 10) {
                ForEach(model.protectedApplications) { application in
                    SurfaceCard {
                        HStack(spacing: 14) {
                            AppIconView(path: application.applicationPath, size: 42)
                            Text(application.name)
                                .font(.headline)
                            Spacer()
                            Menu {
                                ForEach([5, 10, 15, 30], id: \.self) { minute in
                                    Button("\(minute) minutes") {
                                        model.updateRule(application, minutes: minute)
                                    }
                                }
                            } label: {
                                Label("\(application.defaultSessionMinutes) minutes", systemImage: "timer")
                                    .frame(minWidth: 112, alignment: .leading)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()
                            .accessibilityLabel("Default duration for \(application.name)")
                            .accessibilityValue("\(application.defaultSessionMinutes) minutes")
                        }
                    }
                }
            }
            SurfaceCard {
                HStack(spacing: 14) {
                    Image(systemName: "power")
                        .foregroundStyle(palette.pine)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open Limiter at login")
                            .font(.headline)
                        Text(model.launchAtLoginStatus)
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { model.isLaunchAtLoginEnabled },
                        set: { model.setLaunchAtLogin($0) }
                    ))
                    .labelsHidden()
                    .disabled(!model.isLaunchAtLoginAvailable)
                    if model.launchAtLoginStatus.contains("approval") || !model.isLaunchAtLoginAvailable {
                        Button("Open Login Items") { model.openLoginItemSettings() }
                    }
                }
            }
        }
    }

    private var demoStep: some View {
        VStack(alignment: .leading, spacing: 26) {
            SectionHeader(
                eyebrow: "Practice",
                title: "Try the pause safely.",
                subtitle: "This demo uses an imaginary app. Nothing on your Mac will be closed or changed."
            )
            SurfaceCard {
                HStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(palette.pine)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(palette.amber)
                    }
                    .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Demo Arcade")
                            .font(.title2.bold())
                        Text("Run the same reflection that will appear when a protected app opens.")
                            .foregroundStyle(palette.secondaryInk)
                    }
                    Spacer()
                    if model.demoCompleted {
                        Label("Completed", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(palette.success)
                    } else {
                        Button("Run demo") { model.showDemoIntervention() }
                            .buttonStyle(AmberButtonStyle())
                    }
                }
            }
            Text("Limiter is a focus aid, not parental control or medical treatment. You can pause, quit, or uninstall it at any time.")
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
        }
    }

    private var footer: some View {
        HStack {
            if step > 0 {
                Button("Back") {
                    stepDirection = -1
                    step -= 1
                }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Spacer()
            Text("Step \(step + 1) of \(steps.count)")
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
            Button(step == steps.count - 1 ? "Start protecting my time" : "Continue") {
                if step == steps.count - 1 {
                    model.completeOnboarding()
                } else {
                    stepDirection = 1
                    step += 1
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!canContinue)
            .keyboardShortcut(.defaultAction)
        }
    }

    private var canContinue: Bool {
        switch step {
        case 1: !model.protectedApplications.isEmpty
        case 4: model.demoCompleted
        default: true
        }
    }

    private func onboardingFeature(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.pine)
                .frame(width: 28, height: 28)
                .background(palette.pine.opacity(0.09), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 13)
    }

    private var stepTransition: AnyTransition {
        guard !reduceMotion else { return .opacity }
        let insertion: Edge = stepDirection > 0 ? .trailing : .leading
        let removal: Edge = stepDirection > 0 ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: insertion).combined(with: .opacity),
            removal: .move(edge: removal).combined(with: .opacity)
        )
    }
}

struct AppSelectionList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Binding var searchText: String

    private var filteredApplications: [InstalledApplication] {
        let applications = model.installedApplications.filter {
            searchText.isEmpty ||
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
        return applications.sorted { lhs, rhs in
            if model.isProtected(lhs) != model.isProtected(rhs) {
                return model.isProtected(lhs)
            }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }

    private var suggestedApplications: [InstalledApplication] {
        guard searchText.isEmpty else { return [] }
        return filteredApplications.filter { distractionScore(for: $0) > 0 }
            .sorted {
                let lhsScore = distractionScore(for: $0)
                let rhsScore = distractionScore(for: $1)
                return lhsScore == rhsScore
                    ? $0.name.localizedStandardCompare($1.name) == .orderedAscending
                    : lhsScore > rhsScore
            }
            .prefix(8)
            .map { $0 }
    }

    private var otherApplications: [InstalledApplication] {
        let suggestedIDs = Set(suggestedApplications.map(\.bundleIdentifier))
        return filteredApplications.filter { !suggestedIDs.contains($0.bundleIdentifier) }
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        SurfaceCard {
            VStack(spacing: 14) {
                HStack {
                    TextField("Search installed apps", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !model.protectedApplications.isEmpty {
                        Text("\(model.protectedApplications.count) selected")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(palette.success)
                    }
                    Button("Add Other App…") { model.addApplicationsUsingOpenPanel() }
                        .buttonStyle(SecondaryButtonStyle())
                }
                if model.isDiscoveringApplications {
                    ProgressView("Finding installed applications…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredApplications.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass", title: "No apps found", message: "Try another search or choose an app manually.")
                } else {
                    List {
                        if !suggestedApplications.isEmpty {
                            Section("Likely distractions") {
                                ForEach(suggestedApplications) { application in
                                    appRow(application, palette: palette)
                                }
                            }
                        }
                        Section(suggestedApplications.isEmpty ? "Applications" : "All applications") {
                            ForEach(otherApplications) { application in
                                appRow(application, palette: palette)
                            }
                        }
                    }
                    .listStyle(.inset)
                }
            }
        }
    }

    private func appRow(_ application: InstalledApplication, palette: LimiterPalette) -> some View {
        Button {
            model.toggleProtectedApplication(application)
        } label: {
            HStack(spacing: 12) {
                AppIconView(path: application.url.path, size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.name)
                        .font(.body.weight(.medium))
                    Text(application.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                }
                Spacer()
                Image(systemName: model.isProtected(application) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(model.isProtected(application) ? palette.success : palette.secondaryInk)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.isProtected(application) ? .isSelected : [])
    }

    private func distractionScore(for application: InstalledApplication) -> Int {
        let value = "\(application.name) \(application.bundleIdentifier)".lowercased()
        let highSignal = ["roblox", "steam", "epicgames", "minecraft", "discord", "tiktok", "instagram", "youtube", "netflix"]
        let mediumSignal = ["game", "chess", "telegram", "spotify", "music", "podcast", "tv", "geforce", "opera", "chrome", "safari"]
        if highSignal.contains(where: value.contains) { return 2 }
        if mediumSignal.contains(where: value.contains) { return 1 }
        return 0
    }
}
