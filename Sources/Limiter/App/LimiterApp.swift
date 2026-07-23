import SwiftData
import SwiftUI

@main
struct LimiterApp: App {
    private let container: ModelContainer
    @State private var model: AppModel

    init() {
        do {
            let schema = Schema([
                ProtectedApplication.self,
                ReflectionRecord.self,
                SessionRecord.self
            ])
            let applicationSupport = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let limiterDirectory = applicationSupport.appendingPathComponent("Limiter", isDirectory: true)
            try FileManager.default.createDirectory(
                at: limiterDirectory,
                withIntermediateDirectories: true
            )
            let configuration = ModelConfiguration(
                "Limiter",
                schema: schema,
                url: limiterDirectory.appendingPathComponent("Limiter.store")
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            self.container = container
            _model = State(initialValue: AppModel(container: container))
        } catch {
            fatalError("Limiter could not create its local data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup("Limiter", id: "main") {
            AppRootView()
                .environment(model)
                .modelContainer(container)
                .preferredColorScheme(model.preferences.appearance.colorScheme)
                .task { model.start() }
                .frame(minWidth: 880, minHeight: 620)
        }
        .defaultSize(width: 1040, height: 720)
        .commands {
            CommandGroup(replacing: .appTermination) {
                Button("Quit Limiter…") {
                    model.requestProtectionPause(wantsQuit: true)
                }
                .keyboardShortcut("q")
            }
        }

        MenuBarExtra {
            MenuBarContentView()
                .environment(model)
        } label: {
            Label("Limiter", systemImage: model.isProtectionPaused ? "pause.circle.fill" : "shield.checkered")
        }

        Settings {
            SettingsContentView(isStandalone: true)
                .environment(model)
                .preferredColorScheme(model.preferences.appearance.colorScheme)
                .frame(width: 520, height: 520)
        }
    }
}

struct AppRootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            AppBackground()
            if model.preferences.onboardingCompleted {
                MainDashboardView()
            } else {
                OnboardingView()
            }
        }
        .alert("Limiter needs attention", isPresented: Binding(
            get: { model.errorMessage != nil },
            set: { if !$0 { model.errorMessage = nil } }
        )) {
            Button("OK") { model.errorMessage = nil }
        } message: {
            Text(model.errorMessage ?? "Unknown error")
        }
    }
}
