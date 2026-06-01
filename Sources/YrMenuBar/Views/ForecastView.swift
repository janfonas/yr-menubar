import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings
    @State private var expandedDay: Date?

    var body: some View {
        let f = WeatherFormatters(units: settings.unitSystem)
        let days = store.dailySummaries(days: 7)
        ScrollView {
            VStack(spacing: 4) {
                ForEach(days) { day in
                    dayRow(day: day, formatter: f)
                }
            }
        }
    }

    @ViewBuilder
    private func dayRow(day: DailySummary, formatter f: WeatherFormatters) -> some View {
        let isExpanded = expandedDay == day.date
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    expandedDay = isExpanded ? nil : day.date
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .frame(width: 10)
                    WeatherCanvas(symbolCode: day.symbolCode)
                        .frame(width: 30, height: 30)
                    Text(dayLabel(day.date))
                        .font(.callout)
                        .lineLimit(1)
                        .frame(width: 60, alignment: .leading)
                    Spacer()
                    Label(f.precip(day.precipitation), systemImage: "drop")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(width: 64, alignment: .trailing)
                        .monospacedDigit()
                    Text("\(f.tempShort(day.minTemp)) / \(f.tempShort(day.maxTemp))")
                        .font(.callout).monospacedDigit()
                        .frame(width: 76, alignment: .trailing)
                }
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))
                .contentShape(Rectangle())
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            if isExpanded {
                expandedDetails(for: day, formatter: f)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    @ViewBuilder
    private func expandedDetails(for day: DailySummary,
                                 formatter f: WeatherFormatters) -> some View {
        let entries = store.hourlyEntries(for: day.date)
        if entries.isEmpty {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 6)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(entries.enumerated()), id: \.element.time) { idx, entry in
                    hourRow(entry: entry, formatter: f)
                    if idx < entries.count - 1 {
                        Divider().opacity(0.3)
                    }
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.18)))
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func hourRow(entry: LocationForecast.TimeSeriesEntry,
                         formatter f: WeatherFormatters) -> some View {
        let inst = entry.data.instant.details
        let symbol = entry.data.next1Hours?.summary?.symbolCode
            ?? entry.data.next6Hours?.summary?.symbolCode
            ?? entry.data.next12Hours?.summary?.symbolCode
        let precip = entry.data.next1Hours?.details?.precipitationAmount
            ?? entry.data.next6Hours?.details?.precipitationAmount
        HStack(spacing: 6) {
            Text(timeLabel(entry.time))
                .font(.caption.weight(.medium))
                .monospacedDigit()
                .frame(width: 44, alignment: .leading)
            WeatherCanvas(symbolCode: symbol)
                .frame(width: 22, height: 22)
            Text(f.tempShort(inst.airTemperature))
                .font(.caption.weight(.semibold))
                .monospacedDigit()
                .frame(width: 40, alignment: .leading)
            Spacer(minLength: 2)
            HStack(spacing: 3) {
                Image(systemName: (precip ?? 0) > 0.05 ? "drop.fill" : "drop")
                Text(f.precip(precip ?? 0))
            }
            .font(.caption2)
            .foregroundStyle(.blue)
            .monospacedDigit()
            .frame(width: 64, alignment: .trailing)
            HStack(spacing: 3) {
                Image(systemName: "wind")
                Text(windText(inst.windSpeed, dir: inst.windFromDirection))
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 2)
    }

    private func windText(_ ms: Double?, dir: Double?) -> String {
        let d = WeatherFormatters.windDirectionLabel(dir)
        guard let v = ms else { return d }
        let n: String
        switch settings.unitSystem {
        case .metric:   n = String(format: "%.0f m/s", v)
        case .imperial: n = String(format: "%.0f mph", v * 2.23694)
        }
        return "\(n) \(d)"
    }

    private func timeLabel(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = L10n.locale
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return L10n.t(.today) }
        if cal.isDateInTomorrow(date) { return L10n.t(.tomorrow) }
        let fmt = DateFormatter(); fmt.locale = L10n.locale; fmt.dateFormat = "EEE"
        return fmt.string(from: date).capitalized
    }
}
