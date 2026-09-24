import Foundation

protocol WeatherProviding {
    func forecast(at coordinate: Coordinate) async throws -> WeatherSnapshot
    func usAirQualityIndex(at coordinate: Coordinate) async throws -> Int?
}

/// Forecasts from Open-Meteo (https://open-meteo.com) — free, no API key,
/// backed by NOAA GFS/HRRR for the United States.
struct OpenMeteoService: WeatherProviding {
    var session: URLSession = .shared

    func forecast(at coordinate: Coordinate) async throws -> WeatherSnapshot {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,pressure_msl,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index,dew_point_2m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,precipitation_probability,weather_code,is_day"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
            URLQueryItem(name: "forecast_days", value: "7"),
        ]
        let (data, response) = try await session.data(from: components.url!)
        try HTTP.validate(response)
        return try OpenMeteoResponse.decode(data).snapshot()
    }

    func usAirQualityIndex(at coordinate: Coordinate) async throws -> Int? {
        var components = URLComponents(string: "https://air-quality-api.open-meteo.com/v1/air-quality")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "current", value: "us_aqi"),
        ]
        let (data, response) = try await session.data(from: components.url!)
        try HTTP.validate(response)
        struct AQIResponse: Decodable {
            struct Current: Decodable {
                let usAqi: Double?
                enum CodingKeys: String, CodingKey { case usAqi = "us_aqi" }
            }
            let current: Current
        }
        let decoded = try JSONDecoder().decode(AQIResponse.self, from: data)
        return decoded.current.usAqi.map { Int($0.rounded()) }
    }
}

struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let time: String
        let temperature2m: Double
        let relativeHumidity2m: Double?
        let apparentTemperature: Double?
        let isDay: Int?
        let precipitation: Double?
        let weatherCode: Int?
        let pressureMsl: Double?
        let windSpeed10m: Double?
        let windDirection10m: Double?
        let windGusts10m: Double?
        let uvIndex: Double?
        let dewPoint2m: Double?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
            case apparentTemperature = "apparent_temperature"
            case isDay = "is_day"
            case precipitation
            case weatherCode = "weather_code"
            case pressureMsl = "pressure_msl"
            case windSpeed10m = "wind_speed_10m"
            case windDirection10m = "wind_direction_10m"
            case windGusts10m = "wind_gusts_10m"
            case uvIndex = "uv_index"
            case dewPoint2m = "dew_point_2m"
        }
    }

    struct Hourly: Decodable {
        let time: [String]
        let temperature2m: [Double?]
        let precipitationProbability: [Int?]?
        let weatherCode: [Int?]
        let isDay: [Int?]?

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2m = "temperature_2m"
            case precipitationProbability = "precipitation_probability"
            case weatherCode = "weather_code"
            case isDay = "is_day"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let weatherCode: [Int?]
        let temperature2mMax: [Double?]
        let temperature2mMin: [Double?]
        let precipitationProbabilityMax: [Int?]?
        let sunrise: [String]?
        let sunset: [String]?
        let uvIndexMax: [Double?]?

        enum CodingKeys: String, CodingKey {
            case time, sunrise, sunset
            case weatherCode = "weather_code"
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case precipitationProbabilityMax = "precipitation_probability_max"
            case uvIndexMax = "uv_index_max"
        }
    }

    let utcOffsetSeconds: Int
    let current: Current
    let hourly: Hourly
    let daily: Daily

    enum CodingKeys: String, CodingKey {
        case current, hourly, daily
        case utcOffsetSeconds = "utc_offset_seconds"
    }

    static func decode(_ data: Data) throws -> OpenMeteoResponse {
        try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
    }

    func snapshot(now: Date = .now) -> WeatherSnapshot {
        let timeZone = TimeZone(secondsFromGMT: utcOffsetSeconds) ?? .current
        let hourFormat = DateFormatter.posix("yyyy-MM-dd'T'HH:mm", timeZone: timeZone)
        let dayFormat = DateFormatter.posix("yyyy-MM-dd", timeZone: timeZone)

        let conditions = CurrentConditions(
            temperature: current.temperature2m,
            apparentTemperature: current.apparentTemperature ?? current.temperature2m,
            humidity: current.relativeHumidity2m ?? 0,
            dewPoint: current.dewPoint2m ?? current.temperature2m,
            windSpeed: current.windSpeed10m ?? 0,
            windGust: current.windGusts10m ?? 0,
            windDirection: current.windDirection10m ?? 0,
            pressureHPa: current.pressureMsl ?? 1013,
            precipitation: current.precipitation ?? 0,
            uvIndex: current.uvIndex ?? 0,
            weatherCode: current.weatherCode ?? 3,
            isDay: (current.isDay ?? 1) == 1
        )

        var hours: [HourlyForecast] = []
        let startOfHour = now.addingTimeInterval(-3600)
        for (i, stamp) in hourly.time.enumerated() {
            guard let time = hourFormat.date(from: stamp), time > startOfHour,
                  let temperature = hourly.temperature2m[safe: i] ?? nil else { continue }
            hours.append(HourlyForecast(
                time: time,
                temperature: temperature,
                precipitationChance: (hourly.precipitationProbability?[safe: i] ?? nil) ?? 0,
                weatherCode: (hourly.weatherCode[safe: i] ?? nil) ?? 3,
                isDay: ((hourly.isDay?[safe: i] ?? nil) ?? 1) == 1
            ))
            if hours.count == 24 { break }
        }

        var days: [DailyForecast] = []
        for (i, stamp) in daily.time.enumerated() {
            guard let date = dayFormat.date(from: stamp),
                  let high = daily.temperature2mMax[safe: i] ?? nil,
                  let low = daily.temperature2mMin[safe: i] ?? nil else { continue }
            days.append(DailyForecast(
                date: date,
                high: high,
                low: low,
                precipitationChance: (daily.precipitationProbabilityMax?[safe: i] ?? nil) ?? 0,
                weatherCode: (daily.weatherCode[safe: i] ?? nil) ?? 3,
                sunrise: daily.sunrise?[safe: i].flatMap { hourFormat.date(from: $0) },
                sunset: daily.sunset?[safe: i].flatMap { hourFormat.date(from: $0) },
                uvIndexMax: (daily.uvIndexMax?[safe: i] ?? nil) ?? 0
            ))
        }

        return WeatherSnapshot(current: conditions, hourly: hours, daily: days, fetchedAt: now)
    }
}
