import SwiftUI

enum AlertSeverity: String, CaseIterable, Comparable, Codable {
    case unknown = "Unknown"
    case minor = "Minor"
    case moderate = "Moderate"
    case severe = "Severe"
    case extreme = "Extreme"

    private var rank: Int {
        switch self {
        case .unknown: 0
        case .minor: 1
        case .moderate: 2
        case .severe: 3
        case .extreme: 4
        }
    }

    static func < (lhs: AlertSeverity, rhs: AlertSeverity) -> Bool { lhs.rank < rhs.rank }

    var color: Color {
        switch self {
        case .extreme: Color(red: 0.93, green: 0.13, blue: 0.40)
        case .severe: Color(red: 0.95, green: 0.27, blue: 0.23)
        case .moderate: Color(red: 1.00, green: 0.62, blue: 0.16)
        case .minor: Color(red: 0.98, green: 0.84, blue: 0.25)
        case .unknown: Color(white: 0.6)
        }
    }
}

/// Broad hazard families, used for icons and linking to safety guides.
enum HazardKind: String, CaseIterable {
    case tornado, tropical, flood, thunderstorm, heat, winter, fire, wind, fog, airQuality, other

    init(event: String) {
        let e = event.lowercased()
        if e.contains("tornado") { self = .tornado }
        else if e.contains("hurricane") || e.contains("tropical") || e.contains("storm surge") { self = .tropical }
        else if e.contains("flood") { self = .flood }
        else if e.contains("thunderstorm") { self = .thunderstorm }
        else if e.contains("heat") { self = .heat }
        else if ["winter", "ice", "freeze", "frost", "snow", "cold", "chill", "sleet"].contains(where: e.contains) { self = .winter }
        else if e.contains("fire") || e.contains("red flag") { self = .fire }
        else if e.contains("wind") { self = .wind }
        else if e.contains("fog") { self = .fog }
        else if e.contains("air quality") || e.contains("smoke") { self = .airQuality }
        else { self = .other }
    }

    var symbol: String {
        switch self {
        case .tornado: "tornado"
        case .tropical: "hurricane"
        case .flood: "water.waves"
        case .thunderstorm: "cloud.bolt.rain.fill"
        case .heat: "thermometer.sun.fill"
        case .winter: "snowflake"
        case .fire: "flame.fill"
        case .wind: "wind"
        case .fog: "cloud.fog.fill"
        case .airQuality: "aqi.medium"
        case .other: "exclamationmark.triangle.fill"
        }
    }

    /// The safety guide most relevant to this hazard.
    var guideID: String? {
        switch self {
        case .tornado: "tornado"
        case .tropical: "hurricane"
        case .flood: "flood"
        case .thunderstorm: "lightning"
        case .heat: "heat"
        case .winter: "winter"
        default: nil
        }
    }
}

struct WeatherAlert: Identifiable, Hashable, Comparable {
    let id: String
    let event: String
    let headline: String
    let description: String
    let instruction: String?
    let severity: AlertSeverity
    let urgency: String
    let certainty: String
    let areaDescription: String
    let effective: Date?
    let expires: Date?
    let sender: String
    /// Outer rings of the warning polygon(s). Many NWS alerts are zone-based and have none.
    let polygons: [[Coordinate]]
    var isDemo = false

    var kind: HazardKind { HazardKind(event: event) }

    /// Warnings outrank watches outrank advisories within the same severity.
    private var eventRank: Int {
        let e = event.lowercased()
        if e.contains("warning") { return 3 }
        if e.contains("watch") { return 2 }
        if e.contains("advisory") { return 1 }
        return 0
    }

    static func < (lhs: WeatherAlert, rhs: WeatherAlert) -> Bool {
        if lhs.severity != rhs.severity { return lhs.severity > rhs.severity }
        if lhs.eventRank != rhs.eventRank { return lhs.eventRank > rhs.eventRank }
        return (lhs.expires ?? .distantFuture) < (rhs.expires ?? .distantFuture)
    }

    var expiresText: String? {
        guard let expires else { return nil }
        if expires < .now { return "Expired" }
        return "Until \(expires.formatted(.dateTime.weekday(.abbreviated).hour().minute()))"
    }

    var shareText: String {
        "⚠️ \(event) — \(areaDescription)\n\n\(headline)\n\nShared from Tufar Weather"
    }
}
