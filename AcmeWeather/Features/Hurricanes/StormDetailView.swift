import SwiftUI
import MapKit

struct StormDetailView: View {
    let storm: Storm
    @Environment(AppState.self) private var app

    var body: some View {
        let miles = storm.position.distanceMiles(to: app.coordinate)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                Map(initialPosition: .region(.fitting(storm.forecastTrack.map(\.coordinate) + [app.coordinate], padding: 1.3))) {
                    StormMapContent(storm: storm)
                    UserAnnotation()
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                stats(miles: miles)

                ThreatGuidance(miles: miles, category: storm.category)

                if storm.forecastTrack.count > 1 {
                    trackTable
                }

                if let url = storm.advisoryURL {
                    Link(destination: url) {
                        Label("Read the official NHC advisory", systemImage: "safari.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.sky.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }

                Text(storm.isDemo
                     ? "Hurricane Magnolia is a fictional storm for Demo Mode."
                     : "Position and intensity from the National Hurricane Center. Always follow official NHC advisories and local emergency officials.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Theme.appBackground.ignoresSafeArea())
        .navigationTitle(storm.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            SpinningStormIcon(color: storm.category.color, size: 70)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(storm.displayName).font(.title2.weight(.bold))
                    if storm.isDemo { DemoBadge() }
                }
                Text(storm.category.longLabel)
                    .font(.headline)
                    .foregroundStyle(storm.category.color)
                if let updated = storm.lastUpdate {
                    Text("Updated \(updated.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func stats(miles: Double) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            DetailTile(title: "Max winds", symbol: "wind", value: "\(storm.windMph) mph", caption: storm.category.shortLabel)
            DetailTile(title: "Pressure", symbol: "gauge.with.dots.needle.33percent",
                       value: storm.pressureMb.map { "\($0) mb" } ?? "—", caption: "Lower = stronger")
            DetailTile(title: "Movement", symbol: "arrow.up.right", value: storm.movementText, caption: "Current heading")
            DetailTile(title: "Distance", symbol: "location.fill", value: "\(Int(miles).formatted()) mi",
                       caption: "From \(app.placeTitle)")
        }
    }

    private var trackTable: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardHeader(title: "Forecast track", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            ForEach(storm.forecastTrack) { point in
                HStack {
                    Text(point.label).font(.subheadline.weight(.semibold)).frame(width: 56, alignment: .leading)
                    Circle().fill(point.category.color).frame(width: 10, height: 10)
                    Text(point.category.shortLabel).font(.subheadline).frame(width: 50, alignment: .leading)
                    Text("\(point.windMph) mph").font(.subheadline)
                    Spacer()
                    Text(String(format: "%.1f°N %.1f°W", point.coordinate.latitude, abs(point.coordinate.longitude)))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .glassCard()
    }
}

/// Plain-language "what does this mean for me" guidance based on distance and strength.
private struct ThreatGuidance: View {
    let miles: Double
    let category: StormCategory

    var body: some View {
        let (title, message, color): (String, String, Color) = {
            switch miles {
            case ..<150:
                return ("High threat", "This storm is close. Follow evacuation orders immediately and finish preparations now.", Theme.danger)
            case ..<400:
                return ("Be ready", "Tropical-storm-force winds and heavy rain could reach you within days. Review your plan and top off supplies.", .orange)
            default:
                return ("Monitor", "No immediate threat to your location. Keep an eye on the forecast — tracks can shift.", Theme.sky)
            }
        }()
        return VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: "shield.lefthalf.filled")
                .font(.headline)
                .foregroundStyle(color)
            Text(message).font(.subheadline)
        }
        .glassCard()
    }
}
