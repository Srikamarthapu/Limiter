import AppKit
import SwiftUI

struct MainDashboardView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        HStack(spacing: 0) {
            LimiterSidebar()
                .frame(width: 232)

            VStack(spacing: 0) {
                LimiterTopBar()
                Rectangle()
                    .fill(palette.border)
                    .frame(height: 1)

                ZStack {
                    palette.background
                    detail
                        .id(model.selectedSection)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
                }
            }
        }
        .background(palette.background)
        .animation(reduceMotion ? nil : LimiterMotion.quick, value: model.selectedSection)
    }

    @ViewBuilder
    private var detail: some View {
        switch model.selectedSection {
        case .today: TodayView()
        case .protectedApps: ProtectedAppsView()
        case .journal: JournalView()
        case .settings: SettingsContentView(isStandalone: false)
        }
    }
}

private struct LimiterSidebar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                Image(nsImage: NSApplication.shared.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 25, height: 25)
                    .accessibilityHidden(true)
                Text("Limiter")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(palette.ink)
            }
            .padding(.horizontal, 26)
            .padding(.top, 54)
            .padding(.bottom, 30)

            VStack(spacing: 8) {
                ForEach(AppSection.allCases) { section in
                    sidebarButton(section, palette: palette)
                }
            }

            Spacer(minLength: 28)

            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(palette.border)
                    .frame(height: 1)
                    .padding(.bottom, 12)
                Label(
                    model.isProtectionPaused ? "Protection paused" : "Protection active",
                    systemImage: model.isProtectionPaused ? "pause.shield.fill" : "checkmark.shield.fill"
                )
                .font(.subheadline.weight(.medium))
                .foregroundStyle(model.isProtectionPaused ? palette.amber : palette.success)
                Text("\(model.enabledRuleCount) protected app\(model.enabledRuleCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 28)
        }
        .background(palette.surface)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(palette.amber.opacity(0.82))
                .frame(width: 1)
                .accessibilityHidden(true)
        }
    }

    private func sidebarButton(_ section: AppSection, palette: LimiterPalette) -> some View {
        let isSelected = model.selectedSection == section
        return Button {
            withAnimation(reduceMotion ? nil : LimiterMotion.quick) {
                model.selectedSection = section
            }
        } label: {
            HStack(spacing: 15) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 17, weight: .medium))
                    .symbolRenderingMode(.monochrome)
                    .frame(width: 24)
                Text(section.title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular, design: .rounded))
                Spacer()
                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isSelected ? palette.amber : palette.ink)
            .padding(.horizontal, 25)
            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
            .background(isSelected ? palette.elevatedSurface.opacity(0.72) : Color.clear)
            .overlay(alignment: .leading) {
                if isSelected {
                    Rectangle()
                        .fill(palette.amber)
                        .frame(width: 3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct LimiterTopBar: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                Text(Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day()).uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.35)
                    .foregroundStyle(palette.amber)
                HStack(spacing: 9) {
                    Image(systemName: model.isProtectionPaused ? "pause.shield.fill" : "checkmark.shield.fill")
                        .foregroundStyle(model.isProtectionPaused ? palette.amber : palette.success)
                        .accessibilityHidden(true)
                    Text(model.isProtectionPaused ? model.protectionStatusText : "Protection active")
                        .foregroundStyle(palette.ink)
                    Text("·")
                        .foregroundStyle(palette.secondaryInk)
                    Text("\(model.enabledRuleCount) protected app\(model.enabledRuleCount == 1 ? "" : "s")")
                        .foregroundStyle(palette.secondaryInk)
                }
                .font(.system(size: 14))
            }

            Spacer()

            Button {
                if model.isProtectionPaused {
                    model.resumeProtection()
                } else {
                    model.requestProtectionPause()
                }
            } label: {
                Label(
                    model.isProtectionPaused ? "Resume protection" : "Pause protection",
                    systemImage: model.isProtectionPaused ? "play.fill" : "pause.fill"
                )
            }
            .buttonStyle(ShellActionButtonStyle(isBordered: true))

            Rectangle()
                .fill(palette.border)
                .frame(width: 1, height: 34)

            Button {
                model.addApplicationsUsingOpenPanel()
            } label: {
                Label("Add app", systemImage: "plus")
            }
            .buttonStyle(ShellActionButtonStyle(isBordered: false))
        }
        .padding(.leading, 46)
        .padding(.trailing, 30)
        .padding(.top, 16)
        .frame(height: 110)
        .background(palette.background)
    }
}

