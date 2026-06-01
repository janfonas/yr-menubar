import SwiftUI

@main
struct YrMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The entire UI — status item, popover panel, Settings and About
        // windows — is owned by `AppDelegate` / `StatusItemController` (AppKit).
        // SwiftUI's `App` only needs a scene to exist; this empty `Settings`
        // scene is never surfaced (the app is `LSUIElement`, so there is no
        // menu bar to invoke it).
        Settings { EmptyView() }
    }
}
