import SwiftUI

struct OnboardingView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @State private var step = 0
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
                }
                Divider()
                footer
                    .padding(.horizontal, 32)
                    .padding(.vertical, 18)
                    .background(palette.surface)
            }
        }
        .background(palette.background)
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

            HStack(spacing: 16) {
                onboardingFeature(icon: "command", title: "Keep Spotlight", message: "Use Command–Space exactly as you do today.")
                onboardingFeature(icon: "eye.slash", title: "No surveillance", message: "No keystrokes, screen recording, accounts, or telemetry.")
                onboardingFeature(icon: "hand.raised", title: "Always your choice", message: "Limiter adds friction, not unbreakable parental control.")
            }

            SurfaceCard {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(palette.amber)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("A transparent user-space tool")
                            .font(.headline)
                        Text("macOS does not offer native Screen Time shielding to third-party Mac apps. Limiter observes normal app launches, hides or asks selected apps to close normally, and never force-quits them.")
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
                }
            }
            SurfaceCard {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: "quote.opening")
                        .foregroundStyle(palette.pine)
                    Text("“Does opening this app match what I came here to do?” is more useful than shame. Limiter keeps the language supportive and the choice explicit.")
                        .font(.title3)
                        .foregroundStyle(palette.ink)
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
                            Picker("Default duration", selection: Binding(
                                get: { application.defaultSessionMinutes },
                                set: { model.updateRule(application, minutes: $0) }
                            )) {
                                ForEach([5, 10, 15, 30], id: \.self) { minute in
                                    Text("\(minute) min").tag(minute)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 135)
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
                    if model.launchAtLoginStatus.contains("approval") {
                        Button("Open Settings") { model.openLoginItemSettings() }
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
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(palette.pine)
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(palette.amber)
                    }
                    .frame(width: 88, height: 88)
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
                Button("Back") { step -= 1 }
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
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(palette.pine)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
        }
    }
}

struct AppSelectionList: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Binding var searchText: String

    private var filteredApplications: [InstalledApplication] {
        guard !searchText.isEmpty else { return model.installedApplications }
        return model.installedApplications.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        SurfaceCard {
            VStack(spacing: 14) {
                HStack {
                    TextField("Search installed apps", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Button("Add Other App…") { model.addApplicationsUsingOpenPanel() }
                        .buttonStyle(SecondaryButtonStyle())
                }
                if model.isDiscoveringApplications {
                    ProgressView("Finding installed applications…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredApplications.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass", title: "No apps found", message: "Try another search or choose an app manually.")
                } else {
                    List(filteredApplications) { application in
                        Button {
                            model.toggleProtectedApplication(application)
                        } label: {
                            HStack(spacing: 12) {
                                AppIconView(path: application.url.path, size: 38)
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
                    .listStyle(.inset)
                }
            }
        }
    }
}
