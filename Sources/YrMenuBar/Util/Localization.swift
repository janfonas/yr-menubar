import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system, en, nb
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .en: return "English"
        case .nb: return "Norsk (bokmål)"
        }
    }

    /// Effective language code resolved from user preferences.
    static var resolved: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? AppLanguage.system.rawValue
        let chosen = AppLanguage(rawValue: raw) ?? .system
        if chosen != .system { return chosen }
        // Fall back to the first preferred language matching what we ship.
        let pref = (Locale.preferredLanguages.first ?? "en").lowercased()
        if pref.hasPrefix("nb") || pref.hasPrefix("nn") || pref.hasPrefix("no") { return .nb }
        return .en
    }
}

/// Minimal in-code localization. Avoids needing .lproj bundles in a bare SwiftPM target.
enum L10n {
    static func t(_ key: Key) -> String {
        switch AppLanguage.resolved {
        case .nb: return key.nb
        default:  return key.en
        }
    }

    enum Key {
        // UI
        case now, sevenDay, settings, quit, refresh, updatedAgo
        case today, tomorrow
        case wind, humidity, pressure, precip1h, cloud, uv
        case loading, error
        case feelsLike, fromDirection
        case dryNextHour, precipNextHour
        // Beaufort
        case bf0, bf1, bf2, bf3, bf4, bf5, bf6, bf7, bf8, bf9, bf10, bf11, bf12
        // Compass long names
        case dirN, dirNE, dirE, dirSE, dirS, dirSW, dirW, dirNW
        // Settings sections + labels
        case sectionLocation, sectionUnits, sectionStartup, sectionLanguage
        case useCurrentLocation, authorization, requestAccess
        case authNotDetermined, authRestricted, authDenied, authAuthorized, authUnknown
        case fallbackLocation, searchCity, searchButton, name, lat, lon, noResults
        case unitsLabel, unitsMetric, unitsImperial
        case launchAtLogin
        case language

        var en: String {
            switch self {
            case .now: return "Now"
            case .sevenDay: return "7-day"
            case .settings: return "Settings…"
            case .quit: return "Quit"
            case .refresh: return "Refresh"
            case .updatedAgo: return "Updated"
            case .today: return "Today"
            case .tomorrow: return "Tom."
            case .wind: return "Wind"
            case .humidity: return "Humidity"
            case .pressure: return "Pressure"
            case .precip1h: return "Precip (1h)"
            case .cloud: return "Cloud"
            case .uv: return "UV"
            case .loading: return "Loading…"
            case .error: return "Error"
            case .feelsLike: return "Feels like"
            case .fromDirection: return "from"
            case .dryNextHour: return "Dry next hour"
            case .precipNextHour: return "Precipitation next hour"
            case .bf0: return "Calm"
            case .bf1: return "Light air"
            case .bf2: return "Light breeze"
            case .bf3: return "Gentle breeze"
            case .bf4: return "Moderate breeze"
            case .bf5: return "Fresh breeze"
            case .bf6: return "Strong breeze"
            case .bf7: return "Near gale"
            case .bf8: return "Gale"
            case .bf9: return "Strong gale"
            case .bf10: return "Storm"
            case .bf11: return "Violent storm"
            case .bf12: return "Hurricane"
            case .dirN: return "north"
            case .dirNE: return "north-east"
            case .dirE: return "east"
            case .dirSE: return "south-east"
            case .dirS: return "south"
            case .dirSW: return "south-west"
            case .dirW: return "west"
            case .dirNW: return "north-west"
            case .sectionLocation: return "Location"
            case .sectionUnits: return "Units"
            case .sectionStartup: return "Startup"
            case .sectionLanguage: return "Language"
            case .useCurrentLocation: return "Use current location"
            case .authorization: return "Authorization:"
            case .requestAccess: return "Request access"
            case .authNotDetermined: return "Not determined"
            case .authRestricted: return "Restricted"
            case .authDenied: return "Denied"
            case .authAuthorized: return "Authorized"
            case .authUnknown: return "Unknown"
            case .fallbackLocation: return "Fallback location"
            case .searchCity: return "Search city…"
            case .searchButton: return "Search"
            case .name: return "Name"
            case .lat: return "Lat"
            case .lon: return "Lon"
            case .noResults: return "No results"
            case .unitsLabel: return "Units"
            case .unitsMetric: return "Metric (°C, m/s, mm)"
            case .unitsImperial: return "Imperial (°F, mph, in)"
            case .launchAtLogin: return "Launch at login"
            case .language: return "Language"
            }
        }

