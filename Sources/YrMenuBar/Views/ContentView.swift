import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings
    @State private var tab: Tab = .now

    enum Tab: String, CaseIterable { case now, forecast }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.locationName).font(.headline)
                    if let date = store.fetchedAt {
                        Text("\(L10n.t(.updatedAgo)) \(date, style: .relative)")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    store.refreshIfNeeded(force: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help(L10n.t(.refresh))
                .disabled(store.isLoading)
            }

            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { t in
                    Text(t == .now ? L10n.t(.now) : L10n.t(.sevenDay)).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Group {
                switch tab {
                case .now: CurrentWeatherView()
                case .forecast: ForecastView()
                }
            }

            if let err = store.errorMessage {
                Text(err).font(.caption).foregroundStyle(.red).lineLimit(2)
            }

            HStack {
                SettingsLink {
                    Label(L10n.t(.settings), systemImage: "gear")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button(L10n.t(.quit)) { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
            .font(.callout)
        }
        .padding(14)
    }
}
