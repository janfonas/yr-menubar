import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: WeatherStore
    @EnvironmentObject var settings: AppSettings
    @State private var tab: Tab = .now

    enum Tab: String, CaseIterable { case now = "Now"; case forecast = "7-day" }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.locationName).font(.headline)
                    if let date = store.fetchedAt {
                        Text("Updated \(date, style: .relative) ago")
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
                .disabled(store.isLoading)
            }

            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
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
                    Label("Settings…", systemImage: "gear")
                }
                .buttonStyle(.borderless)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
            }
            .font(.callout)
        }
        .padding(14)
    }
}