        var nb: String {
            switch self {
            case .now: return "Nå"
            case .sevenDay: return "7 dager"
            case .settings: return "Innstillinger…"
            case .quit: return "Avslutt"
            case .refresh: return "Oppdater"
            case .updatedAgo: return "Oppdatert"
            case .today: return "I dag"
            case .tomorrow: return "I morgen"
            case .wind: return "Vind"
            case .humidity: return "Luftfukt."
            case .pressure: return "Trykk"
            case .precip1h: return "Nedbør (1t)"
            case .cloud: return "Skyer"
            case .uv: return "UV"
            case .loading: return "Laster…"
            case .error: return "Feil"
            case .feelsLike: return "Føles som"
            case .fromDirection: return "fra"
            case .dryNextHour: return "Opphold neste time"
            case .precipNextHour: return "Nedbør neste time"
            case .bf0: return "Stille"
            case .bf1: return "Flau vind"
            case .bf2: return "Svak vind"
            case .bf3: return "Lett bris"
            case .bf4: return "Laber bris"
            case .bf5: return "Frisk bris"
            case .bf6: return "Liten kuling"
            case .bf7: return "Stiv kuling"
            case .bf8: return "Sterk kuling"
            case .bf9: return "Liten storm"
            case .bf10: return "Full storm"
            case .bf11: return "Sterk storm"
            case .bf12: return "Orkan"
            case .dirN: return "nord"
            case .dirNE: return "nordøst"
            case .dirE: return "øst"
            case .dirSE: return "sørøst"
            case .dirS: return "sør"
            case .dirSW: return "sørvest"
            case .dirW: return "vest"
            case .dirNW: return "nordvest"
            case .sectionLocation: return "Posisjon"
            case .sectionUnits: return "Enheter"
            case .sectionStartup: return "Oppstart"
            case .sectionLanguage: return "Språk"
            case .useCurrentLocation: return "Bruk nåværende posisjon"
            case .authorization: return "Tilgang:"
            case .requestAccess: return "Be om tilgang"
            case .authNotDetermined: return "Ikke avgjort"
            case .authRestricted: return "Begrenset"
            case .authDenied: return "Avslått"
            case .authAuthorized: return "Tillatt"
            case .authUnknown: return "Ukjent"
            case .fallbackLocation: return "Standardplassering"
            case .searchCity: return "Søk etter sted…"
            case .searchButton: return "Søk"
            case .name: return "Navn"
            case .lat: return "Bredde"
            case .lon: return "Lengde"
            case .noResults: return "Ingen treff"
            case .unitsLabel: return "Enheter"
            case .unitsMetric: return "Metrisk (°C, m/s, mm)"
            case .unitsImperial: return "Imperial (°F, mph, in)"
            case .launchAtLogin: return "Start ved pålogging"
            case .language: return "Språk"
            }
        }
    }

    /// Human-readable description for a met.no symbol_code.
    static func describe(symbolCode: String?) -> String {
        guard let code = symbolCode else { return "—" }
        let isNight = code.contains("_night")
        let base = code
            .replacingOccurrences(of: "_day", with: "")
            .replacingOccurrences(of: "_night", with: "")
            .replacingOccurrences(of: "_polartwilight", with: "")
        let table = AppLanguage.resolved == .nb ? Self.nbTable : Self.enTable
        let baseText = table[base] ?? base.replacingOccurrences(of: "_", with: " ").capitalized
        if isNight {
            let suffix = AppLanguage.resolved == .nb ? " (natt)" : " (night)"
            return baseText + suffix
        }
        return baseText
    }

