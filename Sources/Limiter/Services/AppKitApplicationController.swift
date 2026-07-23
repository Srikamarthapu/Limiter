import AppKit
import Foundation

@MainActor
final class AppKitApplicationController: ApplicationControlling {
    private let workspace: NSWorkspace

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    func contain(_ event: ApplicationEvent) {
        guard event.kind != .terminated else { return }
        _ = event.application.hide()
        if event.kind == .launched {
            _ = event.application.terminate()
        }
    }

    func reveal(_ request: InterventionRequest) {
        if let running = request.event?.application, !running.isTerminated {
            _ = running.unhide()
            _ = running.activate(options: [.activateAllWindows])
            return
        }

        let resolvedURL = request.applicationURL
            ?? NSWorkspace.shared.urlForApplication(withBundleIdentifier: request.bundleIdentifier)

        guard let url = resolvedURL else { return }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        workspace.openApplication(at: url, configuration: configuration) { _, _ in }
    }

    func terminateNormally(bundleIdentifier: String) {
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            _ = application.terminate()
        }
    }

    func hide(bundleIdentifier: String) {
        for application in NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier) {
            _ = application.hide()
        }
    }
}
