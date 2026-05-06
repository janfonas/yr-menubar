import SwiftUI

@main
struct YrMenuBarApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var location = LocationProvider()
    @StateObject private var store = WeatherStore()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(settings)
                .environmentObject(location)
                .environmentObject(store)
                .frame(width: 360, height: 540)
                .onAppear {
                    store.configure(settings: settings, location: location)
                    store.refreshIfNeeded()
                }
        } label: {
            MenuBarLabel()
                .environmentObject(store)
                .environmentObject(settings)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(location)
                .environmentObject(store)
                .frame(width: 460)
        }
    }
}

struct MenuBarLabel: View {
    @EnvironmentObject var store: WeatherStore

    var body: some View {
        let symbol = store.currentSymbolCode
        Image(systemName: SFSymbol.from(symbolCode: symbol))
    }
}
