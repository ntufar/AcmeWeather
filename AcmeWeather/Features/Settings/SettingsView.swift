import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @AppStorage(StorageKey.hasOnboarded) private var hasOnboarded = true

    var body: some View {
        @Bindable var app = app
        @Bindable var notifications = app.notifications

        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $app.demoMode) {
                        Label {
                            VStack(alignment: .leading) {
                                Text("Demo Mode")
                                Text("Adds a simulated hurricane, warnings and outages so you can explore every feature.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "sparkles").foregroundStyle(Theme.peach)
                        }
                    }
                    .tint(Theme.peach)
                }

                Section("Notifications") {
                    if notifications.isAuthorized {
                        Picker("Notify me for", selection: $notifications.minimumSeverity) {
                            Text("Extreme only").tag(AlertSeverity.extreme)
                            Text("Severe & up").tag(AlertSeverity.severe)
                            Text("Moderate & up").tag(AlertSeverity.moderate)
                            Text("Everything").tag(AlertSeverity.minor)
                        }
                    } else {
                        Button {
                            Task { await app.notifications.requestAuthorization() }
                        } label: {
                            Label("Turn on severe weather alerts", systemImage: "bell.badge.fill")
                        }
                    }
                    Text("Alerts are checked whenever the app refreshes. Background delivery is on the roadmap.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Location") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(locationStatus).foregroundStyle(.secondary)
                    }
                    if app.location.isDenied {
                        Button("Open iOS Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                        }
                    } else if !app.location.isAuthorized {
                        Button("Allow location access") { app.location.requestPermission() }
                    }
                }

                Section("Data sources") {
                    SourceRow(name: "Forecasts", source: "Open-Meteo (NOAA GFS/HRRR)", url: "https://open-meteo.com")
                    SourceRow(name: "Alerts", source: "National Weather Service", url: "https://www.weather.gov")
                    SourceRow(name: "Tropics", source: "National Hurricane Center", url: "https://www.nhc.noaa.gov")
                    SourceRow(name: "Radar", source: "RainViewer", url: "https://www.rainviewer.com")
                }

                Section {
                    Button("Replay welcome tour") {
                        dismiss()
                        hasOnboarded = false
                    }
                } footer: {
                    Text("Tufar Weather \(Bundle.main.shortVersion) · Made with 🍑 in Georgia.\nNot a substitute for official warnings. In an emergency, call 911.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.appBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
            .task { await app.notifications.refreshStatus() }
        }
    }

    private var locationStatus: String {
        if app.location.isAuthorized { return "Allowed" }
        if app.location.isDenied { return "Denied" }
        return "Not set"
    }
}

private struct SourceRow: View {
    let name: String
    let source: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(name).foregroundStyle(.white)
                Spacer()
                Text(source).font(.caption).foregroundStyle(.secondary)
                Image(systemName: "arrow.up.right.square").foregroundStyle(.secondary)
            }
        }
    }
}

extension Bundle {
    var shortVersion: String {
        (infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
}
