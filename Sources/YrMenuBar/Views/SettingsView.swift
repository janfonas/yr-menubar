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
            Section(L10n.t(.sectionLocation)) {
                Toggle(L10n.t(.useCurrentLocation), isOn: Binding(
                    get: { settings.useGeoLocation },
                    set: { newValue in
                        settings.useGeoLocation = newValue
                        if newValue { location.requestLocation() }
                        store.updateLocationName()
                        store.refreshIfNeeded(force: true)
                    }))

                if settings.useGeoLocation {
                    HStack {
                        Text(L10n.t(.authorization))
                        Text(authText).foregroundStyle(.secondary)
                        Spacer()
                        if location.authorizationStatus == .notDetermined {
                            Button(L10n.t(.requestAccess)) { location.requestAuthorization() }
                        }
                    }
                }

                Divider()
                Text(L10n.t(.fallbackLocation)).font(.caption).foregroundStyle(.secondary)
                HStack {
                    TextField(L10n.t(.searchCity), text: $searchQuery, onCommit: search)
                    Button(L10n.t(.searchButton), action: search).disabled(searchQuery.isEmpty)
                }
                if let e = searchError {
                    Text(e).font(.caption).foregroundStyle(.red)
                }

                HStack {
                    TextField(L10n.t(.name), text: Binding(get: { settings.fallbackName }, set: { settings.fallbackName = $0 }))
                    TextField(L10n.t(.lat), value: Binding(get: { settings.fallbackLatitude }, set: { settings.fallbackLatitude = $0 }), format: .number)
                        .frame(width: 80)
                    TextField(L10n.t(.lon), value: Binding(get: { settings.fallbackLongitude }, set: { settings.fallbackLongitude = $0 }), format: .number)
                        .frame(width: 80)
                }
            }

            Section(L10n.t(.sectionUnits)) {
                Picker(L10n.t(.unitsLabel), selection: Binding(
                    get: { settings.unitSystem },
                    set: { settings.unitSystem = $0 })) {
                    ForEach(UnitSystem.allCases) { u in
                        Text(u == .metric ? L10n.t(.unitsMetric) : L10n.t(.unitsImperial)).tag(u)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section(L10n.t(.sectionLanguage)) {
                Picker(L10n.t(.language), selection: Binding(
                    get: { settings.language },
                    set: { settings.language = $0 })) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section(L10n.t(.sectionStartup)) {
                Toggle(L10n.t(.launchAtLogin), isOn: Binding(
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
        case .notDetermined: return L10n.t(.authNotDetermined)
        case .restricted: return L10n.t(.authRestricted)
        case .denied: return L10n.t(.authDenied)
        case .authorizedAlways, .authorized: return L10n.t(.authAuthorized)
        @unknown default: return L10n.t(.authUnknown)
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
                DispatchQueue.main.async { searchError = L10n.t(.noResults) }
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