struct ShellActionButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let isBordered: Bool

    func makeBody(configuration: Configuration) -> some View {
        let palette = LimiterPalette.resolve(colorScheme)
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .foregroundStyle(palette.ink)
            .padding(.horizontal, isBordered ? 16 : 10)
            .frame(minHeight: 44)
            .background(isBordered ? palette.surface.opacity(configuration.isPressed ? 0.9 : 0.42) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if isBordered {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(palette.border, lineWidth: 1)
                }
            }
            .opacity(configuration.isPressed ? 0.72 : 1)
            .animation(reduceMotion ? nil : LimiterMotion.quick, value: configuration.isPressed)
    }
}

struct TodayView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var intentionFocused: Bool
    @ScaledMetric(relativeTo: .largeTitle) private var intentionFontSize: CGFloat = 60

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                EditorialLabel("Current intention")

                TextField("What did you sit down to do?", text: Binding(
                    get: { model.preferences.currentIntention },
                    set: { model.preferences.currentIntention = $0 }
                ), axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: intentionFontSize, weight: .medium, design: .default))
                .foregroundStyle(palette.ink)
                .lineLimit(2...3)
                .focused($intentionFocused)
                .frame(maxWidth: 760, alignment: .leading)
                .padding(.top, 28)
                .padding(.bottom, 12)
                .accessibilityLabel("Current intention")
                .accessibilityHint("Edit the intention Limiter shows when a distraction appears")

                Text("This intention returns when a distraction appears.")
                    .font(.system(size: 15))
                    .foregroundStyle(palette.secondaryInk)
                    .padding(.top, 12)

                if !model.activeSessions.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        EditorialLabel("Active now")
                            .padding(.bottom, 8)
                        ForEach(model.activeSessions) { session in
                            ActiveSessionRow(session: session)
                        }
                    }
                    .padding(.top, 42)
                }

                OutcomeLedger()
                    .padding(.top, 44)

                RecentChoicesTimeline()
                    .padding(.top, 42)
            }
            .padding(.horizontal, 46)
            .padding(.top, 50)
            .padding(.bottom, 60)
            .frame(maxWidth: 1220, alignment: .leading)
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
}

private struct EditorialLabel: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title.uppercased())
            .font(.caption.weight(.bold))
            .tracking(1.45)
            .foregroundStyle(LimiterPalette.resolve(colorScheme).amber)
    }
}

struct EditorialPageHeader: View {
    @Environment(\.colorScheme) private var colorScheme
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(alignment: .leading, spacing: 0) {
            Text(eyebrow.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.45)
                .foregroundStyle(palette.amber)
            Text(title)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(palette.ink)
                .padding(.top, 18)
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(palette.secondaryInk)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 660, alignment: .leading)
                .padding(.top, 10)
        }
    }
}

