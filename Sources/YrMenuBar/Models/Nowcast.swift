import Foundation

/// met.no nowcast 2.0 (precipitation-only). Available for Nordic region;
/// elsewhere the API returns 422.
/// https://api.met.no/weatherapi/nowcast/2.0/documentation
struct Nowcast: Codable {
    struct Properties: Codable {
        let meta: Meta
        let timeseries: [Entry]
    }

    struct Meta: Codable {
        let updatedAt: Date
        let radarCoverage: String?

        enum CodingKeys: String, CodingKey {
            case updatedAt = "updated_at"
            case radarCoverage = "radar_coverage"
        }
    }

    struct Entry: Codable {
        let time: Date
        let data: EntryData
    }

    struct EntryData: Codable {
        let instant: Instant
    }

    struct Instant: Codable {
        let details: Details
    }

    struct Details: Codable {
        let precipitationRate: Double?

        enum CodingKeys: String, CodingKey {
            case precipitationRate = "precipitation_rate"
        }
    }

    let properties: Properties
}

extension Nowcast {
    /// Sample points (mm/h) every ~5 minutes covering ~90 minutes.
    /// Returns empty if the response had no precipitation_rate values.
    var precipitationSeries: [(time: Date, rate: Double)] {
        properties.timeseries.compactMap { entry in
            guard let r = entry.data.instant.details.precipitationRate else { return nil }
            return (entry.time, r)
        }
    }
}
