import SwiftUI

struct WeatherSnapshot {
    var current: CurrentConditions
    var hourly: [HourlyForecast]
    var daily: [DailyForecast]
    var fetchedAt: Date
}

struct CurrentConditions {
    var temperature: Double
    var apparentTemperature: Double
    var humidity: Double
    var dewPoint: Double
    var windSpeed: Double
    var windGust: Double
    var windDirection: Double
    var pressureHPa: Double
    var precipitation: Double
    var uvIndex: Double
    var weatherCode: Int
    var isDay: Bool

    var condition: WeatherCondition { WeatherCondition(wmoCode: weatherCode) }
    var pressureInHg: Double { pressureHPa * 0.02953 }
}

struct HourlyForecast: Identifiable {
    var time: Date
    var temperature: Double
    var precipitationChance: Int
    var weatherCode: Int
    var isDay: Bool

    var id: Date { time }
    var condition: WeatherCondition { WeatherCondition(wmoCode: weatherCode) }
}

struct DailyForecast: Identifiable {
    var date: Date
    var high: Double
    var low: Double
    var precipitationChance: Int
    var weatherCode: Int
    var sunrise: Date?
    var sunset: Date?
    var uvIndexMax: Double

    var id: Date { date }
    var condition: WeatherCondition { WeatherCondition(wmoCode: weatherCode) }
}

enum WeatherParticle: Equatable {
    case rain(heavy: Bool)
    case snow
}

/// Condition buckets derived from WMO weather interpretation codes.
enum WeatherCondition: String, CaseIterable {
    case clear, mostlyClear, partlyCloudy, cloudy, fog, drizzle, rain, heavyRain, freezingRain, snow, thunderstorm

    init(wmoCode: Int) {
        switch wmoCode {
        case 0: self = .clear
        case 1: self = .mostlyClear
        case 2: self = .partlyCloudy
        case 3: self = .cloudy
        case 45, 48: self = .fog
        case 51, 53, 55: self = .drizzle
        case 56, 57, 66, 67: self = .freezingRain
        case 61, 63, 80, 81: self = .rain
        case 65, 82: self = .heavyRain
        case 71, 73, 75, 77, 85, 86: self = .snow
        case 95, 96, 99: self = .thunderstorm
        default: self = .cloudy
        }
    }

    var label: String {
        switch self {
        case .clear: "Clear"
        case .mostlyClear: "Mostly Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .fog: "Foggy"
        case .drizzle: "Drizzle"
        case .rain: "Rain"
        case .heavyRain: "Heavy Rain"
        case .freezingRain: "Freezing Rain"
        case .snow: "Snow"
        case .thunderstorm: "Thunderstorms"
        }
    }

    func symbol(isDay: Bool) -> String {
        switch self {
        case .clear, .mostlyClear: isDay ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .cloudy: "cloud.fill"
        case .fog: "cloud.fog.fill"
        case .drizzle: "cloud.drizzle.fill"
        case .rain: "cloud.rain.fill"
        case .heavyRain: "cloud.heavyrain.fill"
        case .freezingRain: "cloud.sleet.fill"
        case .snow: "cloud.snow.fill"
        case .thunderstorm: "cloud.bolt.rain.fill"
        }
    }

    func gradient(isDay: Bool) -> [Color] {
        if !isDay {
            switch self {
            case .thunderstorm, .heavyRain: return [Color(red: 0.08, green: 0.06, blue: 0.16), Color(red: 0.02, green: 0.02, blue: 0.06)]
            case .clear, .mostlyClear: return [Color(red: 0.05, green: 0.08, blue: 0.25), Color(red: 0.02, green: 0.03, blue: 0.10)]
            default: return [Color(red: 0.10, green: 0.12, blue: 0.22), Color(red: 0.03, green: 0.04, blue: 0.10)]
            }
        }
        switch self {
        case .clear, .mostlyClear:
            return [Color(red: 0.16, green: 0.49, blue: 0.93), Color(red: 0.99, green: 0.62, blue: 0.42)]
        case .partlyCloudy:
            return [Color(red: 0.24, green: 0.50, blue: 0.84), Color(red: 0.62, green: 0.70, blue: 0.83)]
        case .cloudy, .fog:
            return [Color(red: 0.38, green: 0.45, blue: 0.55), Color(red: 0.20, green: 0.25, blue: 0.33)]
        case .drizzle, .rain, .freezingRain:
            return [Color(red: 0.24, green: 0.32, blue: 0.45), Color(red: 0.10, green: 0.15, blue: 0.24)]
        case .heavyRain, .thunderstorm:
            return [Color(red: 0.17, green: 0.16, blue: 0.30), Color(red: 0.05, green: 0.06, blue: 0.12)]
        case .snow:
            return [Color(red: 0.55, green: 0.64, blue: 0.78), Color(red: 0.28, green: 0.35, blue: 0.48)]
        }
    }

