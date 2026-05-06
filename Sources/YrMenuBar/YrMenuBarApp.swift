import SwiftUI

@main
struct YrMenuBarApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var location = LocationProvider()
    @StateObject private var store = WeatherStore()
    @StateObject private var alerts = AlertsStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(settings)
                .environmentObject(location)
                .environmentObject(store)
                .environmentObject(alerts)
                .frame(width: 360, height: 540)
                .onAppear {
                    store.configure(settings: settings, location: location)
                    store.refreshIfNeeded()
                    alerts.configure(settings: settings, location: location)
                    alerts.refresh()
                }
        } label: {
            MenuBarLabel()
                .environmentObject(store)
                .environmentObject(settings)
                .environmentObject(alerts)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(location)
                .environmentObject(store)
                .environmentObject(alerts)
                .frame(width: 460)
        }
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var alerts: AlertsStore

    var body: some View {
        let symbol = store.currentSymbolCode
        // When alerts are present we overlay a small triangle. Using
        // `symbolRenderingMode(.palette)` so the badge keeps its colour even
        // though menu-bar items are otherwise rendered as templates.
        if alerts.alerts.isEmpty {
            Image(systemName: SFSymbol.from(symbolCode: symbol))
        } else {
            HStack(spacing: 2) {
                Image(systemName: SFSymbol.from(symbolCode: symbol))
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .black,
                        alertBadgeColor(rank: alerts.worstSeverityRank)
                    )
            }
        }
    }

    private func alertBadgeColor(rank: Int) -> Color {
        switch rank {
        case 3: return .red
        case 2: return .orange
        default: return Color(red: 0.96, green: 0.80, blue: 0.13)
        }
    }
}