private struct OutcomeLedger: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(spacing: 0) {
            Rectangle()
                .fill(palette.border)
                .frame(height: 1)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 30) {
                    LedgerMetric(title: "Returned to focus", value: "\(model.declinedTodayCount)")
                    ledgerDivider(palette)
                    LedgerMetric(title: "Intentional sessions", value: "\(model.intentionalTodayCount)")
                    ledgerDivider(palette)
                    LedgerMetric(title: "Allowed time", value: "\(model.allowedMinutesToday)m")
                    Spacer(minLength: 0)
                }
                .padding(.vertical, 27)

                VStack(alignment: .leading, spacing: 16) {
                    LedgerMetric(title: "Returned to focus", value: "\(model.declinedTodayCount)")
                    LedgerMetric(title: "Intentional sessions", value: "\(model.intentionalTodayCount)")
                    LedgerMetric(title: "Allowed time", value: "\(model.allowedMinutesToday)m")
                }
                .padding(.vertical, 22)
            }
            Rectangle()
                .fill(palette.border)
                .frame(height: 1)
        }
    }

    private func ledgerDivider(_ palette: LimiterPalette) -> some View {
        Rectangle()
            .fill(palette.border)
            .frame(width: 1, height: 28)
    }
}

private struct LedgerMetric: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let value: String

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text(title)
                .foregroundStyle(palette.secondaryInk)
            Text(value)
                .fontWeight(.semibold)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(palette.ink)
        }
        .font(.system(size: 15))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
    }
}

private struct RecentChoicesTimeline: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(alignment: .leading, spacing: 25) {
            EditorialLabel("Recent choices")

            if model.reflections.isEmpty {
                HStack(alignment: .top, spacing: 25) {
                    TimelineRail(tint: palette.secondaryInk.opacity(0.55), extends: true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nothing to review yet")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(palette.ink)
                        Text("Your next choice will appear here, privately.")
                            .font(.body)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .padding(.top, 3)
                }
                .frame(minHeight: 150, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(model.reflections.prefix(4).enumerated()), id: \.element.id) { index, record in
                        TimelineReflectionRow(record: record, extends: index < min(model.reflections.count, 4) - 1)
                    }
                }
            }
        }
    }
}

private struct TimelineRail: View {
    let tint: Color
    let extends: Bool

    var body: some View {
        VStack(spacing: 0) {
            Circle()
                .stroke(tint, lineWidth: 1.25)
                .frame(width: 18, height: 18)
            if extends {
                Rectangle()
                    .fill(tint.opacity(0.7))
                    .frame(width: 1)
            }
        }
        .frame(width: 18)
        .accessibilityHidden(true)
    }
}

private struct TimelineReflectionRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let record: ReflectionRecord
    let extends: Bool

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        let tint = record.decision == .returnedToFocus ? palette.success : palette.amber
        HStack(alignment: .top, spacing: 25) {
            TimelineRail(tint: tint, extends: extends)
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
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
                    .foregroundStyle(tint)
                Text(record.reason.title)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryInk)
                if !record.intendedTask.isEmpty {
                    Text(record.intendedTask)
                        .font(.subheadline)
                        .foregroundStyle(palette.ink)
                }
            }
            .padding(.bottom, extends ? 28 : 0)
        }
        .accessibilityElement(children: .combine)
    }
}

