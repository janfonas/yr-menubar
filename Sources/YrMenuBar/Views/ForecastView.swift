import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let f = WeatherFormatters(units: settings.unitSystem)
        let days = store.dailySummaries(days: 7)
        ScrollView {
            VStack(spacing: 2) {
                ForEach(days) { day in
                    HStack(spacing: 8) {
                        WeatherCanvas(symbolCode: day.symbolCode)
                            .frame(width: 30, height: 30)
                        Text(dayLabel(day.date))
                            .font(.callout)
                            .lineLimit(1)
                            .frame(width: 70, alignment: .leading)
                        Spacer()
                        Label(f.precip(day.precipitation), systemImage: "drop")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 70, alignment: .trailing)
                            .monospacedDigit()
                        Text("\(f.tempShort(day.minTemp)) / \(f.tempShort(day.maxTemp))")
                            .font(.callout).monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.3)))
                }
            }
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return L10n.t(.today) }
        if cal.isDateInTomorrow(date) { return L10n.t(.tomorrow) }
        let fmt = DateFormatter(); fmt.locale = L10n.locale; fmt.dateFormat = "EEE"
        return fmt.string(from: date).capitalized
    }
}
