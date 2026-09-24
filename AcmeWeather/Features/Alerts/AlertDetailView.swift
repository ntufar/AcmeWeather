import SwiftUI
import MapKit

struct AlertDetailView: View {
    let alert: WeatherAlert
    @State private var showGuide: SafetyGuide?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if alert.kind == .tornado && alert.event.lowercased().contains("warning") {
                    TakeShelterCard()
                }

                if !alert.polygons.isEmpty {
                    Map(initialPosition: .region(.fitting(alert.polygons.flatMap { $0 }, padding: 1.8))) {
                        ForEach(Array(alert.polygons.enumerated()), id: \.offset) { _, ring in
                            MapPolygon(coordinates: ring.map(\.cl))
                                .foregroundStyle(alert.severity.color.opacity(0.3))
                                .stroke(alert.severity.color, lineWidth: 2)
                        }
                        UserAnnotation()
                    }
                    .mapStyle(.standard(pointsOfInterest: .excludingAll))
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }

                if let instruction = alert.instruction, !instruction.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        CardHeader(title: "What to do", systemImage: "figure.run")
                        Text(instruction.nwsCleaned)
                            .font(.body.weight(.medium))
                    }
                    .glassCard()
                    .overlay(alignment: .leading) {
                        Rectangle().fill(alert.severity.color).frame(width: 4)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                            .padding(.vertical, 12)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    CardHeader(title: "Details", systemImage: "text.alignleft")
                    Text(alert.description.nwsCleaned)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .glassCard()

                facts

                if let guideID = alert.kind.guideID, let guide = SafetyGuide.guide(id: guideID) {
                    Button { showGuide = guide } label: {
                        Label("Open the \(guide.title) safety guide", systemImage: guide.symbol)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(guide.color.opacity(0.25), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Theme.appBackground.ignoresSafeArea())
        .navigationTitle(alert.event)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: alert.shareText)
            }
        }
        .sheet(item: $showGuide) { guide in
            NavigationStack { SafetyGuideView(guide: guide) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: alert.kind.symbol)
                    .font(.largeTitle)
                    .symbolEffect(.pulse, options: .repeating, isActive: alert.severity >= .severe)
                Spacer()
                if alert.isDemo { DemoBadge() }
                Pill(text: alert.severity.rawValue.uppercased(), color: .white.opacity(0.25))
            }
            Text(alert.event).font(.title.weight(.bold))
            Text(alert.headline).font(.subheadline).opacity(0.9)
        }
        .foregroundStyle(.white)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [alert.severity.color, alert.severity.color.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private var facts: some View {
        VStack(spacing: 10) {
            FactRow(label: "Areas", value: alert.areaDescription)
            if let effective = alert.effective {
                FactRow(label: "Effective", value: effective.formatted(date: .abbreviated, time: .shortened))
            }
            if let expires = alert.expires {
                FactRow(label: "Expires", value: expires.formatted(date: .abbreviated, time: .shortened))
            }
            FactRow(label: "Urgency", value: alert.urgency)
            FactRow(label: "Certainty", value: alert.certainty)
            FactRow(label: "Issued by", value: alert.sender)
        }
        .glassCard()
    }
}

private struct FactRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label).foregroundStyle(.secondary).frame(width: 90, alignment: .leading)
            Text(value).frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
    }
}

/// Unmissable "take shelter now" card for tornado warnings.
struct TakeShelterCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("TAKE SHELTER NOW", systemImage: "house.lodge.fill")
                .font(.title3.weight(.heavy))
            ForEach([
                "Go to the lowest floor, in an interior room without windows.",
                "Put as many walls between you and the outside as you can.",
                "Cover your head and neck. Wear shoes.",
                "Mobile home or car? Get to a sturdy building now.",
            ], id: \.self) { tip in
                Label(tip, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
            }
        }
        .foregroundStyle(.black)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension String {
    /// NWS text is hard-wrapped at ~70 columns; rejoin lines within paragraphs.
    var nwsCleaned: String {
        components(separatedBy: "\n\n")
            .map { $0.replacingOccurrences(of: "\n", with: " ") }
            .joined(separator: "\n\n")
    }
}
