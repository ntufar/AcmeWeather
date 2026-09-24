import SwiftUI
import UserNotifications

@main
struct AcmeWeatherApp: App {
    @State private var app = AppState()

    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.dark)
                .task { await app.bootstrap() }
        }
    }
}
