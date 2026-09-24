# 🍑 Acme Weather — Georgia's Storm Companion

A native SwiftUI iPhone app for Georgia weather. It covers the Blue Ridge down to the Golden Isles and has what Georgians actually need: live radar, NWS warnings, hurricane tracking, power outage reporting, and tools to keep your family safe.

<p align="center"><img src="AcmeWeather/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png" width="160" alt="App icon"></p>

## Highlights

| Tab | What's inside |
| --- | --- |
| **Now** | Animated sky that matches conditions (rain, snow, stars, sun glow, lightning flashes), current conditions, a 24-hour strip, a 7-day forecast with range bars, a **Muggy Meter** 💦, UV, air quality, a pollen estimate, sunrise/sunset. Also a banner for the top active alert and a callout for the nearest storm. |
| **Radar** | Full-screen MapKit map with **animated precipitation radar**, NWS **warning polygons** (tap one for details), **hurricane cones & tracks**, and power outages. Zoom in/out, **jump to my location**, fit all of Georgia, pick a map style, and set radar opacity. |
| **Alerts** | Live NWS watches, warnings and advisories for Georgia, sorted by danger. Includes severity summary, filters, detail pages with polygon maps, a "Take shelter now" card for tornado warnings, sharing, and local notifications. |
| **Tropics** | Active Atlantic storms from the National Hurricane Center, a season progress bar, a forecast-cone map, storm detail with plain-language threat guidance, a prep timeline, an interactive Saffir-Simpson scale, and **Know Your Zone** evacuation routes for all six coastal counties. |
| **Be Ready** | A gamified **Readiness Score**, power outage reporting and tracking *(dummy backend)*, an emergency kit checklist, a family emergency plan (shareable), 7 safety guides, a **flash-to-bang lightning timer**, a **flashlight & Morse SOS**, emergency contacts, and a one-tap **"I'm Safe"** message. |

**Demo Mode** (Settings → Demo Mode, or the Tropics tab) injects a fictional Category 3 *Hurricane Magnolia* aimed at the Georgia coast, plus a tornado warning over Macon, a flood watch, a heat advisory and county outage data. You can show off every feature on a sunny day.

## Requirements

- Xcode 26 or later (the project uses file-system-synchronized groups, `objectVersion 77`)
- iOS 17.0+ deployment target, iPhone only
- An iOS Simulator runtime (install via **Xcode ▸ Settings ▸ Components**) or a device

No API keys, accounts, or third-party packages are required.

## Getting started

```bash
open AcmeWeather.xcodeproj
```

1. Select the **AcmeWeather** scheme and an iPhone simulator.
2. In **Signing & Capabilities**, choose your team (needed only for devices).
3. Run with ⌘R. To test location, use **Features ▸ Location ▸ Custom Location** in the Simulator (e.g. Savannah: `32.0809, -81.0912`).
4. Turn on **Demo Mode** in Settings (gear icon on the Now tab) to see hurricanes, warnings and outages.

Command line:

```bash
xcodebuild -scheme AcmeWeather -destination 'platform=iOS Simulator,name=iPhone 17' build
xcodebuild -scheme AcmeWeather -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Project layout

```
AcmeWeather/
├── App/            App entry, RootView (tabs), AppState (single source of truth), config
├── Design/         Theme, reusable components, animated WeatherBackground
├── Models/         Weather, alerts, storms, outages, radar, geography, safety content
├── Services/       Open-Meteo, NWS, NHC, RainViewer clients; location; notifications; local stores; sample data
├── Features/
│   ├── Now/        Current conditions, forecasts, place picker
│   ├── Radar/      MKMapView wrapper with radar tiles & overlays, radar screen
│   ├── Alerts/     Alert list & detail
│   ├── Hurricanes/ Tropics hub, storm detail, evacuation routes
│   ├── Outages/    Report form & outage center (simulated)
│   ├── Safety/     Hub, kit, family plan, guides, lightning timer, flashlight, contacts
│   ├── Onboarding/ Welcome tour
│   └── Settings/
└── Resources/      Asset catalog (app icon, accent color)
AcmeWeatherTests/   Swift Testing suites for parsers and domain logic
docs/               Architecture, features, data sources, roadmap
scripts/            App icon generator
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md): how the app is put together
- [Features](docs/FEATURES.md): a screen-by-screen tour
- [Data sources](docs/DATA_SOURCES.md): APIs, terms and attribution
- [Roadmap](docs/ROADMAP.md): what's dummy today and what's next

## Disclaimer

Acme Weather is not a substitute for official warnings from the National Weather Service, the National Hurricane Center, GEMA/HS or local officials. **In an emergency, call 911.** Power outage reporting is a simulation: reports stay on the device and are not sent to any utility.
