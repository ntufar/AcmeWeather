import SwiftUI

/// Saffir-Simpson Hurricane Wind Scale plus the tropical storm / depression tiers.
enum StormCategory: Comparable, Hashable {
    case depression
    case tropicalStorm
    case hurricane(Int)

    init(windMph: Int) {
        switch windMph {
        case ..<39: self = .depression
        case ..<74: self = .tropicalStorm
        case ..<96: self = .hurricane(1)
        case ..<111: self = .hurricane(2)
        case ..<130: self = .hurricane(3)
        case ..<157: self = .hurricane(4)
        default: self = .hurricane(5)
        }
    }

    var shortLabel: String {
        switch self {
        case .depression: "TD"
        case .tropicalStorm: "TS"
        case .hurricane(let cat): "Cat \(cat)"
        }
    }

    var longLabel: String {
        switch self {
        case .depression: "Tropical Depression"
        case .tropicalStorm: "Tropical Storm"
        case .hurricane(let cat): cat >= 3 ? "Major Hurricane · Category \(cat)" : "Hurricane · Category \(cat)"
        }
    }

    var color: Color {
        switch self {
        case .depression: Color(red: 0.36, green: 0.66, blue: 0.96)
        case .tropicalStorm: Color(red: 0.25, green: 0.80, blue: 0.62)
        case .hurricane(1): Color(red: 1.00, green: 0.85, blue: 0.30)
        case .hurricane(2): Color(red: 1.00, green: 0.62, blue: 0.20)
        case .hurricane(3): Color(red: 0.97, green: 0.36, blue: 0.20)
        case .hurricane(4): Color(red: 0.90, green: 0.12, blue: 0.30)
        case .hurricane: Color(red: 0.75, green: 0.20, blue: 0.85)
        }
    }

    static let saffirSimpson: [(category: Int, winds: String, damage: String)] = [
        (1, "74–95 mph", "Very dangerous winds will produce some damage: roof shingles, gutters, large tree branches snap, power outages likely for days."),
        (2, "96–110 mph", "Extremely dangerous winds cause extensive damage: major roof and siding damage, many shallow-rooted trees uprooted, near-total power loss for days to weeks."),
        (3, "111–129 mph", "Devastating damage: well-built homes may lose roof decking and gable ends, many trees snapped or uprooted, electricity and water unavailable for days to weeks."),
        (4, "130–156 mph", "Catastrophic damage: homes can lose most of the roof and some exterior walls, power poles downed, areas uninhabitable for weeks or months."),
        (5, "157+ mph", "Catastrophic damage: a high percentage of framed homes destroyed, residential areas isolated, power outages for weeks to possibly months."),
    ]
}

struct TrackPoint: Identifiable, Hashable {
    let hoursFromNow: Int
    let coordinate: Coordinate
    let windMph: Int

    var id: Int { hoursFromNow }
    var category: StormCategory { StormCategory(windMph: windMph) }
    var label: String { hoursFromNow == 0 ? "Now" : "+\(hoursFromNow)h" }
}

struct Storm: Identifiable, Hashable {
    let id: String
    let name: String
    /// NHC classification code (HU, TS, TD, STS, PTC, ...).
    let classification: String
    let windMph: Int
    let pressureMb: Int?
    let position: Coordinate
    let movementDegrees: Int?
    let movementMph: Int?
    let lastUpdate: Date?
    let advisoryURL: URL?
    /// Forecast positions starting at the current one. Empty when only the
    /// current fix is known (live NHC summary feed).
    let forecastTrack: [TrackPoint]
    var isDemo = false

    var category: StormCategory { StormCategory(windMph: windMph) }

    var typeName: String {
        switch classification {
        case "HU": "Hurricane"
        case "TS": "Tropical Storm"
        case "TD": "Tropical Depression"
        case "STS": "Subtropical Storm"
        case "SD": "Subtropical Depression"
        case "PTC": "Potential Tropical Cyclone"
        case "PC": "Post-Tropical Cyclone"
        default: "Storm"
        }
    }

