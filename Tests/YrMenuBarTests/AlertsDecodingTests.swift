#if canImport(Testing)
import Testing
import Foundation
@testable import YrMenuBar

@Suite struct AlertsDecodingTests {
    @Test func decodeExampleFixture() throws {
        let url = Bundle.module.url(forResource: "alerts-example", withExtension: "json")
        try #require(url != nil)
        let data = try Data(contentsOf: url!)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let envelope = try decoder.decode(MetAlertsResponse.self, from: data)
        #expect(!envelope.features.isEmpty)
        let first = envelope.features[0].properties
        #expect(!first.id.isEmpty)
        #expect(first.event != nil)
        #expect(first.headline.count > 0)
    }

    @Test func severityRanking() {
        let red    = stub(color: "Red")
        let orange = stub(color: "Orange")
        let yellow = stub(color: "Yellow")
        #expect(red.severityRank == 3)
        #expect(orange.severityRank == 2)
        #expect(yellow.severityRank == 1)
        #expect(red.severityRank > orange.severityRank)
        #expect(orange.severityRank > yellow.severityRank)
    }

    @Test func headlineFallback() {
        let withName = stub(color: "Yellow", awarenessName: "Stor skogbrannfare", title: "title", event: "forestFire")
        #expect(withName.headline == "Stor skogbrannfare")
        let titleOnly = stub(color: "Yellow", awarenessName: nil, title: "title", event: "forestFire")
        #expect(titleOnly.headline == "title")
        let eventOnly = stub(color: "Yellow", awarenessName: nil, title: nil, event: "forestFire")
        #expect(eventOnly.headline == "forestFire")
    }

    private func stub(color: String,
                      awarenessName: String? = nil,
                      title: String? = nil,
                      event: String? = nil) -> WeatherAlert {
        let json = """
        {
            "id": "test.\(color)",
            "event": \(event.map { "\"\($0)\"" } ?? "null"),
            "eventAwarenessName": \(awarenessName.map { "\"\($0)\"" } ?? "null"),
            "title": \(title.map { "\"\($0)\"" } ?? "null"),
            "riskMatrixColor": "\(color)"
        }
        """
        let decoder = JSONDecoder()
        return try! decoder.decode(WeatherAlert.self, from: Data(json.utf8))
    }
}
#endif
