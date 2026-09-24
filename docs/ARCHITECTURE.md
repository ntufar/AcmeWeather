# Architecture

Acme Weather is a pure SwiftUI app (iOS 17+) with no third-party dependencies. It uses the Observation framework, async/await, and MapKit.

## Big picture

```
            ┌─────────────────────────── AppState (@Observable) ───────────────────────────┐
            │ weather · alerts · storms · radarFrames · placeSelection · demoMode         │
            │                                                                              │
            │ LocationManager   NotificationManager   OutageStore   EmergencyKitStore   FamilyPlanStore
            └───────▲───────────────────────▲────────────────────────▲──────────────────────┘
                    │ protocols             │                        │ environment
  ┌─────────────────┴───────────┐           │           ┌────────────┴────────────┐
  │ WeatherProviding  (Open-Meteo)│          │           │  NowView  RadarView      │
  │ AlertProviding    (NWS)       │          │           │  AlertsView  Tropics     │
  │ HurricaneProviding (NHC)      │          │           │  SafetyHubView …         │
  │ RadarProviding    (RainViewer)│          │           └─────────────────────────┘
  └───────────────────────────────┘          │
                                   UNUserNotificationCenter
```

- **`AppState`** (`App/AppState.swift`) is the single source of truth. `AcmeWeatherApp` creates it and injects it with `.environment(_:)`. It owns the services and sub-stores, and runs refreshes: `refreshAll()` fetches weather, alerts, storms and radar concurrently with `async let`.
- **Services** sit behind small protocols (`WeatherProviding`, `AlertProviding`, `HurricaneProviding`, `RadarProviding`). `AppState.init` takes them as parameters, so tests or previews can inject fakes.
- **Parsers** are pure static functions (`NWSAlertParser.parse`, `NHCParser.parse`, `OpenMeteoResponse.snapshot`, `RainViewerService.parse`) and are unit-tested against JSON fixtures.
- **Local stores** (`OutageStore`, `EmergencyKitStore`, `FamilyPlanStore`) persist small Codable values as JSON in `UserDefaults` through `Storage`.

## Concurrency

The app target uses Xcode 26's **default MainActor isolation** (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) plus *approachable concurrency*, in Swift 5 language mode. UI state, stores and services all live on the main actor. Network calls suspend with `URLSession`'s async APIs and JSON payloads are small, so this keeps the code simple with no data races. The few delegate callbacks from system frameworks (`CLLocationManagerDelegate`, `UNUserNotificationCenterDelegate`) are marked `nonisolated` and hop back to the main actor explicitly.

## Resilience & offline behavior

| Failure | Behavior |
| --- | --- |
| Forecast request fails | Shows `SampleData.weather()` with an "Offline — showing sample data" label; the next successful refresh replaces it. |
| NWS alerts fail | Keeps the last live alerts and shows an inline error. |
| NHC fails | Keeps the last live storms and shows an inline error. |
| Radar manifest fails | The radar layer is hidden and the header shows "Radar unavailable". |
| Location denied / outside GA | Falls back to Atlanta or a chosen city; the header says so. |

Data refreshes on launch, on pull-to-refresh, when the user moves more than about 1.5 miles, and when the app returns to the foreground after more than 10 minutes.

## The radar map

SwiftUI's `Map` can't draw tile overlays, so `Features/Radar/WeatherMapView.swift` wraps `MKMapView` in a `UIViewRepresentable`:

- **Radar animation.** All radar frames (10 past plus nowcast) are added once as `MKTileOverlay`s. Playback just sets each renderer's `alpha` so that only the current frame is visible. Once tiles are cached, looping is smooth and makes no network requests.
- **Diffing.** The coordinator keeps a string "signature" for each layer (radar, alerts, storms, outages) and rebuilds a layer only when its signature changes. `updateUIView` is cheap to call on every SwiftUI update.
- **Camera commands.** Zoom in/out, "my location" and "all of Georgia" are sent as `CameraCommand` values that carry a fresh `UUID`. The coordinator applies each command exactly once.
- **Hit testing.** A simultaneous tap recognizer checks taps against each `MKPolygonRenderer.path`, so tapping a warning polygon opens that alert.
- **Hurricanes.** `ConeBuilder` builds a cone-of-uncertainty polygon. It offsets each forecast point perpendicular to the direction of travel by a radius that grows along the track, then caps both ends with arcs. The storm marker is a custom `MKAnnotationView` with a spinning hurricane glyph.

Detail screens (alert detail, storm detail, tropics overview) use SwiftUI `Map` with `MapPolygon` and `MapPolyline`. `StormMapContent` is shared `MapContent`.

## Design system

- `Design/Theme.swift` holds the brand colors: peach, navy, pine, sky, danger. It also has `glassCard()`, a frosted `.ultraThinMaterial` card, and `appBackground()`.
- `Design/WeatherBackground.swift` is a `TimelineView(.animation)` + `Canvas` renderer. It draws a gradient sky, drifting blurred clouds, rain streaks, snowflakes, twinkling stars, a pulsing sun and lightning. It uses deterministic pseudo-random seeds, so it allocates nothing per frame.
- The app is dark-mode only (`UIUserInterfaceStyle = Dark`) for a consistent, cinematic look.

## Project file

`AcmeWeather.xcodeproj` uses **file-system-synchronized groups**. Any file you add under `AcmeWeather/` or `AcmeWeatherTests/` is picked up automatically, and you never need to edit `project.pbxproj` to add sources. Info.plist values are generated from build settings (`INFOPLIST_KEY_*`), including the location and camera usage descriptions.

## Testing

`AcmeWeatherTests` uses **Swift Testing** (`import Testing`):

- `ParsingTests.swift` tests NWS (Polygon, MultiPolygon, null geometry, missing fields), Open-Meteo (null values, time windowing), NHC (mixed string and number fields, Atlantic filter, knots→mph) and RainViewer.
- `ModelTests.swift` tests WMO code mapping, Saffir-Simpson thresholds, cone geometry, alert ordering, hazard classification, outage stage simulation, family plan completion and geography helpers.

Run them with ⌘U or `xcodebuild test` (see README).
