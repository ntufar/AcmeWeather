import Foundation

struct RadarFrame: Identifiable, Hashable {
    let time: Date
    let host: String
    let path: String
    let isForecast: Bool

    var id: String { path }

    /// Tile URL template in MapKit's {z}/{x}/{y} format. Color scheme 2
    /// ("Universal Blue") with smoothing and snow coloring enabled.
    var tileTemplate: String { "\(host)\(path)/256/{z}/{x}/{y}/2/1_1.png" }
}
