import Foundation

struct LocationForecast: Codable, Equatable {
    let properties: Properties

    struct Properties: Codable, Equatable {
        let meta: Meta
        let timeseries: [TimeSeriesEntry]
    }

    struct Meta: Codable, Equatable {
        let updatedAt: Date
        let units: [String: String]

        enum CodingKeys: String, CodingKey {
            case updatedAt = "updated_at"
            case units
        }
    }

    struct TimeSeriesEntry: Codable, Equatable {
        let time: Date
        let data: EntryData
    }

    struct EntryData: Codable, Equatable {
        let instant: Instant
        let next1Hours: Period?
        let next6Hours: Period?
        let next12Hours: Period?

        enum CodingKeys: String, CodingKey {
            case instant
            case next1Hours = "next_1_hours"
            case next6Hours = "next_6_hours"
            case next12Hours = "next_12_hours"
        }
    }

    struct Instant: Codable, Equatable {
        let details: InstantDetails
    }

    struct InstantDetails: Codable, Equatable {
        let airTemperature: Double?
        let airPressureAtSeaLevel: Double?
        let relativeHumidity: Double?
        let windSpeed: Double?
        let windFromDirection: Double?
        let cloudAreaFraction: Double?
        let uvIndexClearSky: Double?

        enum CodingKeys: String, CodingKey {
            case airTemperature = "air_temperature"
            case airPressureAtSeaLevel = "air_pressure_at_sea_level"
            case relativeHumidity = "relative_humidity"
            case windSpeed = "wind_speed"
            case windFromDirection = "wind_from_direction"
            case cloudAreaFraction = "cloud_area_fraction"
            case uvIndexClearSky = "ultraviolet_index_clear_sky"
        }
    }

    struct Period: Codable, Equatable {
        let summary: Summary?
        let details: PeriodDetails?
    }

    struct Summary: Codable, Equatable {
        let symbolCode: String

        enum CodingKeys: String, CodingKey {
            case symbolCode = "symbol_code"
        }
    }

    struct PeriodDetails: Codable, Equatable {
        let precipitationAmount: Double?
        let airTemperatureMin: Double?
        let airTemperatureMax: Double?

        enum CodingKeys: String, CodingKey {
            case precipitationAmount = "precipitation_amount"
            case airTemperatureMin = "air_temperature_min"
            case airTemperatureMax = "air_temperature_max"
        }
    }
}

struct DailySummary: Identifiable, Equatable {
    let id: Date
    var date: Date { id }
    let minTemp: Double?
    let maxTemp: Double?
    let precipitation: Double
    let symbolCode: String?
    let windSpeed: Double?
}
