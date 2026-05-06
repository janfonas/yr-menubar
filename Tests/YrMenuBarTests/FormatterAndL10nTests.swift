#if canImport(Testing)
import Testing
import Foundation
@testable import YrMenuBar

@Suite struct FormatterAndL10nTests {

    // MARK: Apparent temperature (Steadman 1994)

    @Test func apparentTemperatureNilWhenNoTemperature() {
        #expect(WeatherFormatters.apparentTemperature(t: nil, rh: 50, ws: 0) == nil)
    }

    @Test func apparentTemperatureColderInWind() {
        let calm = WeatherFormatters.apparentTemperature(t: 5, rh: 50, ws: 0)!
        let windy = WeatherFormatters.apparentTemperature(t: 5, rh: 50, ws: 10)!
        #expect(windy < calm)
    }

    @Test func apparentTemperatureWarmerWithHumidityHotDay() {
        let dry = WeatherFormatters.apparentTemperature(t: 30, rh: 20, ws: 0)!
        let humid = WeatherFormatters.apparentTemperature(t: 30, rh: 90, ws: 0)!
        #expect(humid > dry)
    }

    // MARK: Beaufort thresholds (m/s)

    @Test func beaufortLow() {
        #expect(WeatherFormatters.beaufortName(0.1).count > 0)   // Calm / Stille
        #expect(WeatherFormatters.beaufortName(0.5) != WeatherFormatters.beaufortName(0.1))
    }

    @Test func beaufortHurricaneAt33() {
        // 32.7 m/s is the hurricane threshold
        let storm = WeatherFormatters.beaufortName(20)
        let hurricane = WeatherFormatters.beaufortName(35)
        #expect(storm != hurricane)
    }

    @Test func beaufortNilForMissing() {
        #expect(WeatherFormatters.beaufortName(nil) == "—")
    }

    // MARK: Wind direction (8-point compass)

    @Test func windDirectionLabelBoundaries() {
        // Each octant is 45°; offsets of ±22.5° around N, E, S, W still snap.
        #expect(WeatherFormatters.windDirectionLabel(0) == "N")
        #expect(WeatherFormatters.windDirectionLabel(22) == "N")
        #expect(WeatherFormatters.windDirectionLabel(23) != "N")
        #expect(WeatherFormatters.windDirectionLabel(360) == "N")
    }

    @Test func windDirectionLabelNilForMissing() {
        #expect(WeatherFormatters.windDirectionLabel(nil) == "—")
    }

    // MARK: Unit formatting

    @Test func temperatureFormattingMetric() {
        let m = WeatherFormatters(units: .metric)
        #expect(m.temperature(20) == "20°C")
        #expect(m.tempShort(20) == "20°")
        #expect(m.temperature(nil) == "—")
    }

    @Test func temperatureFormattingImperial() {
        let i = WeatherFormatters(units: .imperial)
        #expect(i.temperature(0) == "32°F")
        #expect(i.temperature(100) == "212°F")
    }

    @Test func windFormatting() {
        let m = WeatherFormatters(units: .metric)
        let i = WeatherFormatters(units: .imperial)
        #expect(m.wind(10) == "10.0 m/s")
        #expect(i.wind(10).hasSuffix("mph"))
    }

    @Test func precipFormatting() {
        let m = WeatherFormatters(units: .metric)
        #expect(m.precip(2.5) == "2.5 mm")
        #expect(m.precip(nil) == "—")
    }

    // MARK: L10n

    @Test func localizationFallbackToEnglish() {
        // We can't easily switch the global resolved language inside a unit
        // test, but we can verify both `.en` and `.nb` strings are non-empty
        // for every key.
        for key in allKeys() {
            #expect(!key.en.isEmpty)
            #expect(!key.nb.isEmpty)
        }
    }

    @Test func describeKnownSymbol() {
        let s = L10n.describe(symbolCode: "clearsky_day")
        #expect(!s.isEmpty)
    }

    private func allKeys() -> [L10n.Key] {
        return [
            .now, .sevenDay, .settings, .quit, .refresh, .updatedAgo,
            .today, .tomorrow,
            .wind, .humidity, .pressure, .precip1h, .cloud, .uv,
            .loading, .error,
            .feelsLike, .fromDirection,
            .dryNextHour, .precipNextHour,
            .bf0, .bf1, .bf2, .bf3, .bf4, .bf5, .bf6, .bf7, .bf8, .bf9, .bf10, .bf11, .bf12,
            .dirN, .dirNE, .dirE, .dirSE, .dirS, .dirSW, .dirW, .dirNW,
            .sectionLocation, .sectionUnits, .sectionStartup, .sectionLanguage, .sectionGeneral,
            .useCurrentLocation, .authorization, .requestAccess,
            .authNotDetermined, .authRestricted, .authDenied, .authAuthorized, .authUnknown,
            .fallbackLocation, .searchCity, .searchButton, .name, .lat, .lon, .noResults,
            .unitsLabel, .unitsMetric, .unitsImperial,
            .launchAtLogin, .language
        ]
    }
}
#endif
