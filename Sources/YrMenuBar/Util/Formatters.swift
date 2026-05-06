import Foundation

enum SFSymbol {
    /// Maps a met.no symbol_code to an SF Symbol name (used for the menu bar icon).
    static func from(symbolCode: String?) -> String {
        guard let code = symbolCode else { return "thermometer.medium" }
        let base = code.replacingOccurrences(of: "_day", with: "")
                       .replacingOccurrences(of: "_night", with: "")
                       .replacingOccurrences(of: "_polartwilight", with: "")
        switch base {
        case "clearsky": return "sun.max"
        case "fair": return "sun.min"
        case "partlycloudy": return "cloud.sun"
        case "cloudy": return "cloud"
        case "fog": return "cloud.fog"
        case "rainshowers", "lightrainshowers", "heavyrainshowers": return "cloud.sun.rain"
        case "rain", "lightrain", "heavyrain": return "cloud.rain"
        case "rainshowersandthunder", "lightrainshowersandthunder", "heavyrainshowersandthunder",
             "rainandthunder", "lightrainandthunder", "heavyrainandthunder": return "cloud.bolt.rain"
        case "sleet", "lightsleet", "heavysleet",
             "sleetshowers", "lightsleetshowers", "heavysleetshowers": return "cloud.sleet"
        case "snow", "lightsnow", "heavysnow",
             "snowshowers", "lightsnowshowers", "heavysnowshowers": return "cloud.snow"
        case "snowandthunder", "lightsnowandthunder", "heavysnowandthunder",
             "snowshowersandthunder", "lightsnowshowersandthunder", "heavysnowshowersandthunder",
             "lightssnowshowersandthunder": return "cloud.bolt.snow"
        case "sleetandthunder", "lightsleetandthunder", "heavysleetandthunder",
             "sleetshowersandthunder", "lightsleetshowersandthunder", "heavysleetshowersandthunder",
             "lightssleetshowersandthunder": return "cloud.bolt.rain"
        default: return "cloud"
        }
    }
}

struct WeatherFormatters {
    let units: UnitSystem

    func temperature(_ celsius: Double?) -> String {
        guard let c = celsius else { return "—" }
        switch units {
        case .metric: return String(format: "%.0f°C", c)
        case .imperial: return String(format: "%.0f°F", c * 9 / 5 + 32)
        }
    }

    func tempShort(_ celsius: Double?) -> String {
        guard let c = celsius else { return "—" }
        switch units {
        case .metric: return String(format: "%.0f°", c)
        case .imperial: return String(format: "%.0f°", c * 9 / 5 + 32)
        }
    }

    func wind(_ ms: Double?) -> String {
        guard let v = ms else { return "—" }
        switch units {
        case .metric: return String(format: "%.1f m/s", v)
        case .imperial: return String(format: "%.1f mph", v * 2.23694)
        }
    }

    func precip(_ mm: Double?) -> String {
        guard let v = mm else { return "—" }
        switch units {
        case .metric: return String(format: "%.1f mm", v)
        case .imperial: return String(format: "%.2f in", v / 25.4)
        }
    }

    func pressure(_ hpa: Double?) -> String {
        guard let v = hpa else { return "—" }
        switch units {
        case .metric: return String(format: "%.0f hPa", v)
        case .imperial: return String(format: "%.2f inHg", v * 0.02953)
        }
    }

    func humidity(_ pct: Double?) -> String {
        guard let v = pct else { return "—" }
        return String(format: "%.0f%%", v)
    }

    static func windDirectionLabel(_ degrees: Double?) -> String {
        guard let d = degrees else { return "—" }
        let dirs = ["N","NE","E","SE","S","SW","W","NW"]
        let idx = Int(((d + 22.5).truncatingRemainder(dividingBy: 360)) / 45) % 8
        return dirs[idx]
    }
}
