import Foundation

/// Decoded GeoJSON FeatureCollection from
/// `https://api.met.no/weatherapi/metalerts/2.0/current.json` and friends.
///
/// We only decode what we need for the UI; the API ships many more fields
/// (CAP message metadata, polygon geometry, etc.) that we deliberately ignore.
struct MetAlertsResponse: Decodable {
    let lang: String?
    let lastChange: Date?
    let features: [Feature]

    struct Feature: Decodable {
        let properties: WeatherAlert
        let when: When?

        struct When: Decodable {
            /// `[start, end]` in ISO 8601.
            let interval: [Date]
        }
    }
}

/// One weather warning. Fields mirror the GeoJSON `properties` block returned
/// by the met.no MetAlerts v2 endpoint.
///
/// References:
/// - https://api.met.no/weatherapi/metalerts/2.0/documentation
/// - CAP profile: http://docs.oasis-open.org/emergency/cap/v1.2/CAP-v1.2-os.html
struct WeatherAlert: Decodable, Identifiable, Hashable {
    let id: String
    let event: String?              // "forestFire", "rain", "wind", …
    let eventAwarenessName: String? // human-friendly headline
    let title: String?
    let description: String?
    let instruction: String?
    let consequences: String?
    let area: String?
    let geographicDomain: String?   // "land" | "marine"
    let awarenessResponse: String?
    let awarenessSeriousness: String?
    let awarenessLevel: String?     // "2; yellow; Moderate"
    let awarenessType: String?      // "8; forest-fire"
    let certainty: String?          // "Possible" | "Likely" | "Observed"
    let severity: String?           // "Minor" | "Moderate" | "Severe" | "Extreme"
    let riskMatrixColor: String?    // "Yellow" | "Orange" | "Red"
    let status: String?             // "Actual" | "Test" | …
    let type: String?               // "Alert" | "Update" | "Cancel"
    let web: URL?

    enum CodingKeys: String, CodingKey {
        case id, event, eventAwarenessName, title, description, instruction
        case consequences, area, geographicDomain
        case awarenessResponse, awarenessSeriousness
        case awarenessLevel = "awareness_level"
        case awarenessType = "awareness_type"
        case certainty, severity, riskMatrixColor, status, type, web
    }

    /// Best-effort numeric severity for sorting (3 = Red, 2 = Orange, 1 = Yellow).
    var severityRank: Int {
        switch (riskMatrixColor ?? "").lowercased() {
        case "red": return 3
        case "orange": return 2
        case "yellow": return 1
        default: return 0
        }
    }

    /// Human-readable headline preferring the awareness name.
    var headline: String {
        eventAwarenessName ?? title ?? event ?? id
    }
}
