import Foundation
import SwiftUI
import ServiceManagement
import os

enum UnitSystem: String, CaseIterable, Identifiable {
    case metric, imperial
    var id: String { rawValue }
    var label: String { self == .metric ? "Metric (°C, m/s, mm)" : "Imperial (°F, mph, in)" }
}

final class AppSettings: ObservableObject {
    private let log = Logger(subsystem: "com.janfonas.YrMenuBar", category: "AppSettings")

    @AppStorage("unitSystem") var unitSystemRaw: String = UnitSystem.metric.rawValue
    @AppStorage("useGeoLocation") var useGeoLocation: Bool = true
    @AppStorage("fallbackLatitude") var fallbackLatitude: Double = 59.9139    // Oslo
    @AppStorage("fallbackLongitude") var fallbackLongitude: Double = 10.7522
    @AppStorage("fallbackName") var fallbackName: String = "Oslo"
    @AppStorage("launchAtLogin") var launchAtLoginStored: Bool = false

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: unitSystemRaw) ?? .metric }
        set { unitSystemRaw = newValue.rawValue }
    }

    var launchAtLogin: Bool {
        get { launchAtLoginStored }
        set {
            launchAtLoginStored = newValue
            applyLaunchAtLogin(newValue)
        }
    }

    func applyLaunchAtLogin(_ enabled: Bool) {
        let service = SMAppService.mainApp
        do {
            if enabled {
                if service.status != .enabled { try service.register() }
            } else {
                if service.status == .enabled { try service.unregister() }
            }
        } catch {
            log.error("Launch at login toggle failed: \(error.localizedDescription)")
        }
    }
}
