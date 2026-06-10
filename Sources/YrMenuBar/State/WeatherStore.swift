import Foundation
import Combine
import CoreLocation
import os

@MainActor
final class WeatherStore: ObservableObject {
    @Published var forecast: LocationForecast?
    @Published var nowcast: Nowcast?
    @Published var fetchedAt: Date?
    @Published var locationName: String = "—"
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private weak var settings: AppSettings?
    private weak var location: LocationProvider?
    private var cancellables = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var inFlightFetch: Task<Void, Never>?
    private var nextRefreshAt: Date?
    private var lastModifiedHeader: String?
    private var lastFetchKey: String?
    private let log = Logger(subsystem: "com.janfonas.YrMenuBar", category: "WeatherStore")

    init() {
        if let cached = ForecastCache.load() {
            self.forecast = cached.forecast
            self.fetchedAt = cached.fetchedAt
            self.lastModifiedHeader = cached.lastModified
            self.nextRefreshAt = cached.expiresAt
        }
    }

    func configure(settings: AppSettings, location: LocationProvider) {
        self.settings = settings
        self.location = location

        location.$currentLocation
            .compactMap { $0 }
            .map { String(format: "%.3f,%.3f", $0.coordinate.latitude, $0.coordinate.longitude) }
            .removeDuplicates()
            .sink { [weak self] _ in
                // A new fix arrived: refresh the (reverse-geocoded) place name
                // *and* the forecast for the new coordinates.
                self?.updateLocationName()
                self?.refreshIfNeeded(force: false)
            }
            .store(in: &cancellables)

        if settings.useGeoLocation {
            // Only resume updates if already authorized. Do NOT prompt here:
            // this runs at launch while the app is a background accessory, and
            // a prompt issued then is suppressed by macOS and blocks later ones.
            location.startIfAuthorized()
        }
        startTimer()
        updateLocationName()
    }

