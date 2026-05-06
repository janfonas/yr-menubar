import SwiftUI

struct CurrentWeatherView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let f = WeatherFormatters(units: settings.unitSystem)
        let inst = store.currentInstant
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                WeatherCanvas(symbolCode: store.currentSymbolCode, animated: true)
                    .frame(width: 96, height: 96)
                VStack(alignment: .leading, spacing: 2) {
                    Text(f.temperature(inst?.airTemperature))
                        .font(.system(size: 38, weight: .semibold, design: .rounded))
                    Text(humanReadable(store.currentSymbolCode))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }

            Divider()

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                metric("Wind",
                       value: "\(f.wind(inst?.windSpeed)) \(WeatherFormatters.windDirectionLabel(inst?.windFromDirection))",
                       icon: "wind")
                metric("Humidity", value: f.humidity(inst?.relativeHumidity), icon: "humidity")
                metric("Pressure", value: f.pressure(inst?.airPressureAtSeaLevel), icon: "gauge")
                metric("Precip (1h)", value: f.precip(store.nextHourPrecip), icon: "drop")
                metric("Cloud", value: f.humidity(inst?.cloudAreaFraction), icon: "cloud")
                metric("UV", value: inst?.uvIndexClearSky.map { String(format: "%.1f", $0) } ?? "—", icon: "sun.max")
            }
        }
    }

    @ViewBuilder
    private func metric(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 16)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption2).foregroundStyle(.secondary)
                Text(value).font(.callout).monospacedDigit()
            }
            Spacer()
        }
    }

    private func humanReadable(_ code: String?) -> String {
        guard let c = code else { return "—" }
        let base = c.replacingOccurrences(of: "_day", with: "")
                    .replacingOccurrences(of: "_night", with: "")
                    .replacingOccurrences(of: "_polartwilight", with: "")
                    .replacingOccurrences(of: "_", with: " ")
        return base.prefix(1).uppercased() + base.dropFirst()
    }
}
