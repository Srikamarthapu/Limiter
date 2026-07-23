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
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        SectionHeader(
                            eyebrow: "Preferences",
                            title: "Settings",
                            subtitle: "Keep Limiter calm, transparent, and easy to recover from."
                        )
                        Form { settingsSections(palette: palette) }
                            .formStyle(.grouped)
                            .scrollDisabled(true)
                    }
                    .padding(30)
                    .frame(maxWidth: 850)
                }
            }
        }
        .confirmationDialog("Delete all Limiter data?", isPresented: $confirmDeleteAll) {
            Button("Delete all local data", role: .destructive) { model.deleteAllLocalData() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes rules, reflections, sessions, and your current intention, then returns to setup.")
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
