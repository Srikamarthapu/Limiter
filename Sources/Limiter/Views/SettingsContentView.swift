import SwiftUI

struct SettingsContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    let isStandalone: Bool
    @State private var confirmDeleteAll = false

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        Group {
            if isStandalone {
                Form { settingsSections(palette: palette) }
                    .formStyle(.grouped)
                    .padding(8)
            } else {
                editorialSettings(palette: palette)
            }
        }
        .confirmationDialog("Delete all Limiter data?", isPresented: $confirmDeleteAll) {
            Button("Delete all local data", role: .destructive) { model.deleteAllLocalData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes rules, reflections, sessions, and your current intention, then returns to setup.")
        }
    }

    private func editorialSettings(palette: LimiterPalette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 44) {
                EditorialPageHeader(
                    eyebrow: "Preferences",
                    title: "Settings",
                    subtitle: "Keep Limiter calm, transparent, and easy to recover from."
                )

                EditorialSettingsSection(title: "Protection") {
                    EditorialSettingsRow(title: "Protection status", subtitle: model.protectionStatusText) {
                        Text(model.isProtectionPaused ? "Paused" : "Active")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(model.isProtectionPaused ? palette.amber : palette.success)
                    }
                    EditorialSettingsRow(title: "Open Limiter at login", subtitle: model.launchAtLoginStatus) {
                        Toggle("Open Limiter at login", isOn: Binding(
                            get: { model.isLaunchAtLoginEnabled },
                            set: { model.setLaunchAtLogin($0) }
                        ))
                        .disabled(!model.isLaunchAtLoginAvailable)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    HStack(spacing: 16) {
                        Button(model.isProtectionPaused ? "Resume protection" : "Pause protection…") {
                            if model.isProtectionPaused {
                                model.resumeProtection()
                            } else {
                                model.requestProtectionPause()
                            }
                        }
                        .buttonStyle(ShellActionButtonStyle(isBordered: true))
                        if model.launchAtLoginStatus.contains("approval") || !model.isLaunchAtLoginAvailable {
                            Button("Open Login Items Settings") { model.openLoginItemSettings() }
                                .buttonStyle(ShellActionButtonStyle(isBordered: false))
                        }
                    }
                    .padding(.top, 12)
                }

                EditorialSettingsSection(title: "Intervention") {
                    EditorialSettingsRow(
                        title: "Current intention",
                        subtitle: "Shown when Limiter catches a protected app."
                    ) {
                        TextField("Current intention", text: Binding(
                            get: { model.preferences.currentIntention },
                            set: { model.preferences.currentIntention = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 380)
                    }
                    EditorialSettingsRow(title: "Session warning", subtitle: "A quiet notification before time expires.") {
                        Picker("Session warning", selection: Binding(
                            get: { model.preferences.warningLeadSeconds },
                            set: { model.preferences.warningLeadSeconds = $0 }
                        )) {
                            Text("30 seconds before").tag(30)
                            Text("1 minute before").tag(60)
                            Text("2 minutes before").tag(120)
                        }
                        .labelsHidden()
                        .frame(width: 180)
                    }
                }

                EditorialSettingsSection(title: "Journal and privacy") {
                    EditorialSettingsRow(
                        title: "Save reflection text locally",
                        subtitle: "Limiter never sends your journal off this Mac."
                    ) {
                        Toggle("Save reflection text locally", isOn: Binding(
                            get: { model.preferences.journalEnabled },
                            set: { model.preferences.journalEnabled = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    EditorialSettingsRow(title: "Keep journal", subtitle: "Delete older entries automatically if you prefer.") {
                        Picker("Keep journal", selection: Binding(
                            get: { model.preferences.journalRetentionDays },
                            set: { model.preferences.journalRetentionDays = $0 }
                        )) {
                            Text("Forever").tag(0)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                        }
                        .labelsHidden()
                        .frame(width: 140)
                    }
                    Button("Export journal…", systemImage: "square.and.arrow.up") { model.exportJournal() }
                        .buttonStyle(ShellActionButtonStyle(isBordered: true))
                        .disabled(model.reflections.isEmpty)
                        .padding(.top, 12)
                }

                EditorialSettingsSection(title: "Appearance") {
                    EditorialSettingsRow(title: "Theme", subtitle: "Use the system setting or choose a fixed appearance.") {
                        Picker("Theme", selection: Binding(
                            get: { model.preferences.appearance },
                            set: { model.preferences.appearance = $0 }
                        )) {
                            ForEach(AppearancePreference.allCases) { appearance in
                                Text(appearance.title).tag(appearance)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                        .frame(width: 240)
                    }
                }

                EditorialSettingsSection(title: "Reset") {
                    HStack(spacing: 16) {
                        Button("Run onboarding again") { model.resetOnboarding() }
                            .buttonStyle(ShellActionButtonStyle(isBordered: true))
                        Button("Delete all local data…", role: .destructive) { confirmDeleteAll = true }
                            .buttonStyle(ShellActionButtonStyle(isBordered: false))
                            .foregroundStyle(palette.danger)
                    }
                    Text("Limiter is a focus aid, not unbreakable parental control or medical treatment.")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryInk)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 46)
            .padding(.top, 50)
            .padding(.bottom, 70)
            .frame(maxWidth: 1120, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            LinearGradient(
                colors: [palette.surface.opacity(0.16), palette.background, palette.background],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    @ViewBuilder
    private func settingsSections(palette: LimiterPalette) -> some View {
        Section("Protection") {
            LabeledContent("Status") {
                StatusPill(
                    title: model.isProtectionPaused ? "Paused" : "Active",
                    systemImage: model.isProtectionPaused ? "pause.fill" : "checkmark.shield.fill",
                    isPositive: !model.isProtectionPaused
                )
            }
            if model.isProtectionPaused {
                Button("Resume protection") { model.resumeProtection() }
            } else {
                Button("Pause protection…") { model.requestProtectionPause() }
            }
            Toggle("Open Limiter at login", isOn: Binding(
                get: { model.isLaunchAtLoginEnabled },
                set: { model.setLaunchAtLogin($0) }
            ))
            .disabled(!model.isLaunchAtLoginAvailable)
            LabeledContent("Login item") {
                Text(model.launchAtLoginStatus)
                    .foregroundStyle(palette.secondaryInk)
            }
            if model.launchAtLoginStatus.contains("approval") || !model.isLaunchAtLoginAvailable {
                Button("Open Login Items Settings") { model.openLoginItemSettings() }
            }
        }

        Section("Intervention") {
            TextField("Current intention", text: Binding(
                get: { model.preferences.currentIntention },
                set: { model.preferences.currentIntention = $0 }
            ))
            Picker("Session warning", selection: Binding(
                get: { model.preferences.warningLeadSeconds },
                set: { model.preferences.warningLeadSeconds = $0 }
            )) {
                Text("30 seconds before").tag(30)
                Text("1 minute before").tag(60)
                Text("2 minutes before").tag(120)
            }
        }

        Section("Journal and privacy") {
            Toggle("Save reflection text locally", isOn: Binding(
                get: { model.preferences.journalEnabled },
                set: { model.preferences.journalEnabled = $0 }
            ))
            Picker("Keep journal", selection: Binding(
                get: { model.preferences.journalRetentionDays },
                set: { model.preferences.journalRetentionDays = $0 }
            )) {
                Text("Forever").tag(0)
                Text("30 days").tag(30)
                Text("90 days").tag(90)
            }
            Button("Export journal…") { model.exportJournal() }
                .disabled(model.reflections.isEmpty)
            Text("Limiter has no account, telemetry, advertising, cloud sync, or network service.")
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
        }

        Section("Appearance") {
            Picker("Theme", selection: Binding(
                get: { model.preferences.appearance },
                set: { model.preferences.appearance = $0 }
            )) {
                ForEach(AppearancePreference.allCases) { appearance in
                    Text(appearance.title).tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }

        Section("Reset") {
            Button("Run onboarding again") { model.resetOnboarding() }
            Button("Delete all local data…", role: .destructive) { confirmDeleteAll = true }
                .foregroundStyle(palette.danger)
            Text("Limiter is a focus aid, not unbreakable parental control or medical treatment.")
                .font(.caption)
                .foregroundStyle(palette.secondaryInk)
        }
    }
}

private struct EditorialSettingsSection<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    private let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.35)
                .foregroundStyle(palette.amber)
                .padding(.bottom, 14)
            Rectangle()
                .fill(palette.border)
                .frame(height: 1)
            content
        }
    }
}

private struct EditorialSettingsRow<Control: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String
    private let control: Control

    init(title: String, subtitle: String, @ViewBuilder control: () -> Control) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        HStack(alignment: .center, spacing: 30) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(palette.ink)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }
            Spacer(minLength: 24)
            control
        }
        .padding(.vertical, 18)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
    }
}
