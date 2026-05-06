import SwiftUI
import CoreLocation

struct SettingsView: View {
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var location: LocationProvider
    @EnvironmentObject var store: WeatherStore

    @State private var searchQuery: String = ""
    @State private var searchError: String?
    @State private var launchAtLogin: Bool = false

    var body: some View {
        Form {
            Section("Location") {
                Toggle("Use current location", isOn: Binding(
                    get: { settings.useGeoLocation },
                    set: { newValue in
                        settings.useGeoLocation = newValue
                        if newValue { location.requestLocation() }
                        store.updateLocationName()
                        store.refreshIfNeeded(force: true)
                    }))

                if settings.useGeoLocation {
                    HStack {
                        Text("Authorization:")
                        Text(authText).foregroundStyle(.secondary)
                        Spacer()
                        if location.authorizationStatus == .notDetermined {
                            Button("Request access") { location.requestAuthorization() }
                        }
                    }
                }

                Divider()
                Text("Fallback location").font(.caption).foregroundStyle(.secondary)
                HStack {
                    TextField("Search city…", text: $searchQuery, onCommit: search)
                    Button("Search", action: search).disabled(searchQuery.isEmpty)
                }
                if let e = searchError {
                    Text(e).font(.caption).foregroundStyle(.red)
                }

                HStack {
                    TextField("Name", text: Binding(get: { settings.fallbackName }, set: { settings.fallbackName = $0 }))
                    TextField("Lat", value: Binding(get: { settings.fallbackLatitude }, set: { settings.fallbackLatitude = $0 }), format: .number)
                        .frame(width: 80)
                    TextField("Lon", value: Binding(get: { settings.fallbackLongitude }, set: { settings.fallbackLongitude = $0 }), format: .number)
                        .frame(width: 80)
                }
            }

            Section("Units") {
                Picker("Units", selection: Binding(
                    get: { settings.unitSystem },
                    set: { settings.unitSystem = $0 })) {
                    ForEach(UnitSystem.allCases) { u in Text(u.label).tag(u) }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { launchAtLogin },
                    set: { newValue in
                        launchAtLogin = newValue
                        settings.launchAtLogin = newValue
                    }))
            }
        }
        .padding()
        .onAppear {
            launchAtLogin = settings.launchAtLogin
        }
    }

    private var authText: String {
        switch location.authorizationStatus {
        case .notDetermined: return "Not determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways, .authorized: return "Authorized"
        @unknown default: return "Unknown"
        }
    }

    private func search() {
        searchError = nil
        let q = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        CLGeocoder().geocodeAddressString(q) { placemarks, error in
            if let error = error {
                DispatchQueue.main.async { searchError = error.localizedDescription }
                return
            }
            guard let p = placemarks?.first, let loc = p.location else {
                DispatchQueue.main.async { searchError = "No results" }
                return
            }
            DispatchQueue.main.async {
                settings.fallbackLatitude = loc.coordinate.latitude
                settings.fallbackLongitude = loc.coordinate.longitude
                settings.fallbackName = p.locality ?? p.name ?? q
                store.updateLocationName()
                store.refreshIfNeeded(force: true)
            }
        }
    }
}
