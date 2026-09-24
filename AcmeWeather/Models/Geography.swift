import CoreLocation
import MapKit

struct Coordinate: Codable, Hashable {
    var latitude: Double
    var longitude: Double

    init(_ latitude: Double, _ longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    init(_ coordinate: CLLocationCoordinate2D) {
        self.init(coordinate.latitude, coordinate.longitude)
    }

    var cl: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func distanceMiles(to other: Coordinate) -> Double {
        let a = CLLocation(latitude: latitude, longitude: longitude)
        let b = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return a.distance(from: b) / 1609.344
    }
}

enum GeorgiaRegion {
    static let center = CLLocationCoordinate2D(latitude: 32.68, longitude: -83.22)

    /// The whole state, framed with a little breathing room.
    static let state = MKCoordinateRegion(
        center: center,
        span: MKCoordinateSpan(latitudeDelta: 5.8, longitudeDelta: 5.8)
    )

    static func contains(_ c: Coordinate) -> Bool {
        (30.35...35.01).contains(c.latitude) && (-85.61 ... -80.75).contains(c.longitude)
    }
}

struct GeorgiaPlace: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let region: String
    let coordinate: Coordinate

    init(_ id: String, _ name: String, _ region: String, _ lat: Double, _ lon: Double) {
        self.id = id
        self.name = name
        self.region = region
        self.coordinate = Coordinate(lat, lon)
    }

    static let atlanta = GeorgiaPlace("atlanta", "Atlanta", "Metro Atlanta", 33.7490, -84.3880)

    static let all: [GeorgiaPlace] = [
        atlanta,
        GeorgiaPlace("marietta", "Marietta", "Metro Atlanta", 33.9526, -84.5499),
        GeorgiaPlace("alpharetta", "Alpharetta", "Metro Atlanta", 34.0754, -84.2941),
        GeorgiaPlace("dahlonega", "Dahlonega", "North Georgia Mountains", 34.5326, -83.9849),
        GeorgiaPlace("blueridge", "Blue Ridge", "North Georgia Mountains", 34.8640, -84.3241),
        GeorgiaPlace("helen", "Helen", "North Georgia Mountains", 34.7012, -83.7310),
        GeorgiaPlace("rome", "Rome", "Northwest Georgia", 34.2570, -85.1647),
        GeorgiaPlace("athens", "Athens", "Classic City", 33.9519, -83.3576),
        GeorgiaPlace("augusta", "Augusta", "CSRA", 33.4735, -82.0105),
        GeorgiaPlace("macon", "Macon", "Middle Georgia", 32.8407, -83.6324),
        GeorgiaPlace("milledgeville", "Milledgeville", "Middle Georgia", 33.0801, -83.2321),
        GeorgiaPlace("columbus", "Columbus", "West Georgia", 32.4610, -84.9877),
        GeorgiaPlace("lagrange", "LaGrange", "West Georgia", 33.0393, -85.0313),
        GeorgiaPlace("albany", "Albany", "Southwest Georgia", 31.5785, -84.1557),
        GeorgiaPlace("tifton", "Tifton", "South Georgia", 31.4505, -83.5085),
        GeorgiaPlace("thomasville", "Thomasville", "Southwest Georgia", 30.8366, -83.9788),
        GeorgiaPlace("valdosta", "Valdosta", "South Georgia", 30.8327, -83.2785),
        GeorgiaPlace("savannah", "Savannah", "Coastal Georgia", 32.0809, -81.0912),
        GeorgiaPlace("tybee", "Tybee Island", "Coastal Georgia", 32.0002, -80.8457),
        GeorgiaPlace("brunswick", "Brunswick", "Golden Isles", 31.1499, -81.4915),
        GeorgiaPlace("stsimons", "St. Simons Island", "Golden Isles", 31.1502, -81.3695),
        GeorgiaPlace("stmarys", "St. Marys", "Coastal Georgia", 30.7305, -81.5465),
    ]

    static func nearest(to coordinate: Coordinate) -> GeorgiaPlace {
        all.min { $0.coordinate.distanceMiles(to: coordinate) < $1.coordinate.distanceMiles(to: coordinate) } ?? atlanta
    }
}

extension MKCoordinateRegion {
    /// A region that frames all the given coordinates.
    static func fitting(_ coordinates: [Coordinate], padding: Double = 1.4, minimumSpan: Double = 0.3) -> MKCoordinateRegion {
        guard let first = coordinates.first else { return GeorgiaRegion.state }
        var minLat = first.latitude, maxLat = first.latitude
        var minLon = first.longitude, maxLon = first.longitude
        for c in coordinates {
            minLat = min(minLat, c.latitude); maxLat = max(maxLat, c.latitude)
            minLon = min(minLon, c.longitude); maxLon = max(maxLon, c.longitude)
        }
        return MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * padding, minimumSpan),
                longitudeDelta: max((maxLon - minLon) * padding, minimumSpan)
            )
        )
    }
}

enum Compass {
    static func direction(_ degrees: Double) -> String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalized = (degrees.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
        return points[Int((normalized / 22.5).rounded()) % 16]
    }
}
