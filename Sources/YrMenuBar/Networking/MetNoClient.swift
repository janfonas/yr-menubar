import Foundation
import os

struct CachedForecast: Codable {
    let forecast: LocationForecast
    let lat: Double
    let lon: Double
    let fetchedAt: Date
    let expiresAt: Date?
    let lastModified: String?
}

actor MetNoClient {
    static let shared = MetNoClient()

    private let session: URLSession
    private let log = Logger(subsystem: "com.janfonas.YrMenuBar", category: "MetNoClient")
    private let userAgent: String

    init(session: URLSession = .shared) {
        self.session = session
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        self.userAgent = "YrMenuBar/\(version) (https://github.com/janfonas/yr-menubar)"
    }

    func fetch(lat: Double, lon: Double, ifModifiedSince: String? = nil) async throws -> (LocationForecast, HTTPURLResponse) {
        let (rLat, rLon) = Self.roundedCoordinates(lat: lat, lon: lon)
        guard var components = URLComponents(string: "https://api.met.no/weatherapi/locationforecast/2.0/compact") else {
            throw MetNoError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.4f", rLat)),
            URLQueryItem(name: "lon", value: String(format: "%.4f", rLon))
        ]
        guard let url = components.url else { throw MetNoError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let ims = ifModifiedSince {
            request.setValue(ims, forHTTPHeaderField: "If-Modified-Since")
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MetNoError.invalidResponse
        }
        log.debug("met.no \(http.statusCode) for \(rLat),\(rLon)")
        if http.statusCode == 304 {
            throw MetNoError.notModified
        }
        guard (200..<300).contains(http.statusCode) else {
            throw MetNoError.httpStatus(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let forecast = try decoder.decode(LocationForecast.self, from: data)
        return (forecast, http)
    }

    /// Fetch the precipitation nowcast (next ~90 minutes, 5-min granularity).
    /// Returns `nil` when the location is outside Nordic radar coverage (HTTP 422).
    func fetchNowcast(lat: Double, lon: Double) async throws -> Nowcast? {
        let (rLat, rLon) = Self.roundedCoordinates(lat: lat, lon: lon)
        guard var components = URLComponents(string: "https://api.met.no/weatherapi/nowcast/2.0/complete") else {
            throw MetNoError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.4f", rLat)),
            URLQueryItem(name: "lon", value: String(format: "%.4f", rLon))
        ]
        guard let url = components.url else { throw MetNoError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MetNoError.invalidResponse }
        log.debug("met.no nowcast \(http.statusCode) for \(rLat),\(rLon)")
        // 422 = outside Nordic coverage; treat as "no data".
        if http.statusCode == 422 || http.statusCode == 404 { return nil }
        guard (200..<300).contains(http.statusCode) else {
            throw MetNoError.httpStatus(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(Nowcast.self, from: data)
    }

    /// Fetch active MetAlerts (weather warnings) covering the given coordinate.
    ///
    /// Uses the GeoJSON beta endpoint so we get all relevant fields in one
    /// request without having to chase per-CAP XML files. Returns an empty
    /// array when the API has no active warnings for the location.
    func fetchAlerts(lat: Double, lon: Double, languageCode: String, useExampleEndpoint: Bool = false) async throws -> [WeatherAlert] {
        let (rLat, rLon) = Self.roundedCoordinates(lat: lat, lon: lon)
        let path = useExampleEndpoint
            ? "https://api.met.no/weatherapi/metalerts/2.0/example.json"
            : "https://api.met.no/weatherapi/metalerts/2.0/current.json"
        guard var components = URLComponents(string: path) else {
            throw MetNoError.invalidResponse
        }
        // The MetAlerts API only accepts "no" or "en" for `lang`.
        let lang = (languageCode == "nb" || languageCode == "nn" || languageCode == "no") ? "no" : "en"
        var items = [URLQueryItem(name: "lang", value: lang)]
        // /example.json ignores lat/lon and returns the same demo set; only
        // pass coordinates for the real endpoint.
        if !useExampleEndpoint {
            items.append(URLQueryItem(name: "lat", value: String(format: "%.4f", rLat)))
            items.append(URLQueryItem(name: "lon", value: String(format: "%.4f", rLon)))
        }
        components.queryItems = items
        guard let url = components.url else { throw MetNoError.invalidResponse }
        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw MetNoError.invalidResponse }
        log.debug("met.no metalerts \(http.statusCode) for \(rLat),\(rLon)")
        // 204 (no content) shouldn't happen for GeoJSON, but be defensive.
        if http.statusCode == 204 { return [] }
        guard (200..<300).contains(http.statusCode) else {
            throw MetNoError.httpStatus(http.statusCode)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(MetAlertsResponse.self, from: data)
        return envelope.features.map { $0.properties }
    }

    /// Round to the decimals required by met.no (default 4) so cache keys match
    /// and the API doesn't reject overly precise queries.
    private static func roundedCoordinates(lat: Double, lon: Double) -> (Double, Double) {
        let factor = pow(10.0, Double(Constants.coordinateDecimals))
        return ((lat * factor).rounded() / factor,
                (lon * factor).rounded() / factor)
    }
}

enum MetNoError: LocalizedError {
    case invalidResponse
    case notModified
    case httpStatus(Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Invalid response from met.no"
        case .notModified: return "Forecast not modified"
        case .httpStatus(let s): return "met.no returned HTTP \(s)"
        }
    }
}

enum ForecastCache {
    static var cacheURL: URL {
        let base = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = (base ?? FileManager.default.temporaryDirectory)
            .appendingPathComponent("YrMenuBar", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("forecast.json")
    }

    static func load() -> CachedForecast? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CachedForecast.self, from: data)
    }

    static func save(_ cached: CachedForecast) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(cached) {
            try? data.write(to: cacheURL, options: .atomic)
        }
    }
}
