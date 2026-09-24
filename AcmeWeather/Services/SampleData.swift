import Foundation

/// Offline fallback and Demo Mode data. Everything here is fictional.
enum SampleData {
    static func weather(now: Date = .now) -> WeatherSnapshot {
        let calendar = Calendar.current
        let hourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? now
        let hours = (0..<24).map { i -> HourlyForecast in
            let time = hourStart.addingTimeInterval(Double(i) * 3600)
            let hour = calendar.component(.hour, from: time)
            let temp = 78 + 10 * sin(Double(hour - 9) / 24 * 2 * .pi)
            let stormy = (15...18).contains(hour)
            return HourlyForecast(
                time: time, temperature: temp,
                precipitationChance: stormy ? 60 : 10,
                weatherCode: stormy ? 95 : (hour > 11 ? 2 : 1),
                isDay: (7...19).contains(hour)
            )
        }
        let codes = [95, 2, 1, 61, 3, 0, 80]
        let days = (0..<7).map { i -> DailyForecast in
            let date = calendar.startOfDay(for: now).addingTimeInterval(Double(i) * 86400)
            return DailyForecast(
                date: date, high: 88 - Double(i % 3) * 3, low: 69 - Double(i % 2) * 2,
                precipitationChance: [60, 20, 10, 50, 30, 0, 40][i], weatherCode: codes[i],
                sunrise: date.addingTimeInterval(7 * 3600 + 15 * 60),
                sunset: date.addingTimeInterval(19 * 3600 + 30 * 60),
                uvIndexMax: 8
            )
        }
        let current = CurrentConditions(
            temperature: 84, apparentTemperature: 91, humidity: 68, dewPoint: 72,
            windSpeed: 8, windGust: 17, windDirection: 225, pressureHPa: 1014,
            precipitation: 0, uvIndex: 7, weatherCode: 2,
            isDay: (7...19).contains(calendar.component(.hour, from: now))
        )
        return WeatherSnapshot(current: current, hourly: hours, daily: days, fetchedAt: now)
    }

    static func demoAlerts(now: Date = .now) -> [WeatherAlert] {
        [
            WeatherAlert(
                id: "demo-tornado-warning", event: "Tornado Warning",
                headline: "Tornado Warning issued for Bibb and Jones Counties until 45 minutes from now",
                description: "At this time, a severe thunderstorm capable of producing a tornado was located near Macon, moving northeast at 35 mph.\n\nHAZARD...Tornado.\nSOURCE...Radar indicated rotation.\nIMPACT...Flying debris will be dangerous to those caught without shelter. Mobile homes will be damaged or destroyed.",
                instruction: "TAKE COVER NOW! Move to a basement or an interior room on the lowest floor of a sturdy building. Avoid windows. If you are outdoors, in a mobile home, or in a vehicle, move to the closest substantial shelter and protect yourself from flying debris.",
                severity: .extreme, urgency: "Immediate", certainty: "Observed",
                areaDescription: "Bibb, GA; Jones, GA",
                effective: now.addingTimeInterval(-300), expires: now.addingTimeInterval(45 * 60),
                sender: "NWS Peachtree City GA (Demo)",
                polygons: [[Coordinate(32.78, -83.78), Coordinate(32.96, -83.80), Coordinate(33.06, -83.50), Coordinate(32.86, -83.44)]],
                isDemo: true
            ),
            WeatherAlert(
                id: "demo-hurricane-warning", event: "Hurricane Warning",
                headline: "Hurricane Warning for the Georgia coast — Hurricane Magnolia (Demo)",
                description: "Hurricane conditions are expected within the warning area. Life-threatening storm surge of 6 to 9 feet above ground is possible along the coast, with damaging winds and flooding rain spreading inland.",
                instruction: "Complete preparations to protect life and property. Follow evacuation orders from local officials. Do not return to evacuated areas until officials say it is safe.",
                severity: .extreme, urgency: "Expected", certainty: "Likely",
                areaDescription: "Coastal Chatham, Bryan, Liberty, McIntosh, Glynn and Camden, GA",
                effective: now.addingTimeInterval(-3600), expires: now.addingTimeInterval(48 * 3600),
                sender: "NWS Charleston SC (Demo)",
                polygons: [[Coordinate(32.10, -81.20), Coordinate(32.05, -80.82), Coordinate(31.30, -81.15),
                            Coordinate(30.70, -81.38), Coordinate(30.72, -81.75), Coordinate(31.40, -81.62)]],
                isDemo: true
            ),
            WeatherAlert(
                id: "demo-flood-watch", event: "Flood Watch",
                headline: "Flood Watch for southeast Georgia through Saturday evening",
                description: "Heavy rainfall of 6 to 10 inches with locally higher amounts may cause flash flooding of rivers, creeks, streams and low-lying areas.",
                instruction: "Monitor later forecasts and be alert for possible flood warnings. Have a plan to reach higher ground.",
                severity: .moderate, urgency: "Future", certainty: "Possible",
                areaDescription: "Effingham, Bulloch, Evans, Tattnall, Long, Wayne, GA",
                effective: now, expires: now.addingTimeInterval(60 * 3600),
                sender: "NWS Charleston SC (Demo)",
                polygons: [[Coordinate(32.55, -81.95), Coordinate(32.50, -81.30), Coordinate(31.55, -81.60), Coordinate(31.60, -82.20)]],
                isDemo: true
            ),
            WeatherAlert(
                id: "demo-heat-advisory", event: "Heat Advisory",
                headline: "Heat Advisory — heat index values up to 108 expected",
                description: "Heat index values up to 108 expected this afternoon. Hot temperatures and high humidity may cause heat illnesses.",
                instruction: "Drink plenty of fluids, stay in an air-conditioned room, stay out of the sun, and check up on relatives and neighbors.",
                severity: .minor, urgency: "Expected", certainty: "Likely",
                areaDescription: "Dougherty, Lee, Worth, Mitchell, GA",
                effective: now, expires: now.addingTimeInterval(9 * 3600),
                sender: "NWS Tallahassee FL (Demo)",
                polygons: [],
                isDemo: true
            ),
        ]
    }

