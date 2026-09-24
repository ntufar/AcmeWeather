# Data Sources

All live data comes from free, key-less public APIs. Endpoints live in `AcmeWeather/Services/`.

| Data | Provider | Endpoint | Notes |
| --- | --- | --- | --- |
| Forecast (current, hourly, 7-day) | [Open-Meteo](https://open-meteo.com) | `api.open-meteo.com/v1/forecast` | Uses NOAA GFS/HRRR over the US. Free for non-commercial use; commercial use requires a paid plan. Attribution: "Weather data by Open-Meteo.com" (CC BY 4.0). |
| Air quality (US AQI) | Open-Meteo Air Quality | `air-quality-api.open-meteo.com/v1/air-quality` | Same terms as above. |
| Watches, warnings, advisories | [National Weather Service](https://www.weather.gov/documentation/services-web-api) | `api.weather.gov/alerts/active?area=GA` | Public domain. **Requires a `User-Agent` identifying the app and a contact.** Set `AppConfig.nwsUserAgent` before shipping. |
| Active tropical cyclones | [National Hurricane Center](https://www.nhc.noaa.gov) | `www.nhc.noaa.gov/CurrentStorms.json` | Public domain. Gives the current position and intensity only; forecast track and cone geometry are in NHC GIS products (see Roadmap). Filtered to Atlantic (`al…`) storms. |
| Radar mosaic tiles | [RainViewer](https://www.rainviewer.com/api.html) | `api.rainviewer.com/public/weather-maps.json` + `tilecache.rainviewer.com` | Free for personal and small-scale use, with attribution. The free tier caps tile zoom at 7 (`AppConfig.radarMaxZoom`); MapKit upscales beyond that. For production scale, license a commercial radar provider. |

## Simulated / static data

| Data | Where | Status |
| --- | --- | --- |
| Power outage submission & status | `OutageStore`, `OutageStage.simulated` | **Dummy.** Stored on the device only. |
| County outage counts | `SampleData.countyOutages()` | **Dummy**, labeled "DEMO" in the UI. |
| Pollen | `PollenOutlook.estimate()` | Seasonal estimate, labeled "(est.)". |
| Demo hurricane / alerts | `SampleData.demoHurricane()`, `demoAlerts()` | Fictional; shown only in Demo Mode, with a DEMO badge. |
| Coastal evacuation routes | `CoastalCounty.all` | General guidance. **Verify with GEMA/HS and county EMAs before release.** |
| Safety guidance | `SafetyGuide.all`, `KitCategory.all` | Based on NWS, Ready.gov, CDC/USDA guidance. |

## Before release checklist

- [ ] Replace the contact in `AppConfig.nwsUserAgent`.
- [ ] Confirm Open-Meteo and RainViewer licensing for your distribution model, or switch providers.
- [ ] Have emergency management review the evacuation routes and contact list.
- [ ] Add an in-app attribution screen if providers require one beyond Settings ▸ Data sources.
