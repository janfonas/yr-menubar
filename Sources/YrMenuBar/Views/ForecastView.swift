import SwiftUI

struct ForecastView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings

    var body: some View {
        let f = WeatherFormatters(units: settings.unitSystem)
        let days = store.dailySummaries(days: 7)
        ScrollView {
            VStack(spacing: 4) {
                ForEach(days) { day in
                    HStack(spacing: 10) {
                        WeatherCanvas(symbolCode: day.symbolCode)
                            .frame(width: 36, height: 36)
                        Text(dayLabel(day.date))
                            .font(.callout)
                            .frame(width: 56, alignment: .leading)
                        Spacer()
                        Label(f.precip(day.precipitation), systemImage: "drop")
                            .labelStyle(.titleAndIcon)
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 70, alignment: .trailing)
                        Text("\(f.tempShort(day.minTemp)) / \(f.tempShort(day.maxTemp))")
                            .font(.callout).monospacedDigit()
                            .frame(width: 80, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary.opacity(0.3)))
                }
            }
        }
        .frame(maxHeight: 280)
    }

    private func dayLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return L10n.t(.today) }
        if cal.isDateInTomorrow(date) { return L10n.t(.tomorrow) }
        let fmt = DateFormatter(); fmt.locale = L10n.locale; fmt.dateFormat = "EEE"
        return fmt.string(from: date).capitalized
    }
}
