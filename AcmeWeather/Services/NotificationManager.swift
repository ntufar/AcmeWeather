import Foundation
import Observation
import UserNotifications

@Observable
final class NotificationManager {
    private(set) var isAuthorized = false

    /// Only alerts at or above this severity trigger a notification.
    var minimumSeverity: AlertSeverity {
        didSet { UserDefaults.standard.set(minimumSeverity.rawValue, forKey: StorageKey.minimumSeverity) }
    }

    init() {
        let stored = UserDefaults.standard.string(forKey: StorageKey.minimumSeverity)
        minimumSeverity = stored.flatMap(AlertSeverity.init(rawValue:)) ?? .severe
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshStatus()
        return granted
    }

    func notify(about alerts: [WeatherAlert]) async {
        guard isAuthorized else { return }
        for alert in alerts.prefix(3) {
            let content = UNMutableNotificationContent()
            content.title = "\(alert.kind == .tornado ? "🌪️" : "⚠️") \(alert.event)"
            content.subtitle = alert.areaDescription
            content.body = alert.headline
            content.sound = .default
            content.interruptionLevel = alert.severity == .extreme ? .timeSensitive : .active
            let request = UNNotificationRequest(identifier: alert.id, content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}

/// Shows alert notifications as banners even while the app is open.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
