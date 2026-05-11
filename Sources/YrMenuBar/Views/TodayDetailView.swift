import SwiftUI

/// Hour-by-hour breakdown for today, presented as a sheet from the Now-tab card.
struct TodayDetailView: View {
    let entries: [LocationForecast.TimeSeriesEntry]
    let units: UnitSystem
    var onClose: () -> Void = {}

    var body: some View {
        let f = WeatherFormatters(units: units)
        let summary = daySummary()

        VStack(spacing: 0) {
            header(summary: summary, formatter: f)

            Divider()

            if entries.isEmpty {
                Spacer()
                Text("—")
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(entries, id: \.time) { entry in
                            HourRow(entry: entry, formatter: f)
                            if entry.time != entries.last?.time {
                                Divider().opacity(0.4)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
        )
        .padding(8)
    }

    @ViewBuilder
    private func header(summary: (min: Double?, max: Double?, precip: Double),
                        formatter f: WeatherFormatters) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t(.todayDetails))
                    .font(.headline)
                Text(dateLabel())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 10) {
                Label(f.tempShort(summary.max), systemImage: "arrow.up")
                Label(f.tempShort(summary.min), systemImage: "arrow.down")
                Label(f.precip(summary.precip), systemImage: "drop")
                    .foregroundStyle(.blue)
            }
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .keyboardShortcut(.cancelAction)
            .help(L10n.t(.close))
            .padding(.leading, 4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func dateLabel() -> String {
        let fmt = DateFormatter()
        fmt.locale = L10n.locale
        fmt.dateFormat = "EEEE d. MMMM"
        let date = entries.first?.time ?? Date()
        return fmt.string(from: date).capitalized
    }

    private func daySummary() -> (min: Double?, max: Double?, precip: Double) {
        let temps = entries.compactMap { $0.data.instant.details.airTemperature }
        let precip = entries.reduce(0.0) { acc, e in
            acc + (e.data.next1Hours?.details?.precipitationAmount ?? 0)
        }
        return (temps.min(), temps.max(), precip)
    }
}

private struct HourRow: View {
    let entry: LocationForecast.TimeSeriesEntry
    let formatter: WeatherFormatters

    var body: some View {
        let inst = entry.data.instant.details
        let symbol = entry.data.next1Hours?.summary?.symbolCode
            ?? entry.data.next6Hours?.summary?.symbolCode
        let precip = entry.data.next1Hours?.details?.precipitationAmount

        HStack(spacing: 10) {
            Text(timeLabel(entry.time))
                .font(.callout.weight(.medium))
                .monospacedDigit()
                .frame(width: 46, alignment: .leading)

            WeatherCanvas(symbolCode: symbol)
                .frame(width: 28, height: 28)

            Text(formatter.tempShort(inst.airTemperature))
                .font(.callout.weight(.semibold))
                .monospacedDigit()
                .frame(width: 50, alignment: .leading)

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                Image(systemName: (precip ?? 0) > 0.05 ? "drop.fill" : "drop")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text(formatter.precip(precip ?? 0))
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .monospacedDigit()
            }
            .frame(width: 70, alignment: .trailing)

            HStack(spacing: 4) {
                Image(systemName: "wind")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(windText(speed: inst.windSpeed,
                              direction: inst.windFromDirection))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    private func timeLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = L10n.locale
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    private func windText(speed: Double?, direction: Double?) -> String {
        let dir = WeatherFormatters.windDirectionLabel(direction)
        guard let v = speed else { return dir }
        let value: String
        switch formatter.units {
        case .metric:   value = String(format: "%.0f m/s", v)
        case .imperial: value = String(format: "%.0f mph", v * 2.23694)
        }
        return "\(value) \(dir)"
    }
}
