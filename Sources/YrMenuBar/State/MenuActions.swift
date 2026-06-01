import SwiftUI

/// Closures injected into `ContentView` so the SwiftUI popover content can
/// drive AppKit-owned actions (open Settings, open About, quit, dismiss the
/// panel) without depending on SwiftUI scene environment actions, which are
/// unavailable when the view is hosted in a manually-created `NSPanel`.
@MainActor
final class MenuActions: ObservableObject {
    var openSettings: () -> Void = {}
    var openAbout: () -> Void = {}
    var quit: () -> Void = { NSApp.terminate(nil) }
    var closePanel: () -> Void = {}
}
