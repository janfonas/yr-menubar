import Foundation

/// Single shared instance of the app's observable stores.
///
/// In the custom `NSStatusItem`/`NSPanel` architecture the status item is
/// owned by `AppDelegate` (AppKit) while the `Settings` scene lives in
/// SwiftUI. Both sides need the *same* store instances, so we keep them here
/// rather than as `@StateObject`s scoped to a single scene.
@MainActor
final class AppContainer {
    static let shared = AppContainer()

    let settings = AppSettings()
    let location = LocationProvider()
    let store = WeatherStore()
    let alerts = AlertsStore()

    private init() {}

    /// Wires stores together and kicks off the first fetch. Safe to call once
    /// at launch.
    func bootstrap() {
        store.configure(settings: settings, location: location)
        alerts.configure(settings: settings, location: location)
        store.refreshIfNeeded()
        alerts.refresh()
    }
}
