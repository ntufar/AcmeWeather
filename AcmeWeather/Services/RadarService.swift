import Foundation

protocol RadarProviding {
    func frames() async throws -> [RadarFrame]
}

/// Radar mosaic frames from RainViewer (https://www.rainviewer.com/api.html).
/// Free for personal and small-scale use; attribution required.
struct RainViewerService: RadarProviding {
    var session: URLSession = .shared

    private struct Manifest: Decodable {
        struct Frame: Decodable {
            let time: TimeInterval
            let path: String
        }
        struct Radar: Decodable {
            let past: [Frame]
            let nowcast: [Frame]?
        }
        let host: String
        let radar: Radar
    }

    func frames() async throws -> [RadarFrame] {
        let url = URL(string: "https://api.rainviewer.com/public/weather-maps.json")!
        let (data, response) = try await session.data(from: url)
        try HTTP.validate(response)
        return try Self.parse(data)
    }

    static func parse(_ data: Data) throws -> [RadarFrame] {
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        let past = manifest.radar.past.suffix(AppConfig.radarFrameCount).map {
            RadarFrame(time: Date(timeIntervalSince1970: $0.time), host: manifest.host, path: $0.path, isForecast: false)
        }
        let future = (manifest.radar.nowcast ?? []).map {
            RadarFrame(time: Date(timeIntervalSince1970: $0.time), host: manifest.host, path: $0.path, isForecast: true)
        }
        return past + future
    }
}
