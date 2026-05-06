# YrMenuBar

A small macOS menu-bar app that shows current weather and a 7-day forecast from
[yr.no](https://yr.no) (Norwegian Meteorological Institute) using the public
[`api.met.no`](https://api.met.no/weatherapi/locationforecast/2.0/documentation) service.

- SwiftUI `MenuBarExtra` (macOS 14+, Sonoma)
- Custom Canvas-rendered weather illustrations (sun, clouds, rain, snow, thunder, fog)
- Geo-location via CoreLocation, with a configurable fallback location
- Metric / imperial units
- "Launch at login" toggle (`SMAppService`)
- No tracking, no analytics, no API key needed
- Local on-disk forecast cache that respects met.no `Last-Modified` / `Expires` headers

## Build locally

Requires either Xcode 15+ or Apple Command Line Tools with Swift 5.9+.

```bash
swift test
./scripts/build-app.sh 0.0.0-dev
open dist/YrMenuBar.app
```

The build script assembles a proper `.app` bundle (Info.plist with `LSUIElement`),
ad-hoc-codesigns it so Gatekeeper accepts after a right-click → Open.

## Install a release

1. Download `YrMenuBar-<version>.dmg` from the [Releases](https://github.com/janfonas/yr-menubar/releases) page.
2. Open the DMG and drag `YrMenuBar.app` into `/Applications`.
3. **First launch:** right-click `YrMenuBar.app` → **Open** → confirm. macOS only requires this
   the first time, because the build is unsigned (no paid Apple Developer account).
4. Grant location permission when prompted (or set a fallback location in Settings).

## Settings

Open the menu-bar popover → **Settings…**:
- **Location** — toggle current location, or pick a fallback by city search.
- **Units** — metric (°C, m/s, mm) or imperial (°F, mph, in).
- **Startup** — Launch at login.

## Releasing

Tag and push to publish a build:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The `Release` workflow builds a universal binary, packages a `.dmg` and `.zip`,
and attaches them to a new GitHub Release.

## Attribution

Weather data © [MET Norway](https://www.met.no/en) — used per their
[Terms of Service](https://api.met.no/doc/TermsOfService). All requests send a
descriptive `User-Agent` header as required.

## License

MIT — see [LICENSE](LICENSE).