    private static let enTable: [String: String] = [
        "clearsky": "Clear sky",
        "fair": "Fair",
        "partlycloudy": "Partly cloudy",
        "cloudy": "Cloudy",
        "fog": "Fog",
        "rainshowers": "Rain showers",
        "lightrainshowers": "Light rain showers",
        "heavyrainshowers": "Heavy rain showers",
        "rain": "Rain",
        "lightrain": "Light rain",
        "heavyrain": "Heavy rain",
        "rainshowersandthunder": "Rain showers and thunder",
        "lightrainshowersandthunder": "Light rain showers and thunder",
        "heavyrainshowersandthunder": "Heavy rain showers and thunder",
        "rainandthunder": "Rain and thunder",
        "lightrainandthunder": "Light rain and thunder",
        "heavyrainandthunder": "Heavy rain and thunder",
        "sleet": "Sleet",
        "lightsleet": "Light sleet",
        "heavysleet": "Heavy sleet",
        "sleetshowers": "Sleet showers",
        "lightsleetshowers": "Light sleet showers",
        "heavysleetshowers": "Heavy sleet showers",
        "sleetandthunder": "Sleet and thunder",
        "lightsleetandthunder": "Light sleet and thunder",
        "heavysleetandthunder": "Heavy sleet and thunder",
        "sleetshowersandthunder": "Sleet showers and thunder",
        "lightssleetshowersandthunder": "Light sleet showers and thunder",
        "heavysleetshowersandthunder": "Heavy sleet showers and thunder",
        "snow": "Snow",
        "lightsnow": "Light snow",
        "heavysnow": "Heavy snow",
        "snowshowers": "Snow showers",
        "lightsnowshowers": "Light snow showers",
        "heavysnowshowers": "Heavy snow showers",
        "snowandthunder": "Snow and thunder",
        "lightsnowandthunder": "Light snow and thunder",
        "heavysnowandthunder": "Heavy snow and thunder",
        "snowshowersandthunder": "Snow showers and thunder",
        "lightssnowshowersandthunder": "Light snow showers and thunder",
        "heavysnowshowersandthunder": "Heavy snow showers and thunder"
    ]

    private static let nbTable: [String: String] = [
        "clearsky": "Klarvær",
        "fair": "Lettskyet",
        "partlycloudy": "Delvis skyet",
        "cloudy": "Skyet",
        "fog": "Tåke",
        "rainshowers": "Regnbyger",
        "lightrainshowers": "Lette regnbyger",
        "heavyrainshowers": "Kraftige regnbyger",
        "rain": "Regn",
        "lightrain": "Lett regn",
        "heavyrain": "Kraftig regn",
        "rainshowersandthunder": "Regnbyger og torden",
        "lightrainshowersandthunder": "Lette regnbyger og torden",
        "heavyrainshowersandthunder": "Kraftige regnbyger og torden",
        "rainandthunder": "Regn og torden",
        "lightrainandthunder": "Lett regn og torden",
        "heavyrainandthunder": "Kraftig regn og torden",
        "sleet": "Sludd",
        "lightsleet": "Lett sludd",
        "heavysleet": "Kraftig sludd",
        "sleetshowers": "Sluddbyger",
        "lightsleetshowers": "Lette sluddbyger",
        "heavysleetshowers": "Kraftige sluddbyger",
        "sleetandthunder": "Sludd og torden",
        "lightsleetandthunder": "Lett sludd og torden",
        "heavysleetandthunder": "Kraftig sludd og torden",
        "sleetshowersandthunder": "Sluddbyger og torden",
        "lightssleetshowersandthunder": "Lette sluddbyger og torden",
        "heavysleetshowersandthunder": "Kraftige sluddbyger og torden",
        "snow": "Snø",
        "lightsnow": "Lett snø",
        "heavysnow": "Kraftig snø",
        "snowshowers": "Snøbyger",
        "lightsnowshowers": "Lette snøbyger",
        "heavysnowshowers": "Kraftige snøbyger",
        "snowandthunder": "Snø og torden",
        "lightsnowandthunder": "Lett snø og torden",
        "heavysnowandthunder": "Kraftig snø og torden",
        "snowshowersandthunder": "Snøbyger og torden",
        "lightssnowshowersandthunder": "Lette snøbyger og torden",
        "heavysnowshowersandthunder": "Kraftige snøbyger og torden"
    ]

    /// Locale used for date/number formatting (weekday names, etc.).
    static var locale: Locale {
        switch AppLanguage.resolved {
        case .nb: return Locale(identifier: "nb_NO")
        default:  return Locale(identifier: "en_US")
        }
    }
}