struct ActiveSessionRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    let session: SessionRecord

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        let remaining = max(0, Int(session.grantExpiresAt.timeIntervalSince(model.now)))
        HStack(spacing: 14) {
            AppIconView(
                path: model.protectedApplications.first(where: { $0.bundleIdentifier == session.bundleIdentifier })?.applicationPath,
                size: 38
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(session.applicationName)
                    .font(.headline)
                Text("Ends at \(session.grantExpiresAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }
            Spacer()
            Text(Self.format(seconds: remaining))
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(palette.amber)
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.border).frame(height: 1)
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
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 28) {
                    EditorialPageHeader(
                        eyebrow: "Rules",
                        title: "Protected apps",
                        subtitle: "Each selected app gets the same deliberate pause, with its own sensible default."
                    )
                    Spacer()
                    Button("Browse installed apps", systemImage: "square.grid.2x2") {
                        sheet = .picker
                    }
                    .buttonStyle(ShellActionButtonStyle(isBordered: true))
                }

                if model.protectedApplications.isEmpty {
                    HStack(alignment: .top, spacing: 25) {
                        TimelineRail(tint: palette.secondaryInk.opacity(0.55), extends: true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No apps protected yet")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(palette.ink)
                            Text("Add a game or distracting app to begin. Limiter excludes system-critical processes.")
                                .foregroundStyle(palette.secondaryInk)
                        }
                        .padding(.top, 3)
                    }
                    .frame(minHeight: 170, alignment: .topLeading)
                    .padding(.top, 54)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.protectedApplications) { application in
                            protectedAppRow(application, palette: palette)
                        }
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.horizontal, 46)
            .padding(.top, 50)
            .padding(.bottom, 60)
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

    private func protectedAppRow(_ application: ProtectedApplication, palette: LimiterPalette) -> some View {
        HStack(spacing: 18) {
            AppIconView(path: application.applicationPath, size: 48)
            VStack(alignment: .leading, spacing: 5) {
                Text(application.name)
                    .font(.title3.weight(.semibold))
                Text(application.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(palette.secondaryInk)
            }
            Spacer(minLength: 28)
            VStack(alignment: .trailing, spacing: 3) {
                Text("DEFAULT SESSION")
                    .font(.caption2.weight(.bold))
                    .tracking(1.0)
                    .foregroundStyle(palette.secondaryInk)
                Menu {
                    ForEach([5, 10, 15, 30], id: \.self) { minute in
                        Button("\(minute) minutes") {
                            model.updateRule(application, minutes: minute)
                        }
                    }
                } label: {
                    Text("\(application.defaultSessionMinutes) min")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(palette.ink)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .accessibilityLabel("Default duration for \(application.name)")
                .accessibilityValue("\(application.defaultSessionMinutes) minutes")
            }
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
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(palette.danger)
            .help("Remove \(application.name) from Limiter")
            .accessibilityLabel("Remove \(application.name)")
        }
        .padding(.vertical, 22)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.border).frame(height: 1)
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
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 28) {
                    EditorialPageHeader(
                        eyebrow: "Local journal",
                        title: "Choices, not judgment.",
                        subtitle: "Your reasons and outcomes stay on this Mac. Use them to notice patterns, not to score yourself."
                    )
                    Spacer()
                    Button("Export CSV", systemImage: "square.and.arrow.up") { model.exportJournal() }
                        .buttonStyle(ShellActionButtonStyle(isBordered: true))
                        .disabled(model.reflections.isEmpty)
                    Button("Clear", systemImage: "trash", role: .destructive) { confirmClear = true }
                        .buttonStyle(ShellActionButtonStyle(isBordered: false))
                        .disabled(model.reflections.isEmpty)
                }

                if model.reflections.isEmpty {
                    HStack(alignment: .top, spacing: 25) {
                        TimelineRail(tint: palette.secondaryInk.opacity(0.55), extends: true)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("No reflections yet")
                                .font(.title3.weight(.medium))
                                .foregroundStyle(palette.ink)
                            Text("Once Limiter catches a protected app, your deliberate choice will appear here.")
                                .foregroundStyle(palette.secondaryInk)
                        }
                        .padding(.top, 3)
                    }
                    .frame(minHeight: 170, alignment: .topLeading)
                    .padding(.top, 54)
                } else {
                    VStack(spacing: 0) {
                        ForEach(model.reflections) { record in
                            ReflectionRow(record: record)
                        }
                    }
                    .padding(.top, 50)
                }
            }
            .padding(.horizontal, 46)
            .padding(.top, 50)
            .padding(.bottom, 60)
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
        HStack(alignment: .top, spacing: 18) {
            Circle()
                .fill(record.decision == .returnedToFocus ? palette.success : palette.amber)
                .frame(width: 9, height: 9)
                .padding(.top, 7)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(record.applicationName)
                        .font(.headline)
                    Spacer()
                    Text(record.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .foregroundStyle(palette.secondaryInk)
                        .font(.caption)
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
        .padding(.vertical, 20)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
    }
}