    static func demoHurricane(now: Date = .now) -> Storm {
        let track: [TrackPoint] = [
            TrackPoint(hoursFromNow: 0, coordinate: Coordinate(25.8, -76.2), windMph: 115),
            TrackPoint(hoursFromNow: 12, coordinate: Coordinate(27.3, -78.0), windMph: 125),
            TrackPoint(hoursFromNow: 24, coordinate: Coordinate(28.9, -79.4), windMph: 125),
            TrackPoint(hoursFromNow: 36, coordinate: Coordinate(30.4, -80.4), windMph: 120),
            TrackPoint(hoursFromNow: 48, coordinate: Coordinate(31.6, -81.1), windMph: 110),
            TrackPoint(hoursFromNow: 72, coordinate: Coordinate(33.2, -82.2), windMph: 60),
            TrackPoint(hoursFromNow: 96, coordinate: Coordinate(35.0, -82.8), windMph: 35),
        ]
        return Storm(
            id: "demo-magnolia", name: "Magnolia", classification: "HU",
            windMph: 115, pressureMb: 958, position: track[0].coordinate,
            movementDegrees: 320, movementMph: 12, lastUpdate: now.addingTimeInterval(-40 * 60),
            advisoryURL: URL(string: "https://www.nhc.noaa.gov"),
            forecastTrack: track, isDemo: true
        )
    }

    static func countyOutages() -> [CountyOutage] {
        [
            CountyOutage(county: "Chatham", customersOut: 12_480, customersServed: 145_000, coordinate: Coordinate(32.08, -81.09)),
            CountyOutage(county: "Glynn", customersOut: 6_210, customersServed: 45_000, coordinate: Coordinate(31.15, -81.49)),
            CountyOutage(county: "Liberty", customersOut: 4_320, customersServed: 30_000, coordinate: Coordinate(31.85, -81.60)),
            CountyOutage(county: "Camden", customersOut: 3_950, customersServed: 26_000, coordinate: Coordinate(30.97, -81.72)),
            CountyOutage(county: "Bryan", customersOut: 2_870, customersServed: 20_000, coordinate: Coordinate(32.14, -81.62)),
            CountyOutage(county: "Bibb", customersOut: 2_110, customersServed: 75_000, coordinate: Coordinate(32.84, -83.63)),
            CountyOutage(county: "Fulton", customersOut: 1_340, customersServed: 480_000, coordinate: Coordinate(33.75, -84.39)),
            CountyOutage(county: "Lowndes", customersOut: 1_120, customersServed: 55_000, coordinate: Coordinate(30.83, -83.28)),
            CountyOutage(county: "DeKalb", customersOut: 980, customersServed: 340_000, coordinate: Coordinate(33.77, -84.30)),
            CountyOutage(county: "Richmond", customersOut: 740, customersServed: 95_000, coordinate: Coordinate(33.47, -82.01)),
        ]
    }
}
