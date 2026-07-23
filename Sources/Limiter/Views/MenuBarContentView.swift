import AppKit
import SwiftUI

struct MenuBarContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                model.protectionStatusText,
                systemImage: model.isProtectionPaused ? "pause.circle.fill" : "checkmark.shield.fill"
            )
            .font(.headline)

            if !model.activeSessions.isEmpty {
                Divider()
                Text("Active sessions")
                    .font(.caption.weight(.semibold))
                ForEach(model.activeSessions) { session in
                    let remaining = max(0, Int(session.grantExpiresAt.timeIntervalSince(model.now)))
                    HStack {
                        Text(session.applicationName)
                        Spacer()
                        Text(ActiveSessionRow.format(seconds: remaining))
                            .monospacedDigit()
                    }
                }
            }

            Divider()
            Button("Open Limiter") {
                openWindow(id: "main")
                NSApplication.shared.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("l")

            if model.isProtectionPaused {
                Button("Resume protection") { model.resumeProtection() }
            } else {
                Button("Pause protection…") { model.requestProtectionPause() }
            }

            SettingsLink { Text("Settings…") }
            Divider()
            Button("Quit Limiter…") { model.requestProtectionPause(wantsQuit: true) }
                .keyboardShortcut("q")
        }
        .padding(6)
        .frame(minWidth: 260)
    }
}
