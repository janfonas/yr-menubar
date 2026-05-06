# YrMenuBar

A small macOS menu-bar app that shows current weather, a 7-day forecast and
active weather warnings from [yr.no](https://yr.no) (Norwegian Meteorological
Institute) using the public [`api.met.no`](https://api.met.no/weatherapi/locationforecast/2.0/documentation)
service.

- SwiftUI `MenuBarExtra` (macOS 14+, Sonoma)
- yr.no-style "Now" view with full-bleed animated sky and Canvas-rendered
  weather illustrations (sun, clouds, rain, snow, thunder, fog)
- 90-minute precipitation nowcast (Nordic radar coverage) with a compact
  inline chart
- Wind rose with speed, direction, Beaufort name and units (m/s · mph)
- 7-day forecast with min/max temperature, precipitation totals and
  Norwegian weekday labels
- **Weather warnings** from met.no MetAlerts — coloured `!` overlay on the
  menu-bar icon and a tappable triangle on the Now tab opens a sheet with
  every active warning (severity, area, advice, possible consequences,
  link to yr.no)
- Geo-location via CoreLocation, with a configurable fallback location
  (city search powered by `CLGeocoder`)
- Metric / imperial units, English / Norwegian (bokmål) UI
- "Launch at login" toggle (`SMAppService`)
- Honours the met.no `Last-Modified` / `Expires` headers; coalesces
  concurrent refreshes
- No tracking, no analytics, no API key needed

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
3. **First launch on macOS 15 (Sequoia) or newer** — the build is unsigned (no
   paid Apple Developer account), so Gatekeeper will refuse to open it and
   suggest moving it to the Trash. Don't. Instead:
   1. Click **Done** on the dialog.
   2. Open **System Settings → Privacy & Security**.
   3. Scroll to the bottom — you'll see *"YrMenuBar was blocked to protect your
      Mac"*. Click **Open Anyway**, then confirm with Touch ID / your password.

   On macOS 14 (Sonoma) the old gesture still works: right-click `YrMenuBar.app`
   → **Open** → **Open** in the confirmation dialog.

   Alternative one-liner (any macOS), strips the quarantine flag:

   ```bash
   xattr -dr com.apple.quarantine /Applications/YrMenuBar.app
   ```

4. Grant location permission when prompted (or set a fallback location in Settings).

## Settings

Open the menu-bar popover → **Settings…**:
- **Location** — toggle current location, or pick a fallback by city search.
- **General** — units (metric/imperial), language (System / English / Norsk
  bokmål), Launch at login.

### Hidden developer toggle

Option-click the **Language / Språk** section header to enable a persisted
developer mode. A new **Developer** section appears with a toggle that routes
the MetAlerts feed to `metalerts/2.0/example.json` so you can preview the
warning UI (menu-bar `!` overlay and the alerts sheet) without waiting for
real warnings to be issued.

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
