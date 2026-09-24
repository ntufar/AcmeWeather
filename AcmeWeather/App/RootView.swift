import SwiftUI

enum AppTab: Hashable {
    case now, radar, alerts, hurricanes, safety
}

struct RootView: View {
    @Environment(AppState.self) private var app
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(StorageKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        @Bindable var app = app

        TabView(selection: $app.selectedTab) {
            NowView()
                .tabItem { Label("Now", systemImage: "sun.max.fill") }
                .tag(AppTab.now)

            RadarView()
                .tabItem { Label("Radar", systemImage: "map.fill") }
                .tag(AppTab.radar)

            AlertsView()
                .tabItem { Label("Alerts", systemImage: "exclamationmark.triangle.fill") }
                .badge(app.significantAlertCount)
                .tag(AppTab.alerts)

            HurricaneCenterView()
                .tabItem { Label("Tropics", systemImage: "hurricane") }
                .tag(AppTab.hurricanes)

            SafetyHubView()
                .tabItem { Label("Be Ready", systemImage: "cross.case.fill") }
                .tag(AppTab.safety)
        }
        .tint(Theme.peach)
        .fullScreenCover(isPresented: Binding(get: { !hasOnboarded }, set: { hasOnboarded = !$0 })) {
            OnboardingView { hasOnboarded = true }
        }
        .onChange(of: app.location.fixCount) { _, _ in
            Task { await app.locationDidChange() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await app.refreshIfStale() } }
        }
    }
}
