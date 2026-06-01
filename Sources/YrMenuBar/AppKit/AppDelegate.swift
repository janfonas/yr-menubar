import AppKit

/// AppKit entry point. Owns the status item / panel controller and boots the
/// shared stores. The SwiftUI `App` only keeps a `Settings` scene around.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let container = AppContainer.shared
        container.bootstrap()
        controller = StatusItemController(container: container)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }
}
