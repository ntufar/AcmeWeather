import Foundation

enum AppConfig {
    /// api.weather.gov requires a User-Agent that identifies the app and a contact.
    /// Replace the contact with a real address before shipping.
    static let nwsUserAgent = "(AcmeWeather iOS, support@acmeweather.example)"

    /// RainViewer's free tier serves radar tiles up to this zoom level; MapKit
    /// scales the tiles up when you zoom in further.
    static let radarMaxZoom = 7

    /// Number of past radar frames to animate.
    static let radarFrameCount = 10
}

enum StorageKey {
    static let hasOnboarded = "hasOnboarded"
    static let place = "placeSelection"
    static let demoMode = "demoMode"
    static let seenAlerts = "seenAlertIDs"
    static let minimumSeverity = "notificationMinimumSeverity"
    static let outageReports = "outageReports"
    static let kitChecked = "emergencyKitChecked"
    static let familyPlan = "familyPlan"
}

/// Tiny JSON-in-UserDefaults persistence used by the local stores.
enum Storage {
    static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