    var cloudCover: Double {
        switch self {
        case .clear: 0
        case .mostlyClear: 0.15
        case .partlyCloudy: 0.45
        case .fog, .cloudy: 0.8
        default: 1
        }
    }

    var showsSun: Bool { [.clear, .mostlyClear, .partlyCloudy].contains(self) }
    var showsStars: Bool { [.clear, .mostlyClear, .partlyCloudy].contains(self) }
    var hasLightning: Bool { self == .thunderstorm }

    var particle: WeatherParticle? {
        switch self {
        case .drizzle, .rain, .freezingRain: .rain(heavy: false)
        case .heavyRain, .thunderstorm: .rain(heavy: true)
        case .snow: .snow
        default: nil
        }
    }
}

// MARK: - Human-friendly scales

enum UVScale {
    static func label(_ uv: Double) -> (String, Color) {
        switch uv {
        case ..<3: ("Low", .green)
        case ..<6: ("Moderate", .yellow)
        case ..<8: ("High", .orange)
        case ..<11: ("Very High", .red)
        default: ("Extreme", .purple)
        }
    }
}

enum AirQualityScale {
    static func label(_ aqi: Int) -> (String, Color) {
        switch aqi {
        case ..<51: ("Good", .green)
        case ..<101: ("Moderate", .yellow)
        case ..<151: ("Unhealthy for Sensitive Groups", .orange)
        case ..<201: ("Unhealthy", .red)
        case ..<301: ("Very Unhealthy", .purple)
        default: ("Hazardous", Color(red: 0.5, green: 0, blue: 0.1))
        }
    }
}

/// Georgia's favorite weather topic: how sticky does it feel outside?
enum MuggyMeter {
    static func label(dewPoint: Double) -> (title: String, detail: String, level: Double) {
        switch dewPoint {
        case ..<50: ("Crisp", "Dry and comfortable", 0.1)
        case ..<55: ("Comfortable", "Barely a hint of humidity", 0.25)
        case ..<60: ("Pleasant", "A touch of moisture in the air", 0.4)
        case ..<65: ("Sticky", "You'll notice it on a walk", 0.6)
        case ..<70: ("Muggy", "Classic Georgia summer air", 0.75)
        case ..<75: ("Oppressive", "Like walking through soup", 0.9)
        default: ("Swamp Mode", "Maximum Georgia humidity", 1.0)
        }
    }
}

/// Seasonal pollen estimate. Georgia's spring pine pollen is legendary;
/// a real pollen feed can replace this later (see docs/ROADMAP.md).
enum PollenOutlook {
    static func estimate(for date: Date = .now) -> (level: String, source: String, color: Color, progress: Double) {
        switch Calendar.current.component(.month, from: date) {
        case 2: ("Moderate", "Early tree pollen (oak, maple)", .yellow, 0.45)
        case 3, 4: ("Very High", "Pine & oak — the yellow dust is here", .red, 0.95)
        case 5: ("High", "Grass pollen", .orange, 0.7)
        case 6, 7: ("Moderate", "Grass pollen", .yellow, 0.45)
        case 8, 9, 10: ("High", "Ragweed season", .orange, 0.7)
        default: ("Low", "Mostly dormant", .green, 0.15)
        }
    }
}