    /// Schedule the next refresh based on the server-provided `Expires` header
    /// when available, otherwise fall back to the minimum interval. Capped at
    /// `Constants.maximumRefreshInterval` so we never go silent for too long.
    private func startTimer() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let delay = await MainActor.run { () -> TimeInterval in
                    guard let self = self else { return Constants.minimumRefreshInterval }
                    if let next = self.nextRefreshAt {
                        let interval = next.timeIntervalSinceNow
                        return min(max(interval, Constants.minimumRefreshInterval),
                                   Constants.maximumRefreshInterval)
                    }
                    return Constants.minimumRefreshInterval
                }
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                if Task.isCancelled { break }
                await MainActor.run { self?.refreshIfNeeded(force: false) }
            }
        }
    }

    var currentSymbolCode: String? {
        guard let entry = forecast?.properties.timeseries.first else { return nil }
        return entry.data.next1Hours?.summary?.symbolCode
            ?? entry.data.next6Hours?.summary?.symbolCode
            ?? entry.data.next12Hours?.summary?.symbolCode
    }

    var currentInstant: LocationForecast.InstantDetails? {
        forecast?.properties.timeseries.first?.data.instant.details
    }

    var nextHourPrecip: Double? {
        forecast?.properties.timeseries.first?.data.next1Hours?.details?.precipitationAmount
    }

    /// All forecast entries that fall on the given calendar day, sorted by time.
    /// met.no returns hourly resolution for ~48h so today/tomorrow get fine detail.
    func hourlyEntries(for day: Date = Date()) -> [LocationForecast.TimeSeriesEntry] {
        guard let forecast = forecast else { return [] }
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        return forecast.properties.timeseries
            .filter { cal.isDate($0.time, inSameDayAs: start) }
            .sorted { $0.time < $1.time }
    }

    func dailySummaries(days: Int = 7) -> [DailySummary] {
        guard let forecast = forecast else { return [] }
        let cal = Calendar.current
        var grouped: [Date: [LocationForecast.TimeSeriesEntry]] = [:]
        for entry in forecast.properties.timeseries {
            let day = cal.startOfDay(for: entry.time)
            grouped[day, default: []].append(entry)
        }
        let sortedDays = grouped.keys.sorted().prefix(days)
        return sortedDays.map { day in
            let entries = grouped[day] ?? []
            let temps = entries.compactMap { $0.data.instant.details.airTemperature }
            let minT = temps.min()
            let maxT = temps.max()
            let precip = entries.reduce(0.0) { acc, e in
                acc + (e.data.next6Hours?.details?.precipitationAmount
                    ?? e.data.next1Hours?.details?.precipitationAmount ?? 0)
            }
            // pick midday symbol if possible
            let midday = entries.min(by: { abs($0.time.timeIntervalSince(cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)!))
                < abs($1.time.timeIntervalSince(cal.date(bySettingHour: 12, minute: 0, second: 0, of: day)!)) })
            let symbol = midday?.data.next6Hours?.summary?.symbolCode
                ?? midday?.data.next12Hours?.summary?.symbolCode
                ?? midday?.data.next1Hours?.summary?.symbolCode
            let wind = entries.compactMap { $0.data.instant.details.windSpeed }.max()
            return DailySummary(id: day, minTemp: minT, maxTemp: maxT, precipitation: precip, symbolCode: symbol, windSpeed: wind)
        }
    }

    func currentCoordinate() -> (Double, Double, String)? {
        guard let settings = settings else { return nil }
        if settings.useGeoLocation, let loc = location?.currentLocation {
            return (loc.coordinate.latitude, loc.coordinate.longitude, locationName)
        }
        return (settings.fallbackLatitude, settings.fallbackLongitude, settings.fallbackName)
    }

    func refreshIfNeeded(force: Bool = false) {
        guard let coord = currentCoordinate() else { return }
        let key = String(format: "%.3f,%.3f", coord.0, coord.1)
        if !force,
           let fetchedAt = fetchedAt,
           Date().timeIntervalSince(fetchedAt) < Constants.minimumRefreshInterval,
           lastFetchKey == key {
            return
        }
        // Request coalescing: if a fetch is already running, drop this one
        // unless it's a forced refresh and the in-flight task is finishing.
        if let inFlight = inFlightFetch, !inFlight.isCancelled {
            if !force { return }
            inFlight.cancel()
        }
        inFlightFetch = Task { [weak self] in
            await self?.fetch(lat: coord.0, lon: coord.1, key: key)
            self?.inFlightFetch = nil
        }
    }

    private func fetch(lat: Double, lon: Double, key: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let (forecast, response) = try await MetNoClient.shared.fetch(
                lat: lat, lon: lon,
                ifModifiedSince: (key == lastFetchKey) ? lastModifiedHeader : nil)
            self.forecast = forecast
            self.fetchedAt = Date()
            self.errorMessage = nil
            self.lastFetchKey = key
            // Derive the display name from the single source of truth rather
            // than the (possibly stale) name captured when the fetch started.
            self.updateLocationName()
            if let lm = response.value(forHTTPHeaderField: "Last-Modified") {
                self.lastModifiedHeader = lm
            }
            let expires = response.value(forHTTPHeaderField: "Expires").flatMap(Self.parseHTTPDate)
            self.nextRefreshAt = expires
            ForecastCache.save(CachedForecast(
                forecast: forecast, lat: lat, lon: lon,
                fetchedAt: Date(),
                expiresAt: expires,
                lastModified: lastModifiedHeader))
            // Best-effort nowcast (Nordic radar coverage only).
            await fetchNowcast(lat: lat, lon: lon)
            // Reschedule the timer to honour the new `Expires` window.
            startTimer()
        } catch MetNoError.notModified {
            self.fetchedAt = Date()
            await fetchNowcast(lat: lat, lon: lon)
        } catch is CancellationError {
            // Superseded by another refresh; stay quiet.
        } catch {
            self.errorMessage = error.localizedDescription
            log.error("fetch failed: \(error.localizedDescription)")
        }
    }

    func updateLocationName() {
        guard let settings = settings else { return }
        if settings.useGeoLocation, let loc = location?.currentLocation {
            Task { [weak self] in
                let placemarks = try? await CLGeocoder().reverseGeocodeLocation(loc)
                guard let p = placemarks?.first else { return }
                let name = p.locality ?? p.name ?? p.administrativeArea ?? "Current location"
                self?.locationName = name
            }
        } else {
            self.locationName = settings.fallbackName
        }
    }

    private static func parseHTTPDate(_ s: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "GMT")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        return f.date(from: s)
    }

    private func fetchNowcast(lat: Double, lon: Double) async {
        do {
            self.nowcast = try await MetNoClient.shared.fetchNowcast(lat: lat, lon: lon)
        } catch is CancellationError {
            // ignored
        } catch let MetNoError.httpStatus(code) {
            // 4xx that aren't 422/404 are surfaced; 5xx are logged but kept quiet
            // because the forecast is the primary signal.
            log.notice("nowcast HTTP \(code)")
        } catch {
            log.debug("nowcast fetch failed (non-fatal): \(error.localizedDescription)")
        }
    }
}
