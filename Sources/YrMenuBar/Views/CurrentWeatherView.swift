import SwiftUI

/// yr.no-style "Now" view: full-bleed sky, large WeatherCanvas as scenery,
/// thin huge temperature, wind rose, today's high/low and precipitation status.
struct CurrentWeatherView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let f = WeatherFormatters(units: settings.unitSystem)
        let inst = store.currentInstant
        let symbol = store.currentSymbolCode
        let today = store.dailySummaries(days: 1).first

        ZStack(alignment: .topLeading) {
            // Animated scenery overlays whatever the parent already drew
            WeatherCanvas(symbolCode: symbol, animated: true)
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .opacity(0.95)

            // Bottom scrim to lift legibility of the lower copy.
            LinearGradient(
                colors: [.clear, .black.opacity(0.05), .black.opacity(0.35)],
                startPoint: .top, endPoint: .bottom)
                .allowsHitTesting(false)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 95)

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.t(.now))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                        Text(temperatureBig(inst?.airTemperature))
                            .font(.system(size: 64, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .padding(.top, -4)
                        if let feels = WeatherFormatters.apparentTemperature(
                                t: inst?.airTemperature,
                                rh: inst?.relativeHumidity,
                                ws: inst?.windSpeed) {
                            Text("\(L10n.t(.feelsLike)) \(f.tempShort(feels))")
                                .font(.caption)
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    VStack(spacing: 4) {
                        WindRose(speedMs: inst?.windSpeed,
                                 fromDirectionDegrees: inst?.windFromDirection,
                                 displaySpeed: windSpeedShort(inst?.windSpeed))
                        Text(windCaption(speed: inst?.windSpeed,
                                         direction: inst?.windFromDirection))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(width: 100)
                    }
                }
                .padding(.horizontal, 14)

                Spacer(minLength: 8)

                Text(L10n.describe(symbolCode: symbol))
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)

                if let day = today {
                    HStack(spacing: 12) {
                        Label(f.tempShort(day.maxTemp), systemImage: "arrow.up")
                        Label(f.tempShort(day.minTemp), systemImage: "arrow.down")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.top, 4)
                }

                precipitationStrip(formatter: f)
                    .padding(.horizontal, 14)
                    .padding(.top, 8)

                detailGrid(inst: inst, formatter: f)
                    .padding(.horizontal, 14)
                    .padding(.top, 10)
                    .padding(.bottom, 12)
            }
            // Soft drop-shadow on every text/icon for legibility on the sky.
            .shadow(color: .black.opacity(0.45), radius: 2, x: 0, y: 1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: helpers

    private func temperatureBig(_ celsius: Double?) -> String {
        guard let c = celsius else { return "—" }
        switch settings.unitSystem {
        case .metric:   return String(format: "%.0f°", c)
        case .imperial: return String(format: "%.0f°", c * 9 / 5 + 32)
        }
    }

    private func windSpeedShort(_ ms: Double?) -> String {
        guard let v = ms else { return "—" }
        switch settings.unitSystem {
        case .metric:   return String(format: "%.0f", v)
        case .imperial: return String(format: "%.0f", v * 2.23694)
        }
    }

    private func windCaption(speed: Double?, direction: Double?) -> String {
        let bf = WeatherFormatters.beaufortName(speed)
        guard let _ = direction else { return bf }
        let dir = WeatherFormatters.windDirectionLong(direction)
        let unit = settings.unitSystem == .metric ? "m/s" : "mph"
        return "\(bf) \(L10n.t(.fromDirection)) \(dir) (\(unit))"
    }

    @ViewBuilder
    private func precipitationStrip(formatter f: WeatherFormatters) -> some View {
        HStack(spacing: 6) {
            Image(systemName: store.nextHourPrecip ?? 0 > 0 ? "drop.fill" : "drop")
                .foregroundStyle(.white)
            if let p = store.nextHourPrecip, p > 0.05 {
                Text("\(L10n.t(.precipNextHour)): \(f.precip(p))")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
            } else {
                Text(L10n.t(.dryNextHour))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func detailGrid(inst: LocationForecast.InstantDetails?,
                            formatter f: WeatherFormatters) -> some View {
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            chip(L10n.t(.humidity), f.humidity(inst?.relativeHumidity), icon: "humidity")
            chip(L10n.t(.pressure), f.pressure(inst?.airPressureAtSeaLevel), icon: "gauge")
            chip(L10n.t(.uv),
                 inst?.uvIndexClearSky.map { String(format: "%.1f", $0) } ?? "—",
                 icon: "sun.max")
        }
    }

    @ViewBuilder
    private func chip(_ label: String, _ value: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2).foregroundStyle(.white)
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
    }
}
