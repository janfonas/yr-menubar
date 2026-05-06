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
        let enDirs = ["N","NE","E","SE","S","SW","W","NW"]
        let nbDirs = ["N","NØ","Ø","SØ","S","SV","V","NV"]
        let dirs = AppLanguage.resolved == .nb ? nbDirs : enDirs
        let idx = Int(((d + 22.5).truncatingRemainder(dividingBy: 360)) / 45) % 8
        return dirs[idx]
    }

    static func windDirectionLong(_ degrees: Double?) -> String {
        guard let d = degrees else { return "—" }
        let keys: [L10n.Key] = [.dirN, .dirNE, .dirE, .dirSE, .dirS, .dirSW, .dirW, .dirNW]
        let idx = Int(((d + 22.5).truncatingRemainder(dividingBy: 360)) / 45) % 8
        return L10n.t(keys[idx])
    }

    /// Beaufort name (localized) for a wind speed in m/s.
    static func beaufortName(_ ms: Double?) -> String {
        guard let v = ms else { return "—" }
        let key: L10n.Key
        switch v {
        case ..<0.3:  key = .bf0
        case ..<1.6:  key = .bf1
        case ..<3.4:  key = .bf2
        case ..<5.5:  key = .bf3
        case ..<8.0:  key = .bf4
        case ..<10.8: key = .bf5
        case ..<13.9: key = .bf6
        case ..<17.2: key = .bf7
        case ..<20.8: key = .bf8
        case ..<24.5: key = .bf9
        case ..<28.5: key = .bf10
        case ..<32.7: key = .bf11
        default:      key = .bf12
        }
        return L10n.t(key)
    }

    /// Australian Apparent Temperature (Steadman 1994) in °C.
    /// AT = T + 0.33·e − 0.70·ws − 4.00, where e = (rh/100)·6.105·exp(17.27·T/(237.7+T)).
    static func apparentTemperature(t: Double?, rh: Double?, ws: Double?) -> Double? {
        guard let t = t else { return nil }
        let rh = rh ?? 50
        let ws = ws ?? 0
        let e = (rh / 100.0) * 6.105 * exp(17.27 * t / (237.7 + t))
        return t + 0.33 * e - 0.70 * ws - 4.0
    }
}
