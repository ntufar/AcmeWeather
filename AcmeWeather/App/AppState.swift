import Foundation
import CoreLocation
import Observation

/// Where the forecast is being shown for.
enum PlaceSelection: Hashable {
    case currentLocation
    case place(GeorgiaPlace)

    var storageID: String {
        switch self {
        case .currentLocation: "current"
        case .place(let place): place.id
        }
    }

    init(storageID: String?) {
        if let storageID, let place = GeorgiaPlace.all.first(where: { $0.id == storageID }) {
            self = .place(place)
        } else {
            self = .currentLocation
        }
    }
}

/// The single source of truth for the app. Owns the services and the data
/// every screen renders, and coordinates refreshes.
@Observable
final class AppState {
    var selectedTab: AppTab = .now

    // MARK: Sub-stores

    let location = LocationManager()
    let outages = OutageStore()
    let kit = EmergencyKitStore()
    let family = FamilyPlanStore()
    let notifications = NotificationManager()

    // MARK: Forecast

    var placeSelection: PlaceSelection {
        didSet {
            UserDefaults.standard.set(placeSelection.storageID, forKey: StorageKey.place)
            Task { await refreshWeather() }
        }
    }
    var weather: WeatherSnapshot?
    var weatherIsSample = false
    var isLoadingWeather = false
    var airQualityIndex: Int?

    // MARK: Alerts, tropics, radar

    var alerts: [WeatherAlert] = []
    var alertsUpdatedAt: Date?
    var alertsError: String?
    var storms: [Storm] = []
    var stormsError: String?
    var radarFrames: [RadarFrame] = []
    var lastFullRefresh: Date?

    /// Injects a sample hurricane, sample warnings and outage data so every
    /// feature can be demoed on a calm day.
    var demoMode: Bool {
        didSet {
            UserDefaults.standard.set(demoMode, forKey: StorageKey.demoMode)
            Task {
                await refreshAlerts()
                await refreshStorms()
            }
        }
    }

    @ObservationIgnored private let weatherService: any WeatherProviding
    @ObservationIgnored private let alertService: any AlertProviding
    @ObservationIgnored private let hurricaneService: any HurricaneProviding
    @ObservationIgnored private let radarService: any RadarProviding
    @ObservationIgnored private var seenAlertIDs: Set<String>

    init(
        weatherService: any WeatherProviding = OpenMeteoService(),
        alertService: any AlertProviding = NWSAlertService(),
        hurricaneService: any HurricaneProviding = NHCHurricaneService(),
        radarService: any RadarProviding = RainViewerService()
    ) {
        self.weatherService = weatherService
        self.alertService = alertService
        self.hurricaneService = hurricaneService
        self.radarService = radarService
        self.placeSelection = PlaceSelection(storageID: UserDefaults.standard.string(forKey: StorageKey.place))
        self.demoMode = UserDefaults.standard.bool(forKey: StorageKey.demoMode)
        self.seenAlertIDs = Set(Storage.load([String].self, key: StorageKey.seenAlerts) ?? [])
    }

    // MARK: Derived values

    var coordinate: Coordinate {
        switch placeSelection {
        case .currentLocation: location.coordinate ?? GeorgiaPlace.atlanta.coordinate
        case .place(let place): place.coordinate
        }
    }

    var placeTitle: String {
        switch placeSelection {
        case .currentLocation: location.coordinate == nil ? GeorgiaPlace.atlanta.name : "My Location"
        case .place(let place): place.name
        }
    }

    var placeSubtitle: String {
        switch placeSelection {
        case .currentLocation:
            guard let c = location.coordinate else { return "Location off · showing Atlanta" }
            guard GeorgiaRegion.contains(c) else { return "Outside Georgia" }
            return "Near \(GeorgiaPlace.nearest(to: c).name)"
        case .place(let place):
            return place.region
        }
    }

    /// Alerts worth a badge: severe or extreme.
    var significantAlertCount: Int {
        alerts.filter { $0.severity >= .severe }.count
    }

    var topAlert: WeatherAlert? { alerts.first }

    /// The closest storm to the forecast location, with distance in miles.
    var nearestStorm: (storm: Storm, miles: Double)? {
        storms
            .map { ($0, $0.position.distanceMiles(to: coordinate)) }
            .min { $0.1 < $1.1 }
    }

    // MARK: Refreshing

    func bootstrap() async {
        await notifications.refreshStatus()
        if UserDefaults.standard.bool(forKey: StorageKey.hasOnboarded) {
            location.start()
        }
        await refreshAll()
    }

    func refreshAll() async {
        async let weather: Void = refreshWeather()
        async let alerts: Void = refreshAlerts()
        async let storms: Void = refreshStorms()
        async let radar: Void = refreshRadar()
        _ = await (weather, alerts, storms, radar)
        lastFullRefresh = .now
    }

    func refreshIfStale() async {
        guard let last = lastFullRefresh, Date.now.timeIntervalSince(last) > 10 * 60 else { return }
        await refreshAll()
    }

    func locationDidChange() async {
        if case .currentLocation = placeSelection {
            await refreshWeather()
        }
    }

    func refreshWeather() async {
        isLoadingWeather = true
        defer { isLoadingWeather = false }
        let target = coordinate
        do {
            weather = try await weatherService.forecast(at: target)
            weatherIsSample = false
        } catch {
            if weather == nil || weatherIsSample {
                weather = SampleData.weather()
                weatherIsSample = true
            }
        }
        airQualityIndex = try? await weatherService.usAirQualityIndex(at: target)
    }

    func refreshAlerts() async {
        var live: [WeatherAlert] = []
        do {
            live = try await alertService.activeAlerts(area: "GA")
            alertsError = nil
        } catch {
            alertsError = "Couldn't reach the National Weather Service."
            live = alerts.filter { !$0.isDemo }
        }
        let combined = live + (demoMode ? SampleData.demoAlerts() : [])
        alerts = combined.sorted()
        alertsUpdatedAt = .now

        let fresh = alerts.filter { $0.severity >= notifications.minimumSeverity && !seenAlertIDs.contains($0.id) }
        seenAlertIDs.formUnion(alerts.map(\.id))
        Storage.save(Array(seenAlertIDs), key: StorageKey.seenAlerts)
        if !fresh.isEmpty {
            await notifications.notify(about: fresh)
        }
    }

    func refreshStorms() async {
        var live: [Storm] = []
        do {
            live = try await hurricaneService.activeAtlanticStorms()
            stormsError = nil
        } catch {
            stormsError = "Couldn't reach the National Hurricane Center."
            live = storms.filter { !$0.isDemo }
        }
        storms = live + (demoMode ? [SampleData.demoHurricane()] : [])
    }

    func refreshRadar() async {
        if let frames = try? await radarService.frames(), !frames.isEmpty {
            radarFrames = frames
        }
    }
}
