import SwiftUI
import MapKit

struct HurricaneCenterView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        @Bindable var app = app

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    SeasonHeader()

                    if app.storms.isEmpty {
                        quietTropics
                    } else {
                        TropicsMap(storms: app.storms)
                        ForEach(app.storms) { storm in
                            NavigationLink(value: storm) {
                                StormCard(storm: storm, miles: storm.position.distanceMiles(to: app.coordinate))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if let error = app.stormsError {
                        Label(error, systemImage: "wifi.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }

                    PrepTimeline()

                    NavigationLink {
                        EvacuationView()
                    } label: {
                        ActionTile("Know Your Zone", subtitle: "Georgia's coastal counties & evacuation routes",
                                   systemImage: "car.rear.road.lane.dashed", tint: Theme.peach)
                    }
                    .buttonStyle(.plain)

                    SaffirSimpsonCard()

                    if let guide = SafetyGuide.guide(id: "hurricane") {
                        NavigationLink {
                            SafetyGuideView(guide: guide)
                        } label: {
                            ActionTile("Hurricane Safety Guide", subtitle: guide.tagline, systemImage: "book.fill", tint: guide.color)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Theme.appBackground.ignoresSafeArea())
            .navigationTitle("Tropics")
            .navigationDestination(for: Storm.self) { StormDetailView(storm: $0) }
            .refreshable { await app.refreshStorms() }
        }
    }

    private var quietTropics: some View {
        @Bindable var app = app
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(systemName: "sun.horizon.fill")
                    .font(.largeTitle)
                    .symbolRenderingMode(.multicolor)
                VStack(alignment: .leading) {
                    Text("The Atlantic is quiet").font(.headline)
                    Text("No active tropical cyclones right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $app.demoMode) {
                VStack(alignment: .leading) {
                    Text("Try Demo Mode").font(.subheadline.weight(.semibold))
                    Text("See a simulated hurricane heading for the Georgia coast.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(Theme.peach)
        }
        .glassCard()
    }
}

private struct SeasonHeader: View {
    var body: some View {
        let calendar = Calendar.current
        let now = Date.now
        let year = calendar.component(.year, from: now)
        let start = calendar.date(from: DateComponents(year: year, month: 6, day: 1))!
        let end = calendar.date(from: DateComponents(year: year, month: 11, day: 30))!
        let inSeason = (start...end).contains(now)
        let progress = inSeason ? now.timeIntervalSince(start) / end.timeIntervalSince(start) : (now > end ? 1 : 0)
        let daysLeft = calendar.dateComponents([.day], from: now, to: end).day ?? 0
        let peak = calendar.date(from: DateComponents(year: year, month: 9, day: 10))!

        return VStack(alignment: .leading, spacing: 12) {
            Text("\(String(year)) Atlantic Hurricane Season")
                .font(.headline)
            Text(inSeason ? "\(daysLeft) days left · ends November 30" : (now < start ? "Season starts June 1" : "Season ended November 30"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                let peakX = peak.timeIntervalSince(start) / end.timeIntervalSince(start) * geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.12))
                    Capsule().fill(Theme.peachGradient).frame(width: max(8, progress * geo.size.width))
                    Rectangle().fill(.white).frame(width: 2, height: 16).offset(x: peakX)
                }
            }
            .frame(height: 10)
            HStack {
                Text("Jun 1")
                Spacer()
                Text("Peak · Sep 10")
                Spacer()
                Text("Nov 30")
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

struct TropicsMap: View {
    let storms: [Storm]

    var body: some View {
        let allPoints = storms.flatMap { $0.forecastTrack.map(\.coordinate) + [$0.position] }
            + [GeorgiaPlace.atlanta.coordinate, Coordinate(31.0, -81.4)]
        Map(initialPosition: .region(.fitting(allPoints, padding: 1.3))) {
            ForEach(storms) { storm in
                StormMapContent(storm: storm)
            }
            UserAnnotation()
        }
        .mapStyle(.imagery(elevation: .flat))
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(alignment: .topLeading) {
            Label("Forecast cone", systemImage: "cone")
                .font(.caption.weight(.semibold))
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(10)
        }
    }
}

/// Cone, track line and track points for a storm — shared by the tropics map and storm detail.
struct StormMapContent: MapContent {
    let storm: Storm

    var body: some MapContent {
        let cone = storm.cone
        if cone.count > 2 {
            MapPolygon(coordinates: cone.map(\.cl))
                .foregroundStyle(.white.opacity(0.18))
                .stroke(.white.opacity(0.8), lineWidth: 1)
        }
        if storm.forecastTrack.count > 1 {
            MapPolyline(coordinates: storm.forecastTrack.map(\.coordinate.cl))
                .stroke(.white, lineWidth: 2)
        }
        ForEach(storm.forecastTrack.dropFirst()) { point in
            Annotation(point.label, coordinate: point.coordinate.cl) {
                Circle()
                    .fill(point.category.color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
            }
        }
        Annotation(storm.name, coordinate: storm.position.cl) {
            SpinningStormIcon(color: storm.category.color, size: 36)
        }
    }
}

struct StormCard: View {
    let storm: Storm
    let miles: Double

    var body: some View {
        HStack(spacing: 14) {
            SpinningStormIcon(color: storm.category.color, size: 54)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(storm.displayName).font(.headline)
                    if storm.isDemo { DemoBadge() }
                }
                Text(storm.category.longLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(storm.category.color)
                Text("\(storm.windMph) mph · \(storm.movementText) · \(Int(miles).formatted()) mi away")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

private struct PrepTimeline: View {
    private let steps: [(String, String, String)] = [
        ("5 days", "binoculars.fill", "Watch the forecast. Check your kit and refill prescriptions."),
        ("72 hours", "cart.fill", "Stock water & food, fill gas tanks, get cash, charge batteries."),
        ("48 hours", "hammer.fill", "Secure outdoor items, install shutters, review evacuation routes."),
        ("36 hours", "megaphone.fill", "Hurricane Watch possible. Be ready to leave if you're in a zone."),
        ("Evacuation order", "car.fill", "Go. Tell your out-of-town contact where you're headed."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CardHeader(title: "Before a storm hits", systemImage: "timer")
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        Image(systemName: step.1)
                            .font(.caption.weight(.bold))
                            .frame(width: 30, height: 30)
                            .background(Theme.peach.opacity(0.25), in: Circle())
                            .foregroundStyle(Theme.peachLight)
                        if index < steps.count - 1 {
                            Rectangle().fill(.white.opacity(0.15)).frame(width: 2).frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.0).font(.subheadline.weight(.bold))
                        Text(step.2).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 6)
                }
            }
        }
        .glassCard()
    }
}

struct SaffirSimpsonCard: View {
    @State private var selected = 3

    var body: some View {
        let entry = StormCategory.saffirSimpson[selected - 1]
        let category = StormCategory.hurricane(selected)
        VStack(alignment: .leading, spacing: 12) {
            CardHeader(title: "Saffir-Simpson scale", systemImage: "gauge.with.needle.fill")
            HStack(spacing: 6) {
                ForEach(1...5, id: \.self) { cat in
                    Button {
                        withAnimation(.snappy) { selected = cat }
                    } label: {
                        Text("\(cat)")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 40)
                            .background(
                                StormCategory.hurricane(cat).color.opacity(cat == selected ? 1 : 0.3),
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .foregroundStyle(cat == selected ? .black : .white)
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Category \(selected) · \(entry.winds)")
                .font(.headline)
                .foregroundStyle(category.color)
            Text(entry.damage)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Text("Storm surge and inland flooding cause most hurricane deaths — regardless of category.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}
