import SwiftUI

struct OverlayRootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            AppBackground()
            if let request = model.activeIntervention {
                InterventionView(request: request)
            } else if let request = model.pauseRequest {
                PauseProtectionView(request: request)
            } else if let notice = model.sessionNotice {
                SessionNoticeView(notice: notice)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct InterventionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Bindable var request: InterventionRequest

    private var palette: LimiterPalette { .resolve(colorScheme) }
    private var remaining: Int { request.pauseSecondsRemaining(at: model.now) }
    private let commonDurations = [5, 10, 15, 30]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("Limiter", systemImage: "shield.checkered")
                    .font(.headline)
                    .foregroundStyle(palette.pine)
                Spacer()
                stageIndicator
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)

            Group {
                switch request.stage {
                case .pause: pauseStage
                case .duration: durationStage
                case .confirm: confirmStage
                }
            }
            .id(request.stage)
            .transition(reduceMotion ? .opacity : .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(reduceMotion ? nil : LimiterMotion.standard, value: request.stage)
        }
        .foregroundStyle(palette.ink)
        .padding(.bottom, 24)
    }

    private var stageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(InterventionStage.allCases, id: \.rawValue) { stage in
                Capsule()
                    .fill(stage.rawValue <= request.stage.rawValue ? palette.amber : palette.border)
                    .frame(width: stage == request.stage ? 24 : 8, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(request.stage.rawValue + 1) of 3")
    }

    private var appHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(palette.border, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: CGFloat(10 - remaining) / 10)
                    .stroke(palette.amber, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(reduceMotion ? nil : .linear(duration: 1), value: remaining)
                AppIconView(
                    path: request.applicationURL?.path,
                    size: 68,
                    fallbackSystemImage: request.isDemo ? "gamecontroller.fill" : "app.fill"
                )
            }
            .frame(width: 100, height: 100)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(request.applicationName) app, \(remaining) seconds remain in the pause")

            Text("Pause — you’re opening \(request.applicationName)")
                .font(.system(size: 27, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            Text(remaining > 0 ? "Give the impulse a moment. You can return to focus immediately." : "The pause is complete. Choose what matches your intention.")
                .font(.body)
                .foregroundStyle(palette.secondaryInk)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 470)
        }
    }

    private var pauseStage: some View {
        ScrollView {
            VStack(spacing: 22) {
                appHeader

                VStack(alignment: .leading, spacing: 10) {
                    Text("What brought you here?")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(ReflectionReason.allCases) { reason in
                            Button {
                                request.reason = reason
                            } label: {
                                HStack(spacing: 9) {
                                    Image(systemName: reason.systemImage)
                                    Text(reason.title)
                                    Spacer(minLength: 0)
                                    if request.reason == reason {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(palette.success)
                                    }
                                }
                                .padding(.horizontal, 13)
                                .frame(maxWidth: .infinity, minHeight: 46)
                                .background(request.reason == reason ? palette.pine.opacity(0.12) : palette.elevatedSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(request.reason == reason ? palette.pine : palette.border, lineWidth: 1)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(request.reason == reason ? .isSelected : [])
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("What were you planning to do?")
                        .font(.headline)
                    TextField("Finish the task I sat down for", text: $request.intendedTask)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityHint("This stays on your Mac and will be shown in the final choice.")
                    TextField("Optional note about why you opened this app", text: $request.note)
                        .textFieldStyle(.roundedBorder)
                }

                actionRow(
                    nextTitle: remaining > 0 ? "Continue in \(remaining)s" : "Choose a time limit",
                    nextDisabled: remaining > 0
                )
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
        }
    }

    private var durationStage: some View {
        VStack(spacing: 28) {
            VStack(spacing: 12) {
                AppIconView(path: request.applicationURL?.path, size: 74, fallbackSystemImage: request.isDemo ? "gamecontroller.fill" : "app.fill")
                Text("How long is enough?")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("Choose the session before the session chooses for you.")
                    .foregroundStyle(palette.secondaryInk)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Intentional session")
                    .font(.headline)
                HStack(spacing: 10) {
                    ForEach(commonDurations, id: \.self) { minutes in
                        durationButton(title: "\(minutes) min", value: minutes)
                    }
                    durationButton(title: "Custom", value: -1)
                }
                if request.selectedMinutes == -1 {
                    HStack {
                        Stepper("\(request.customMinutes) minutes", value: $request.customMinutes, in: 1...60)
                        Spacer()
                        Text("1–60 min")
                            .font(.caption)
                            .foregroundStyle(palette.secondaryInk)
                    }
                    .padding(14)
                    .background(palette.elevatedSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            SurfaceCard {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(palette.amber)
                    Text("Limiter will warn you before time ends, ask the app to close normally, and never force-quit it.")
                        .font(.subheadline)
                        .foregroundStyle(palette.secondaryInk)
                }
            }

            Spacer()
            actionRow(nextTitle: "Review my choice", nextDisabled: false)
        }
        .padding(28)
    }

    private var confirmStage: some View {
        VStack(spacing: 26) {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.seal")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(palette.amber)
                    .accessibilityHidden(true)
                Text("Make it deliberate")
                    .font(.system(size: 29, weight: .bold, design: .rounded))
                Text("Read the choice once before crossing the threshold.")
                    .foregroundStyle(palette.secondaryInk)
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 18) {
                    summaryRow(icon: "app.fill", title: "Open", value: request.applicationName)
                    Divider()
                    summaryRow(icon: "timer", title: "For", value: "\(effectiveMinutes) minutes")
                    Divider()
                    summaryRow(
                        icon: "arrow.uturn.backward",
                        title: "Then return to",
                        value: request.intendedTask.isEmpty ? "what matters next" : request.intendedTask
                    )
                }
            }

            Button {
                model.allowIntentionalSession()
            } label: {
                Label("Open for \(effectiveMinutes) minutes", systemImage: "door.left.hand.open")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AmberButtonStyle())
            .keyboardShortcut(.return, modifiers: [.command, .shift])

            Button {
                model.returnToFocus()
            } label: {
                Label("Return to focus instead", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)

            Button("Back") { model.goBackInIntervention() }
                .buttonStyle(.plain)
                .foregroundStyle(palette.secondaryInk)
        }
        .padding(28)
    }

    private var effectiveMinutes: Int {
        request.selectedMinutes == -1 ? request.customMinutes : request.selectedMinutes
    }

    private func durationButton(title: String, value: Int) -> some View {
        Button(title) { request.selectedMinutes = value }
            .buttonStyle(.plain)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(request.selectedMinutes == value ? palette.pine : palette.elevatedSurface)
            .foregroundStyle(request.selectedMinutes == value ? Color.white : palette.ink)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(request.selectedMinutes == value ? palette.pine : palette.border, lineWidth: 1)
            }
            .accessibilityAddTraits(request.selectedMinutes == value ? .isSelected : [])
    }

    private func actionRow(nextTitle: String, nextDisabled: Bool) -> some View {
        HStack(spacing: 12) {
            Button {
                model.returnToFocus()
            } label: {
                Label("Return to focus", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .keyboardShortcut(.defaultAction)

            Button {
                model.advanceIntervention()
            } label: {
                Label(nextTitle, systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(nextDisabled)
        }
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(palette.pine)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryInk)
                Text(value)
                    .font(.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }
}

struct PauseProtectionView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var request: PauseRequest

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(spacing: 22) {
            Image(systemName: request.wantsQuit ? "power" : "pause.circle")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(palette.amber)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(request.wantsQuit ? "Pause before quitting" : "Pause protection deliberately")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("Limiter stays under your control. This short pause keeps disabling it intentional too.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.secondaryInk)
            }

            TextField("Why are you pausing protection?", text: $request.reason)
                .textFieldStyle(.roundedBorder)

            Picker("Pause for", selection: $request.duration) {
                ForEach(PauseDuration.allCases) { duration in
                    Text(duration.title).tag(duration)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 12) {
                Button("Keep protection on") { model.cancelProtectionPause() }
                    .buttonStyle(PrimaryButtonStyle())
                    .frame(maxWidth: .infinity)
                Button(pauseButtonTitle(request: request, now: model.now)) {
                    model.confirmProtectionPause()
                }
                .buttonStyle(SecondaryButtonStyle())
                .frame(maxWidth: .infinity)
                .disabled(request.secondsRemaining(at: model.now) > 0 || request.reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(28)
        .foregroundStyle(palette.ink)
    }

    private func pauseButtonTitle(request: PauseRequest, now: Date) -> String {
        let seconds = request.secondsRemaining(at: now)
        if seconds > 0 { return "Available in \(seconds)s" }
        return request.wantsQuit ? "Pause and quit" : "Pause protection"
    }
}

struct SessionNoticeView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.colorScheme) private var colorScheme
    let notice: SessionNotice

    var body: some View {
        let palette = LimiterPalette.resolve(colorScheme)
        VStack(spacing: 16) {
            Image(systemName: notice.kind == .warning ? "timer" : "checkmark.circle")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(notice.kind == .warning ? palette.amber : palette.success)
            Text(notice.kind == .warning ? "Time check: \(notice.applicationName)" : "Session complete")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text(notice.message)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.secondaryInk)
            Button("Got it") { model.dismissSessionNotice() }
                .buttonStyle(PrimaryButtonStyle())
                .keyboardShortcut(.defaultAction)
        }
        .padding(26)
        .foregroundStyle(palette.ink)
    }
}
