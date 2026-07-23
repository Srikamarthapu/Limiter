import AppKit
import Foundation

@MainActor
final class WorkspaceApplicationMonitor: NSObject, ApplicationMonitoring {
    var onEvent: ((ApplicationEvent) -> Void)?

    private let workspace: NSWorkspace
    private var isStarted = false

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
        super.init()
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        let center = workspace.notificationCenter
        center.addObserver(self, selector: #selector(didLaunch(_:)), name: NSWorkspace.didLaunchApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(didActivate(_:)), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(didTerminate(_:)), name: NSWorkspace.didTerminateApplicationNotification, object: nil)
        center.addObserver(self, selector: #selector(didWake(_:)), name: NSWorkspace.didWakeNotification, object: nil)

        if let frontmost = workspace.frontmostApplication {
            onEvent?(ApplicationEvent(kind: .activated, application: frontmost))
        }
    }

    func stop() {
        guard isStarted else { return }
        workspace.notificationCenter.removeObserver(self)
        isStarted = false
    }

    @objc private func didLaunch(_ notification: Notification) {
        emit(notification, kind: .launched)
    }

    @objc private func didActivate(_ notification: Notification) {
        emit(notification, kind: .activated)
    }

    @objc private func didTerminate(_ notification: Notification) {
        emit(notification, kind: .terminated)
    }

    @objc private func didWake(_ notification: Notification) {
        guard let frontmost = workspace.frontmostApplication else { return }
        onEvent?(ApplicationEvent(kind: .activated, application: frontmost))
    }

    private func emit(_ notification: Notification, kind: ApplicationEventKind) {
        guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        onEvent?(ApplicationEvent(kind: kind, application: application))
    }
}
