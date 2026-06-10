# YrMenuBar — Copilot instructions

A macOS 14+ (Sonoma) menu-bar weather app written in Swift 5.9 / SwiftPM. It
shows current weather, a 7-day forecast, a precipitation nowcast and met.no
weather warnings from the public `api.met.no` service. No API key, no tracking.

## Build, test, run

Requires Xcode 15+ or Apple Command Line Tools with Swift 5.9+.

```bash
swift build -c debug            # compile
swift test                      # full test suite
swift test --filter ForecastDecodingTests          # one test class
swift test --filter ForecastDecodingTests/testName # one test method
./scripts/build-app.sh 0.0.0-dev   # assemble a signed dist/YrMenuBar.app bundle
open dist/YrMenuBar.app
```

`swift build` / `swift run` produce a bare executable — they do **not** create a
launchable `.app`. Use `scripts/build-app.sh` for that: it builds release
(universal when full Xcode is present), substitutes `__VERSION__` / `__BUILD__`
into `Resources/Info.plist`, regenerates `AppIcon.icns` if stale, and codesigns.
Set `CODESIGN_IDENTITY` to a keychain cert name to keep CoreLocation permissions
across rebuilds (ad-hoc signing re-prompts every build). CI runs `swift build -c
debug` then `swift test` on `macos-14`.

## Architecture

The app deliberately mixes AppKit and SwiftUI:

- `YrMenuBarApp` (`@main`) exists only to host an empty `Settings` scene. The
  app is `LSUIElement` (no Dock icon), so the SwiftUI scene is never surfaced.
- `AppDelegate` is the real entry point. It calls `AppContainer.shared.bootstrap()`
  and owns a `StatusItemController` (custom `NSStatusItem` + vibrant `NSPanel`
  popover with the SwiftUI view tree embedded via `NSHostingView`).
- `AppContainer` is the single `@MainActor` owner of the four observable stores
  (`AppSettings`, `LocationProvider`, `WeatherStore`, `AlertsStore`). Stores are
  shared here — **not** as `@StateObject`s — because both the AppKit status item
  and the SwiftUI views need the *same* instances. `bootstrap()` wires stores
  together (`configure(...)`) and kicks off the first fetch.

Layering under `Sources/YrMenuBar/`:
- `Networking/MetNoClient.swift` — an `actor` wrapping all `api.met.no` calls
  (locationforecast, nowcast, metalerts) plus the `ForecastCache` (disk cache in
  Application Support). The only place HTTP happens.
- `Models/` — `Codable` structs decoding met.no JSON (`Forecast`, `Nowcast`,
  `WeatherAlert`). Tests decode the JSON fixtures in `Tests/.../Fixtures/`.
- `State/` — `@MainActor ObservableObject` stores that own app state and drive
  refresh scheduling.
- `Views/` — SwiftUI views, including `Canvas`-rendered weather illustrations
  (`WeatherCanvas`, `SkyBackground`, `PrecipitationChart`, `WindRose`).
- `Util/` — `Constants`, `L10n` localization, formatters, diagnostics, icon.

## Conventions

- **All UI state is `@MainActor`**; networking is an `actor`. Stores hold `weak`
  references to their dependencies (`settings`, `location`) to avoid retain
  cycles. Async fetches use request coalescing (`inFlightFetch`) and key on
  rounded `"lat,lon"` strings.
- **Respect met.no's API etiquette** — it is hard-coded into the client and must
  be preserved: send the descriptive `User-Agent`
  (`YrMenuBar/<version> (https://github.com/janfonas/yr-menubar)`), round
  coordinates to `Constants.coordinateDecimals` (4) decimals, honour
  `If-Modified-Since` / `Last-Modified` / `Expires` headers for refresh timing,
  and poll MetAlerts on its own slower cadence (`alertsRefreshInterval`), not on
  every forecast refresh. HTTP 422/404 from the nowcast means "outside Nordic
  radar coverage" → treat as no data, not an error.
- **Tunable magic numbers live in `Util/Constants.swift`** — add new ones there
  rather than inlining.
- **Localization is in-code, not `.lproj`** — add a `case` to `L10n.Key` and
  provide `en` / `nb` (Norwegian bokmål) strings. There are no string catalogs.
  Resolution falls back System → preferred language → English.
- **Logging** uses `os.Logger` with subsystem `com.janfonas.YrMenuBar` and a
  per-type `category`.
- **Releasing**: push a `v*` tag (`git tag v0.1.0 && git push origin v0.1.0`).
  The `Release` workflow builds a universal binary, packages `.dmg` + `.zip`,
  and attaches them to a GitHub Release. Builds are unsigned (no paid Apple
  account); the README documents the `xattr -dr com.apple.quarantine` workaround.
- **Hidden developer mode**: option-clicking the Settings "Language" header
  enables a persisted toggle that routes MetAlerts to the `metalerts/2.0/example.json`
  endpoint (`useExampleEndpoint`) for previewing the warning UI.
