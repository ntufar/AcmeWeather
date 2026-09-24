import SwiftUI

struct SafetyHubView: View {
    @Environment(AppState.self) private var app

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    /// Gamified readiness: kit, family plan and alerts each count.
    private var readiness: Double {
        let alerts = app.notifications.isAuthorized ? 1.0 : 0.0
        return app.kit.progress * 0.45 + app.family.plan.completion * 0.4 + alerts * 0.15
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    readinessCard

                    LazyVGrid(columns: columns, spacing: 12) {
                        NavigationLink { OutageCenterView() } label: {
                            ActionTile("Power Outages", subtitle: outageSubtitle, systemImage: "bolt.slash.fill", tint: Theme.peach)
                        }
                        NavigationLink { EmergencyKitView() } label: {
                            ActionTile("Emergency Kit", subtitle: "\(Int(app.kit.progress * 100))% packed",
                                       systemImage: "shippingbox.fill", tint: Theme.pine)
                        }
                        NavigationLink { FamilyPlanView() } label: {
                            ActionTile("Family Plan", subtitle: "\(Int(app.family.plan.completion * 100))% complete",
                                       systemImage: "figure.2.and.child.holdinghands", tint: Theme.sky)
                        }
                        NavigationLink { LightningTimerView() } label: {
                            ActionTile("Lightning Timer", subtitle: "How far is that storm?", systemImage: "bolt.fill", tint: .yellow)
                        }
                        NavigationLink { FlashlightView() } label: {
                            ActionTile("Flashlight & SOS", subtitle: "Light and signal", systemImage: "flashlight.on.fill", tint: .white)
                        }
                        NavigationLink { EmergencyContactsView() } label: {
                            ActionTile("Emergency Contacts", subtitle: "911, 211, 511 & more", systemImage: "phone.fill", tint: Theme.danger)
                        }
                    }
                    .buttonStyle(.plain)

                    imSafeCard

                    VStack(alignment: .leading, spacing: 12) {
                        CardHeader(title: "Safety guides", systemImage: "book.fill")
                        ForEach(SafetyGuide.all) { guide in
                            NavigationLink { SafetyGuideView(guide: guide) } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: guide.symbol)
                                        .font(.title3)
                                        .foregroundStyle(guide.color)
                                        .frame(width: 40, height: 40)
                                        .background(guide.color.opacity(0.18), in: RoundedRectangle(cornerRadius: 10))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(guide.title).font(.headline)
                                        Text(guide.tagline).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .glassCard()
                }
                .padding()
            }
            .background(Theme.appBackground.ignoresSafeArea())
            .navigationTitle("Be Ready")
        }
    }

    private var outageSubtitle: String {
        let active = app.outages.activeReports.count
        return active > 0 ? "\(active) active report\(active == 1 ? "" : "s")" : "Report & track"
    }

    private var readinessCard: some View {
        HStack(spacing: 20) {
            ZStack {
                ProgressRing(progress: readiness, lineWidth: 12, gradient: [Theme.danger, Theme.peach, .yellow, Theme.pine])
                VStack(spacing: 0) {
                    Text("\(Int(readiness * 100))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("READY").font(.caption2.weight(.bold)).foregroundStyle(.secondary)
                }
            }
            .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: 8) {
                Text("Your Readiness Score").font(.headline)
                ReadinessRow(done: app.kit.progress >= 0.8, text: "Pack your emergency kit")
                ReadinessRow(done: app.family.plan.completion >= 0.8, text: "Make a family plan")
                ReadinessRow(done: app.notifications.isAuthorized, text: "Turn on severe alerts")
            }
        }
        .glassCard()
    }

    private var imSafeCard: some View {
        let place = app.placeSubtitle.hasPrefix("Near") ? app.placeSubtitle.lowercased() : "in \(app.placeTitle)"
        return VStack(alignment: .leading, spacing: 10) {
            Label("Let family know you're OK", systemImage: "heart.fill")
                .font(.headline)
            Text("One tap sends an \"I'm safe\" message with your location through Messages, WhatsApp or any app.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ShareLink(item: "I'm safe ✅ — I'm \(place). I'll check in again soon. (Sent from Acme Weather)") {
                Label("I'm Safe", systemImage: "checkmark.shield.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Theme.pine, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
            }
        }
        .glassCard()
    }
}

private struct ReadinessRow: View {
    let done: Bool
    let text: String

    var body: some View {
        Label(text, systemImage: done ? "checkmark.circle.fill" : "circle")
            .font(.subheadline)
            .foregroundStyle(done ? Theme.pine : .white.opacity(0.8))
    }
}
