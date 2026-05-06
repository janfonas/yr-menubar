import Foundation

/// Centralized magic numbers used across the app.
enum Constants {
    /// Minimum interval between forecast refreshes when not honouring the
    /// `Expires` header from met.no (e.g. on cache reuse).
    static let minimumRefreshInterval: TimeInterval = 15 * 60

    /// Hard ceiling on how long we will wait between refreshes, even when
    /// the server-provided `Expires` header is far in the future.
    static let maximumRefreshInterval: TimeInterval = 60 * 60

    /// Tick rate for the animated WeatherCanvas when on screen.
    static let canvasAnimatedFps: Double = 30

    /// Tick rate for static (non-foreground) WeatherCanvas instances.
    static let canvasStaticFps: Double = 6

    /// Decimals to round lat/lon to before requesting met.no (per API guidance).
    static let coordinateDecimals: Int = 4

    /// Value below which precipitation rates / amounts are treated as "dry".
    static let precipitationNoiseFloor: Double = 0.05

    /// Cadence for polling met.no MetAlerts. The API explicitly asks clients
    /// not to hit it on every forecast refresh, so this is intentionally
    /// longer than `minimumRefreshInterval`.
    static let alertsRefreshInterval: TimeInterval = 20 * 60
}
