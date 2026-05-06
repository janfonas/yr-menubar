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
        if alerts.alerts.isEmpty {
            // Plain SF Symbol \u2014 macOS will render it as a template so it
            // adapts to the menu-bar tint (light/dark, focused/unfocused).
            Image(systemName: SFSymbol.from(symbolCode: symbol))
        } else {
            // When alerts are present we want a *coloured* badge, which means
            // bypassing the template treatment. We render a SwiftUI ZStack to
            // an NSImage with isTemplate=false so the red `!` survives.
            if let nsImage = Self.renderBadge(weatherSymbol: SFSymbol.from(symbolCode: symbol),
                                              tint: alertBadgeColor(rank: alerts.worstSeverityRank)) {
                Image(nsImage: nsImage)
            } else {
                Image(systemName: SFSymbol.from(symbolCode: symbol))
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

    @MainActor
    private static func renderBadge(weatherSymbol: String, tint: Color) -> NSImage? {
        let view = ZStack(alignment: .topTrailing) {
            // Weather symbol in the menu-bar's "label" colour (matches what
            // template rendering would give us on most macOS appearances).
            Image(systemName: weatherSymbol)
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color(NSColor.labelColor))
                .font(.system(size: 16, weight: .regular))
                .frame(width: 22, height: 18, alignment: .center)
            // A bold red `!` badge in the top-right corner.
            Image(systemName: "exclamationmark.circle.fill")
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, tint)
                .font(.system(size: 11, weight: .black))
                .offset(x: 4, y: -3)
        }
        .frame(width: 26, height: 18)

        let renderer = ImageRenderer(content: view)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        guard let nsImage = renderer.nsImage else { return nil }
        nsImage.isTemplate = false
        return nsImage
    }
}
