# Roadmap

## Replace the dummies

- **Outage reporting backend.** Put `OutageStore.submit` behind an `OutageProviding` protocol (like the weather services) and connect it to a backend or utility partner APIs (Georgia Power, EMCs). Upload photos, send SMS updates through the backend, and get real restoration estimates.
- **Live outage map.** Swap `SampleData.countyOutages()` for a real feed (utility outage maps or aggregators), and draw county choropleths instead of pins.
- **Pollen.** Integrate a real pollen feed. Atlanta Allergy & Asthma publishes the official Atlanta count.

## Hurricanes

- Parse NHC GIS products (forecast cone, track, watches/warnings shapefiles or KMZ) for real storms. Today, live storms show position only and the cone is drawn for Demo Mode.
- Storm surge inundation maps for the Georgia coast.
- Personal evacuation zone lookup by address.

## Alerts

- **Background delivery.** Add `BGAppRefreshTask` polling, or better, a server that watches NWS CAP feeds and sends push notifications. Critical Alerts entitlement for tornado warnings.
- Filter alerts to the user's county/zone using `api.weather.gov/points/{lat},{lon}`.
- Tornado warning "Storm Mode": a full-screen takeover with a countdown and shelter instructions.

## Experience

- Home Screen & Lock Screen **widgets** (WidgetKit), plus a Live Activity for active warnings and landfall countdowns.
- Apple Watch companion with haptic alerts.
- Saved places and multiple locations.
- °C / metric units toggle.
- Radar: lightning strike layer, storm-cell tracks, future radar.
- Localization (Spanish first).
- Accessibility audit: VoiceOver on the map, Dynamic Type across tiles.

## Engineering

- UI tests for the main flows (onboarding, outage report, layer toggles).
- Snapshot tests for the weather backgrounds.
- Response caching for offline launch (last-known forecast).
- CI with GitHub Actions (`xcodebuild test`).
