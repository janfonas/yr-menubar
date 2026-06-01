import Foundation
import CoreLocation
import Combine
import AppKit

final class LocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastError: String?

    private let manager = CLLocationManager()
    private var isUpdating = false
    /// True while we have temporarily switched the app to `.regular` activation
    /// policy so the system location prompt can appear. An `LSUIElement`
    /// (accessory) app cannot present the CoreLocation authorization dialog;
    /// locationd silently drops the request. We revert once the user responds.
    private var didPromoteForPrompt = false

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorized
    }

    /// Human-readable snapshot of the current location state for diagnostics.
    var diagnosticsSummary: String {
        let coord = currentLocation.map { String(format: "%.4f, %.4f", $0.coordinate.latitude, $0.coordinate.longitude) } ?? "none"
        return """
        authStatus: \(authorizationStatus.diagName)
        isAuthorized: \(isAuthorized)
        locationServicesEnabled: \(CLLocationManager.locationServicesEnabled())
        isUpdating: \(isUpdating)
        currentLocation: \(coord)
        lastError: \(lastError ?? "none")
        """
    }

    override init() {
        super.init()
        manager.delegate = self
        // Coarse accuracy is plenty for city-level weather and is far more
        // power-friendly than precise GPS.
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 1000
        authorizationStatus = manager.authorizationStatus
        Diag.location.info("init authStatus=\(self.authorizationStatus.diagName, privacy: .public) servicesEnabled=\(CLLocationManager.locationServicesEnabled(), privacy: .public)")
    }

    /// Begin delivering updates *only* if we are already authorized. Never
    /// shows a prompt, so it is safe to call at launch while the app is a
    /// background accessory. (A `requestWhenInUseAuthorization()` issued while
    /// the app is not frontmost is silently suppressed by macOS and then
    /// blocks later prompts — which is exactly what broke the access button.)
    func startIfAuthorized() {
        Diag.location.info("startIfAuthorized authStatus=\(self.authorizationStatus.diagName, privacy: .public) isAuthorized=\(self.isAuthorized, privacy: .public)")
        if isAuthorized { startUpdating() }
    }

    /// Request authorization if undetermined, otherwise start updates. MUST be
    /// invoked from a context where the app can present UI: the macOS location
    /// prompt only appears when the requesting app is active, so we activate
    /// first.
    func requestAuthorization() {
        Diag.location.info("requestAuthorization called authStatus=\(self.authorizationStatus.diagName, privacy: .public) appActive=\(NSApp.isActive, privacy: .public) policy=\(String(describing: NSApp.activationPolicy()), privacy: .public)")
        switch authorizationStatus {
        case .notDetermined:
            // An accessory (LSUIElement) app cannot present the location prompt.
            // Temporarily become a regular foreground app so the dialog shows;
            // we revert to accessory once the user responds (in didChange).
            if NSApp.activationPolicy() != .regular {
                NSApp.setActivationPolicy(.regular)
                didPromoteForPrompt = true
            }
            NSApp.activate(ignoringOtherApps: true)
            Diag.location.info("calling requestWhenInUseAuthorization() (notDetermined) promoted=\(self.didPromoteForPrompt, privacy: .public) appActive=\(NSApp.isActive, privacy: .public) policy=\(String(describing: NSApp.activationPolicy()), privacy: .public)")
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorized:
            Diag.location.info("already authorized -> startUpdating()")
            startUpdating()
        default:
            Diag.location.info("authorization denied/restricted -> no prompt possible")
            break
        }
    }

    func stopUpdating() {
        guard isUpdating else { return }
        manager.stopUpdatingLocation()
        isUpdating = false
        Diag.location.info("stopUpdating")
    }

    private func startUpdating() {
        guard !isUpdating else { return }
        isUpdating = true
        Diag.location.info("startUpdating -> startUpdatingLocation()")
        manager.startUpdatingLocation()
    }

    // MARK: CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Diag.location.info("didChangeAuthorization -> \(status.diagName, privacy: .public)")
        DispatchQueue.main.async {
            self.authorizationStatus = status
            // Once the user has answered the prompt, drop back to an accessory
            // app so we keep no Dock icon / app menu.
            if status != .notDetermined, self.didPromoteForPrompt {
                self.didPromoteForPrompt = false
                NSApp.setActivationPolicy(.accessory)
                Diag.location.info("reverted activation policy to accessory")
            }
            switch status {
            case .authorizedAlways, .authorized:
                self.startUpdating()
            case .denied, .restricted:
                self.stopUpdating()
            default:
                break
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Diag.location.info("didUpdateLocations \(loc.coordinate.latitude, privacy: .public),\(loc.coordinate.longitude, privacy: .public)")
        DispatchQueue.main.async {
            self.currentLocation = loc
            self.lastError = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // A transient "location unknown" is expected while CoreLocation warms
        // up; keep updates running so a later fix can still arrive. Only record
        // the message for diagnostics.
        Diag.location.error("didFailWithError \(error.localizedDescription, privacy: .public)")
        DispatchQueue.main.async {
            self.lastError = error.localizedDescription
        }
    }
}

extension CLAuthorizationStatus {
    var diagName: String {
        switch self {
        case .notDetermined: return "notDetermined"
        case .restricted: return "restricted"
        case .denied: return "denied"
        case .authorizedAlways: return "authorizedAlways"
        case .authorized: return "authorized"
        @unknown default: return "unknown(\(rawValue))"
        }
    }
}
