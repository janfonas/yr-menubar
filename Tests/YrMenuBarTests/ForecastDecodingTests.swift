#if canImport(Testing)
import Testing
import Foundation
@testable import YrMenuBar

@Suite struct ForecastDecodingTests {
    @Test func decodeCompactFixture() throws {
        let url = Bundle.module.url(forResource: "compact-sample", withExtension: "json")
        try #require(url != nil)
        let data = try Data(contentsOf: url!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let forecast = try decoder.decode(LocationForecast.self, from: data)
        #expect(!forecast.properties.timeseries.isEmpty)
        let first = forecast.properties.timeseries[0]
        #expect(first.data.instant.details.airTemperature != nil)
        #expect(first.data.next1Hours?.summary?.symbolCode == "partlycloudy_day")
    }

    @Test func sfSymbolMapping() {
        #expect(SFSymbol.from(symbolCode: "clearsky_day") == "sun.max")
        #expect(SFSymbol.from(symbolCode: "partlycloudy_night") == "cloud.sun")
        #expect(SFSymbol.from(symbolCode: "heavyrainandthunder") == "cloud.bolt.rain")
        #expect(SFSymbol.from(symbolCode: "snow") == "cloud.snow")
        #expect(SFSymbol.from(symbolCode: nil) == "thermometer.medium")
    }

    @Test func formattersMetricVsImperial() {
        let m = WeatherFormatters(units: .metric)
        let i = WeatherFormatters(units: .imperial)
        #expect(m.temperature(0) == "0°C")
        #expect(i.temperature(0) == "32°F")
        #expect(WeatherFormatters.windDirectionLabel(0) == "N")
        #expect(WeatherFormatters.windDirectionLabel(90) == "E")
        #expect(WeatherFormatters.windDirectionLabel(180) == "S")
    }
}
#elseif canImport(XCTest)
import XCTest
@testable import YrMenuBar

final class ForecastDecodingTests: XCTestCase {
    func testDecodeCompactFixture() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "compact-sample", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        let forecast = try decoder.decode(LocationForecast.self, from: data)
        XCTAssertFalse(forecast.properties.timeseries.isEmpty)
        XCTAssertEqual(forecast.properties.timeseries[0].data.next1Hours?.summary?.symbolCode, "partlycloudy_day")
    }
    func testSFSymbolMapping() {
        XCTAssertEqual(SFSymbol.from(symbolCode: "clearsky_day"), "sun.max")
        XCTAssertEqual(SFSymbol.from(symbolCode: "snow"), "cloud.snow")
    }
}
#endif
