import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings
    @Environment(\.openSettings) private var openSettings
    @State private var tab: Tab = .now

    enum Tab: String, CaseIterable { case now, forecast }

    var body: some View {
        ZStack(alignment: .top) {
            // Let the Now-tab sky bleed to edges by drawing it behind everything.
            if tab == .now {
                SkyBackground(symbolCode: store.currentSymbolCode)
                    .ignoresSafeArea()
                // Slight darkening at top so the header stays legible on bright skies.
                LinearGradient(
                    colors: [.black.opacity(0.18), .clear],
                    startPoint: .top, endPoint: .bottom)
                    .frame(height: 70)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top)
            }
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.locationName)
                            .font(.headline)
                            .foregroundStyle(tab == .now ? .white : .primary)
                        if let date = store.fetchedAt {
                            Text("\(L10n.t(.updatedAgo)) \(date, style: .relative)")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(tab == .now ? .white : .secondary)
                        }
                    }
                    Spacer()
                    Button {
                        store.refreshIfNeeded(force: true)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(tab == .now ? .white : .primary)
                    }
                    .buttonStyle(.borderless)
                    .help(L10n.t(.refresh))
                    .disabled(store.isLoading)
                }
                .shadow(color: tab == .now ? .black.opacity(0.4) : .clear, radius: 2, y: 1)
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { t in
                        Text(t == .now ? L10n.t(.now) : L10n.t(.sevenDay)).tag(t)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 14)

                Group {
                    switch tab {
                    case .now: CurrentWeatherView()
                    case .forecast: ForecastView().padding(.horizontal, 14)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if let err = store.errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red).lineLimit(2)
                        .padding(.horizontal, 14)
                }

                HStack {
                    Button {
                        openSettingsWindow()
                    } label: {
                        Label(L10n.t(.settings), systemImage: "gear")
                            .foregroundStyle(tab == .now ? .white : .primary)
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Button(L10n.t(.quit)) { NSApp.terminate(nil) }
                        .buttonStyle(.borderless)
                        .foregroundStyle(tab == .now ? .white : .primary)
                }
                .font(.callout.weight(.medium))
                .shadow(color: tab == .now ? .black.opacity(0.4) : .clear, radius: 2, y: 1)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    /// Opens the Settings scene reliably from a `MenuBarExtra` in an accessory
    /// app (`LSUIElement`). `SettingsLink` is unreliable in that context on
    /// macOS 14/15, so we trigger the standard AppKit selector after bringing
    /// the app forward.
    private func openSettingsWindow() {
        // Use the SwiftUI environment action — this is the only reliable way
        // to open the `Settings` scene from a `MenuBarExtra` popover in an
        // `LSUIElement` app. `SettingsLink` is broken in that context.
        openSettings()

        // The popover is dismissed when the button is tapped, which can leave
        // the Settings window hidden behind other apps. Bring the app forward,
        // then poll for the Settings window: SwiftUI instantiates it
        // asynchronously, so the exact moment it appears is timing-dependent.
        // Polling a few times avoids racing a single fixed delay.
        NSApp.activate(ignoringOtherApps: true)
        frontSettingsWindow(attemptsRemaining: 10)
    }

    /// Brings the first eligible Settings window to the front, retrying on the
    /// main runloop until it has been instantiated by SwiftUI (or attempts run
    /// out). Stops after fronting a single window so we never disturb other
    /// app windows.
    private func frontSettingsWindow(attemptsRemaining: Int) {
        // The `Settings` scene exposes no public window identifier, so we
        // heuristically pick the first non-panel window that can become key
        // and already has its content view controller wired up.
        if let window = NSApp.windows.first(where: { window in
            window.canBecomeKey
                && !(window is NSPanel)
                && window.contentViewController != nil
        }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        guard attemptsRemaining > 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            frontSettingsWindow(attemptsRemaining: attemptsRemaining - 1)
        }
    }
}
