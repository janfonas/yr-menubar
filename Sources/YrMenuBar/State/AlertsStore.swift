import Foundation
import Combine
import CoreLocation
import os

/// Owns the MetAlerts feed for the active location.
///
/// Kept separate from `WeatherStore` so the alerts polling cadence (which the
/// API specifically asks us to keep low) is independent from the forecast
/// refresh loop, and so views that only care about alerts can subscribe just
/// to this object.
@MainActor
final class AlertsStore: ObservableObject {
    @Published private(set) var alerts: [WeatherAlert] = []
    @Published private(set) var fetchedAt: Date?
    @Published private(set) var lastError: String?

    private weak var settings: AppSettings?
    private weak var location: LocationProvider?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var inFlight: Task<Void, Never>?
    private var lastKey: String?
    private let log = Logger(subsystem: "com.janfonas.YrMenuBar", category: "AlertsStore")

    func configure(settings: AppSettings, location: LocationProvider) {
        self.settings = settings
        self.location = location

        location.$currentLocation
            .compactMap { $0 }
            .removeDuplicates(by: { $0.distance(from: $1) < 500 })
            .sink { [weak self] _ in self?.refresh(force: false) }
            .store(in: &cancellables)

        startTimer()
    }

    /// Worst-severity alert, useful for menu-bar tinting / icon overlay.
    var worstSeverityRank: Int { alerts.map(\.severityRank).max() ?? 0 }

    /// Sorted by severity (worst first), then by headline.
    var sorted: [WeatherAlert] {
        alerts.sorted { lhs, rhs in
            if lhs.severityRank != rhs.severityRank { return lhs.severityRank > rhs.severityRank }
            return lhs.headline < rhs.headline
        }
    }

    private func currentCoordinate() -> (Double, Double)? {
        guard let settings = settings else { return nil }
        if settings.useGeoLocation, let loc = location?.currentLocation {
            return (loc.coordinate.latitude, loc.coordinate.longitude)
        }
        return (settings.fallbackLatitude, settings.fallbackLongitude)
    }

    func refresh(force: Bool = false) {
        guard let coord = currentCoordinate() else { return }
        let key = String(format: "%.3f,%.3f", coord.0, coord.1)
        if !force,
           let fetchedAt = fetchedAt,
           Date().timeIntervalSince(fetchedAt) < Constants.alertsRefreshInterval,
           lastKey == key {
            return
        }
        if let inFlight = inFlight, !inFlight.isCancelled {
            if !force { return }
            inFlight.cancel()
        }
        inFlight = Task { [weak self] in
            await self?.fetch(lat: coord.0, lon: coord.1, key: key)
            self?.inFlight = nil
        }
    }

    private func fetch(lat: Double, lon: Double, key: String) async {
        let lang = AppLanguage.resolved == .nb ? "no" : "en"
        do {
            let result = try await MetNoClient.shared.fetchAlerts(
                lat: lat, lon: lon, languageCode: lang)
            self.alerts = result
            self.fetchedAt = Date()
            self.lastError = nil
            self.lastKey = key
            log.debug("alerts: fetched \(result.count) for \(key)")
        } catch is CancellationError {
            // superseded — quiet
        } catch let MetNoError.httpStatus(code) {
            // Don't surface MetAlerts errors to the user — the forecast is
            // still the primary signal. Log and keep stale data.
            log.notice("alerts HTTP \(code)")
        } catch {
            log.debug("alerts fetch failed: \(error.localizedDescription)")
        }
    }

    private func startTimer() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Constants.alertsRefreshInterval * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run { self?.refresh(force: false) }
            }
        }
    }
}
