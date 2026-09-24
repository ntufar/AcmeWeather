import Foundation

protocol HurricaneProviding {
    func activeAtlanticStorms() async throws -> [Storm]
}

/// Active tropical cyclones from the National Hurricane Center's
/// CurrentStorms.json summary feed. It provides the current fix and
/// intensity; forecast track/cone geometry lives in NHC GIS products
/// (see docs/ROADMAP.md).
struct NHCHurricaneService: HurricaneProviding {
    var session: URLSession = .shared

    func activeAtlanticStorms() async throws -> [Storm] {
        let url = URL(string: "https://www.nhc.noaa.gov/CurrentStorms.json")!
        let (data, response) = try await session.data(from: url)
        try HTTP.validate(response)
        return try NHCParser.parse(data)
    }
}

enum NHCParser {
    private struct Response: Decodable {
        let activeStorms: [NHCStorm]
    }

    private struct NHCStorm: Decodable {
        let id: String
        let name: String
        let classification: String
        let intensityKnots: Double?
        let pressure: Double?
        let latitudeNumeric: Double?
        let longitudeNumeric: Double?
        let movementDir: Double?
        let movementSpeed: Double?
        let lastUpdate: String?
        let advisoryURL: String?

        private enum CodingKeys: String, CodingKey {
            case id, name, classification, intensity, pressure, latitudeNumeric, longitudeNumeric,
                 movementDir, movementSpeed, lastUpdate, publicAdvisory
        }

        private struct Link: Decodable { let url: String? }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            name = (try? c.decode(String.self, forKey: .name)) ?? "Unnamed"
            classification = (try? c.decode(String.self, forKey: .classification)) ?? ""
            intensityKnots = Self.flexibleDouble(c, .intensity)
            pressure = Self.flexibleDouble(c, .pressure)
            latitudeNumeric = Self.flexibleDouble(c, .latitudeNumeric)
            longitudeNumeric = Self.flexibleDouble(c, .longitudeNumeric)
            movementDir = Self.flexibleDouble(c, .movementDir)
            movementSpeed = Self.flexibleDouble(c, .movementSpeed)
            lastUpdate = try? c.decode(String.self, forKey: .lastUpdate)
            advisoryURL = (try? c.decode(Link.self, forKey: .publicAdvisory))?.url
        }

        /// NHC mixes numbers and numeric strings across fields.
        private static func flexibleDouble(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
            if let value = try? c.decode(Double.self, forKey: key) { return value }
            if let string = try? c.decode(String.self, forKey: key) { return Double(string) }
            return nil
        }
    }

    static func parse(_ data: Data) throws -> [Storm] {
        let response = try JSONDecoder().decode(Response.self, from: data)
        return response.activeStorms
            .filter { $0.id.lowercased().hasPrefix("al") }
            .compactMap { s in
                guard let lat = s.latitudeNumeric, let lon = s.longitudeNumeric else { return nil }
                let windMph = Int(((s.intensityKnots ?? 0) * 1.15078).rounded())
                let position = Coordinate(lat, lon)
                return Storm(
                    id: s.id,
                    name: s.name,
                    classification: s.classification,
                    windMph: windMph,
                    pressureMb: s.pressure.map { Int($0) },
                    position: position,
                    movementDegrees: s.movementDir.map { Int($0) },
                    movementMph: s.movementSpeed.map { Int($0) },
                    lastUpdate: ISODate.parse(s.lastUpdate),
                    advisoryURL: s.advisoryURL.flatMap(URL.init(string:)),
                    forecastTrack: [TrackPoint(hoursFromNow: 0, coordinate: position, windMph: windMph)]
                )
            }
    }
}
