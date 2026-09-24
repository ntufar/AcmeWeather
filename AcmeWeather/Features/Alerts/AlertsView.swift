import SwiftUI

struct AlertsView: View {
    @Environment(AppState.self) private var app
    @State private var filter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case warnings = "Warnings"
        case watches = "Watches"
        case advisories = "Advisories"
        var id: String { rawValue }

        func matches(_ alert: WeatherAlert) -> Bool {
            let event = alert.event.lowercased()
            switch self {
            case .all: return true
            case .warnings: return event.contains("warning")
            case .watches: return event.contains("watch")
            case .advisories: return !event.contains("warning") && !event.contains("watch")
            }
        }
    }

    private var filtered: [WeatherAlert] { app.alerts.filter(filter.matches) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    summary
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }

                Section {
                    Picker("Filter", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("All clear", systemImage: "checkmark.shield.fill")
                    } description: {
                        Text(app.alerts.isEmpty
                             ? "No active weather alerts for Georgia right now. Enjoy it! 🍑"
                             : "No \(filter.rawValue.lowercased()) right now.")
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filtered) { alert in
                        NavigationLink(value: alert) {
                            AlertRow(alert: alert)
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                }

                if let error = app.alertsError {
                    Label(error, systemImage: "wifi.exclamationmark")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .listRowBackground(Color.clear)
                }
            }
            .appBackground()
            .navigationTitle("Georgia Alerts")
            .navigationDestination(for: WeatherAlert.self) { AlertDetailView(alert: $0) }
            .refreshable { await app.refreshAlerts() }
        }
    }

    private var summary: some View {
        let extreme = app.alerts.filter { $0.severity == .extreme }.count
        let severe = app.alerts.filter { $0.severity == .severe }.count
        let other = app.alerts.count - extreme - severe
        return HStack(spacing: 10) {
            SummaryChip(count: extreme, label: "Extreme", color: AlertSeverity.extreme.color)
            SummaryChip(count: severe, label: "Severe", color: AlertSeverity.severe.color)
            SummaryChip(count: other, label: "Other", color: AlertSeverity.moderate.color)
        }
        .overlay(alignment: .bottomTrailing) {
            if let updated = app.alertsUpdatedAt {
                Text("Updated \(updated.shortTime)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .offset(y: 18)
            }
        }
        .padding(.bottom, 12)
    }
}

private struct SummaryChip: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title.weight(.bold))
                .contentTransition(.numericText())
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(count > 0 ? 0.25 : 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(color.opacity(count > 0 ? 0.6 : 0.15)))
    }
}

struct AlertRow: View {
    let alert: WeatherAlert

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.kind.symbol)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(alert.severity.color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.event).font(.headline)
                    if alert.isDemo { DemoBadge() }
                }
                Text(alert.areaDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Pill(text: alert.severity.rawValue.uppercased(), color: alert.severity.color.opacity(0.3))
                    if let expires = alert.expiresText {
                        Text(expires).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
