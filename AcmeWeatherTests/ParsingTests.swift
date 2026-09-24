import Foundation
import Testing
@testable import AcmeWeather

@MainActor
struct NWSAlertParsingTests {
    let json = """
    {
      "features": [
        {
          "id": "https://api.weather.gov/alerts/urn:1",
          "geometry": {
            "type": "Polygon",
            "coordinates": [[[-83.8, 32.8], [-83.5, 33.0], [-83.4, 32.8], [-83.8, 32.8]]]
          },
          "properties": {
            "id": "urn:1",
            "event": "Tornado Warning",
            "headline": "Tornado Warning issued for Bibb County",
            "description": "Radar indicated rotation.",
            "instruction": "TAKE COVER NOW!",
            "severity": "Extreme",
            "urgency": "Immediate",
            "certainty": "Observed",
            "areaDesc": "Bibb, GA",
            "effective": "2026-09-25T14:00:00-04:00",
            "expires": "2026-09-25T14:45:00-04:00",
            "senderName": "NWS Peachtree City GA"
          }
        },
        {
          "id": "urn:2",
          "geometry": null,
          "properties": {
            "event": "Heat Advisory",
            "severity": "Minor",
            "areaDesc": "Dougherty, GA"
          }
        },
        {
          "id": "urn:3",
          "geometry": {
            "type": "MultiPolygon",
            "coordinates": [
              [[[-81.2, 32.1], [-80.8, 32.0], [-81.1, 31.5], [-81.2, 32.1]]],
              [[[-81.5, 31.2], [-81.3, 31.1], [-81.4, 30.9], [-81.5, 31.2]]]
            ]
          },
          "properties": { "event": "Storm Surge Warning", "severity": "Severe" }
        },
        { "id": "urn:4", "geometry": null, "properties": { "headline": "no event" } }
      ]
    }
    """.data(using: .utf8)!

    @Test func parsesFeatures() throws {
        let alerts = try NWSAlertParser.parse(json)
        #expect(alerts.count == 3)

        let tornado = try #require(alerts.first { $0.event == "Tornado Warning" })
        #expect(tornado.id == "urn:1")
        #expect(tornado.severity == .extreme)
        #expect(tornado.kind == .tornado)
        #expect(tornado.polygons.count == 1)
        #expect(tornado.polygons[0].first == Coordinate(32.8, -83.8))
        #expect(tornado.expires != nil)
    }

    @Test func handlesMissingGeometryAndFields() throws {
        let heat = try #require(try NWSAlertParser.parse(json).first { $0.event == "Heat Advisory" })
        #expect(heat.polygons.isEmpty)
        #expect(heat.headline == "Heat Advisory")
        #expect(heat.severity == .minor)
    }

    @Test func keepsEveryPolygonOfAMultiPolygon() throws {
        let surge = try #require(try NWSAlertParser.parse(json).first { $0.event == "Storm Surge Warning" })
        #expect(surge.polygons.count == 2)
        #expect(surge.kind == .tropical)
    }
}

@MainActor
struct OpenMeteoParsingTests {
    @Test func buildsSnapshot() throws {
        let json = """
        {
          "utc_offset_seconds": -14400,
          "current": {
            "time": "2026-09-25T14:00", "temperature_2m": 86.4, "relative_humidity_2m": 62,
            "apparent_temperature": 92.1, "is_day": 1, "precipitation": 0, "weather_code": 2,
            "pressure_msl": 1015.2, "wind_speed_10m": 7.5, "wind_direction_10m": 210,
            "wind_gusts_10m": 15.1, "uv_index": 6.2, "dew_point_2m": 71.3
          },
          "hourly": {
            "time": ["2026-09-25T13:00", "2026-09-25T14:00", "2026-09-25T15:00"],
            "temperature_2m": [85.0, 86.4, null],
            "precipitation_probability": [0, 10, 40],
            "weather_code": [1, 2, 95],
            "is_day": [1, 1, 1]
          },
          "daily": {
            "time": ["2026-09-25", "2026-09-26"],
            "weather_code": [95, 1],
            "temperature_2m_max": [89.0, 87.0],
            "temperature_2m_min": [70.0, 68.0],
            "precipitation_probability_max": [60, 5],
            "sunrise": ["2026-09-25T07:22", "2026-09-26T07:23"],
            "sunset": ["2026-09-25T19:24", "2026-09-26T19:23"],
            "uv_index_max": [7.1, 7.4]
          }
        }
        """.data(using: .utf8)!

        let response = try OpenMeteoResponse.decode(json)
        let now = try #require(ISODate.parse("2026-09-25T17:30:00Z")) // 13:30 EDT
        let snapshot = response.snapshot(now: now)

        #expect(snapshot.current.temperature == 86.4)
        #expect(snapshot.current.condition == .partlyCloudy)
        #expect(snapshot.current.isDay)
        // The 15:00 hour has a null temperature and is skipped.
        #expect(snapshot.hourly.count == 2)
        #expect(snapshot.daily.count == 2)
        #expect(snapshot.daily[0].condition == .thunderstorm)
        #expect(snapshot.daily[0].sunrise != nil)
    }
}

@MainActor
struct NHCParsingTests {
    @Test func parsesMixedNumericFormatsAndFiltersToAtlantic() throws {
        let json = """
        {
          "activeStorms": [
            {
              "id": "al092026", "name": "Ida", "classification": "HU",
              "intensity": "100", "pressure": "962",
              "latitudeNumeric": 27.5, "longitudeNumeric": -79.1,
              "movementDir": 330, "movementSpeed": 11,
              "lastUpdate": "2026-09-25T15:00:00.000Z",
              "publicAdvisory": { "url": "https://www.nhc.noaa.gov/text/example.shtml" }
            },
            {
              "id": "ep142026", "name": "Pacific", "classification": "TS",
              "intensity": 45, "latitudeNumeric": 15.0, "longitudeNumeric": -110.0
            }
          ]
        }
        """.data(using: .utf8)!

        let storms = try NHCParser.parse(json)
        #expect(storms.count == 1)
        let ida = try #require(storms.first)
        #expect(ida.windMph == 115) // 100 kt ≈ 115 mph
        #expect(ida.category == .hurricane(4) || ida.category == .hurricane(3))
        #expect(ida.pressureMb == 962)
        #expect(ida.movementText == "NNW at 11 mph")
        #expect(ida.advisoryURL != nil)
        #expect(ida.lastUpdate != nil)
    }
}

@MainActor
struct RainViewerParsingTests {
    @Test func combinesPastAndNowcastFrames() throws {
        let past = (0..<13).map { #"{"time": \#(1_790_000_000 + $0 * 600), "path": "/v2/radar/p\#($0)"}"# }
        let json = """
        {
          "host": "https://tilecache.rainviewer.com",
          "radar": {
            "past": [\(past.joined(separator: ","))],
            "nowcast": [{"time": 1790009000, "path": "/v2/radar/n1"}]
          }
        }
        """.data(using: .utf8)!

        let frames = try RainViewerService.parse(json)
        #expect(frames.count == AppConfig.radarFrameCount + 1)
        #expect(frames.last?.isForecast == true)
        #expect(frames.first?.isForecast == false)
        #expect(frames[0].tileTemplate == "https://tilecache.rainviewer.com/v2/radar/p3/256/{z}/{x}/{y}/2/1_1.png")
    }
}
