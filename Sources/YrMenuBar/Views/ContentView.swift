import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings
    @State private var tab: Tab = .now

    enum Tab: String, CaseIterable { case now, forecast }

    var body: some View {
        ZStack(alignment: .top) {
            // Let the Now-tab sky bleed to edges by drawing it behind everything.
            if tab == .now {
                SkyBackground(symbolCode: store.currentSymbolCode)
                    .ignoresSafeArea()
            }
            VStack(spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.locationName)
                            .font(.headline)
                            .foregroundStyle(tab == .now ? .white : .primary)
                        if let date = store.fetchedAt {
                            Text("\(L10n.t(.updatedAgo)) \(date, style: .relative)")
                                .font(.caption2)
                                .foregroundStyle(tab == .now ? .white.opacity(0.8) : .secondary)
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

                if let err = store.errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red).lineLimit(2)
                        .padding(.horizontal, 14)
                }

                HStack {
                    SettingsLink {
                        Label(L10n.t(.settings), systemImage: "gear")
                            .foregroundStyle(tab == .now ? .white : .primary)
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    Button(L10n.t(.quit)) { NSApp.terminate(nil) }
                        .buttonStyle(.borderless)
                        .foregroundStyle(tab == .now ? .white : .primary)
                }
                .font(.callout)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
    }
}
