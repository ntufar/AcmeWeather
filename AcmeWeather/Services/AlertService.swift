import Foundation

protocol AlertProviding {
    func activeAlerts(area: String) async throws -> [WeatherAlert]
}

/// Active watches, warnings and advisories from the National Weather Service
/// (https://api.weather.gov). Free, no key; a descriptive User-Agent is required.
struct NWSAlertService: AlertProviding {
    var session: URLSession = .shared

    func activeAlerts(area: String) async throws -> [WeatherAlert] {
        var request = URLRequest(url: URL(string: "https://api.weather.gov/alerts/active?area=\(area)")!)
        request.setValue(AppConfig.nwsUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        try HTTP.validate(response)
        return try NWSAlertParser.parse(data)
    }
}

enum NWSAlertParser {
    private struct Collection: Decodable {
        let features: [Feature]
    }

    private struct Feature: Decodable {
        let id: String
        let geometry: Geometry?
        let properties: Properties
    }

    private struct Properties: Decodable {
        let id: String?
        let event: String?
        let headline: String?
        let description: String?
        let instruction: String?
        let severity: String?
        let urgency: String?
        let certainty: String?
        let areaDesc: String?
        let effective: String?
        let expires: String?
        let ends: String?
        let senderName: String?
    }

    /// GeoJSON Polygon or MultiPolygon; we keep each polygon's outer ring.
    private struct Geometry: Decodable {
        let rings: [[Coordinate]]

        private enum CodingKeys: String, CodingKey { case type, coordinates }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            func ring(_ points: [[Double]]) -> [Coordinate] {
                points.compactMap { $0.count >= 2 ? Coordinate($0[1], $0[0]) : nil }
            }
            switch type {
            case "Polygon":
                let polygon = try container.decode([[[Double]]].self, forKey: .coordinates)
                rings = polygon.first.map { [ring($0)] } ?? []
            case "MultiPolygon":
                let multi = try container.decode([[[[Double]]]].self, forKey: .coordinates)
                rings = multi.compactMap { $0.first.map(ring) }
            default:
                rings = []
            }
        }
    }

    static func parse(_ data: Data) throws -> [WeatherAlert] {
        let collection = try JSONDecoder().decode(Collection.self, from: data)
        return collection.features.compactMap { feature in
            let p = feature.properties
            guard let event = p.event else { return nil }
            return WeatherAlert(
                id: p.id ?? feature.id,
                event: event,
                headline: p.headline ?? event,
                description: p.description ?? "",
                instruction: p.instruction,
                severity: AlertSeverity(rawValue: p.severity ?? "") ?? .unknown,
                urgency: p.urgency ?? "Unknown",
                certainty: p.certainty ?? "Unknown",
                areaDescription: p.areaDesc ?? "Georgia",
                effective: ISODate.parse(p.effective),
                expires: ISODate.parse(p.ends) ?? ISODate.parse(p.expires),
                sender: p.senderName ?? "National Weather Service",
                polygons: feature.geometry?.rings.filter { $0.count >= 3 } ?? []
            )
        }
    }
}
