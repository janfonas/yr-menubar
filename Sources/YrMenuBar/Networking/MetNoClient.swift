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
        // round to 4 decimals per met.no recommendation
        let rLat = (lat * 10000).rounded() / 10000
        let rLon = (lon * 10000).rounded() / 10000
        var components = URLComponents(string: "https://api.met.no/weatherapi/locationforecast/2.0/compact")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(format: "%.4f", rLat)),
            URLQueryItem(name: "lon", value: String(format: "%.4f", rLon))
        ]
        var request = URLRequest(url: components.url!)
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