    var displayName: String { "\(typeName) \(name)" }

    var movementText: String {
        guard let movementDegrees, let movementMph else { return "Stationary" }
        return "\(Compass.direction(Double(movementDegrees))) at \(movementMph) mph"
    }

    /// Cone of uncertainty polygon, widening along the forecast track.
    var cone: [Coordinate] {
        ConeBuilder.cone(along: forecastTrack.map(\.coordinate))
    }
}

/// Builds a cone-of-uncertainty style polygon around a forecast track by
/// offsetting each point perpendicular to the direction of travel with a
/// radius that grows over time, then capping both ends with arcs.
enum ConeBuilder {
    static func cone(along track: [Coordinate], startRadiusMiles: Double = 25, growthMiles: Double = 28) -> [Coordinate] {
        guard track.count >= 2 else { return [] }
        let radii = track.indices.map { startRadiusMiles + Double($0) * growthMiles }
        let bearings = track.indices.map { i -> Double in
            let a = track[max(i - 1, 0)]
            let b = track[i == 0 ? 1 : i]
            return bearing(from: a, to: b)
        }

        var left: [Coordinate] = []
        var right: [Coordinate] = []
        for i in track.indices {
            left.append(offset(track[i], miles: radii[i], bearing: bearings[i] - .pi / 2))
            right.append(offset(track[i], miles: radii[i], bearing: bearings[i] + .pi / 2))
        }

        let endCap = arc(around: track.last!, miles: radii.last!, from: bearings.last! - .pi / 2, to: bearings.last! + .pi / 2)
        let startCap = arc(around: track[0], miles: radii[0], from: bearings[0] + .pi / 2, to: bearings[0] + 3 * .pi / 2)
        return left + endCap + right.reversed() + startCap
    }

    /// Planar bearing in radians, clockwise from north.
    static func bearing(from a: Coordinate, to b: Coordinate) -> Double {
        let meanLat = (a.latitude + b.latitude) / 2 * .pi / 180
        let dx = (b.longitude - a.longitude) * cos(meanLat)
        let dy = b.latitude - a.latitude
        return atan2(dx, dy)
    }

    static func offset(_ c: Coordinate, miles: Double, bearing: Double) -> Coordinate {
        let dLat = miles * cos(bearing) / 69.0
        let dLon = miles * sin(bearing) / (69.0 * cos(c.latitude * .pi / 180))
        return Coordinate(c.latitude + dLat, c.longitude + dLon)
    }

    private static func arc(around c: Coordinate, miles: Double, from start: Double, to end: Double, steps: Int = 12) -> [Coordinate] {
        (1..<steps).map { i in
            offset(c, miles: miles, bearing: start + (end - start) * Double(i) / Double(steps))
        }
    }
}

/// Georgia's six coastal counties and their typical inland evacuation routes.
/// Routes are general guidance — always follow GEMA and county EMA orders.
struct CoastalCounty: Identifiable {
    let name: String
    let seat: String
    let routes: [String]
    var id: String { name }

    static let all: [CoastalCounty] = [
        CoastalCounty(name: "Chatham", seat: "Savannah", routes: ["I-16 West (contraflow may be activated)", "US-80 West"]),
        CoastalCounty(name: "Bryan", seat: "Pembroke", routes: ["I-16 West", "US-280 West"]),
        CoastalCounty(name: "Liberty", seat: "Hinesville", routes: ["US-84 West", "GA-119 North"]),
        CoastalCounty(name: "McIntosh", seat: "Darien", routes: ["GA-251 to I-95 North", "GA-57 West"]),
        CoastalCounty(name: "Glynn", seat: "Brunswick", routes: ["US-341 West", "US-82 West"]),
        CoastalCounty(name: "Camden", seat: "Woodbine", routes: ["GA-40 West", "US-17 North to I-95"]),
    ]
}
