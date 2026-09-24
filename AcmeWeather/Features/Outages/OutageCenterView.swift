import SwiftUI

struct OutageCenterView: View {
    @Environment(AppState.self) private var app
    @State private var showReport = false

    var body: some View {
        let store = app.outages
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Statewide").font(.headline)
                        Spacer()
                        DemoBadge()
                    }
                    Text(store.totalCustomersOut.formatted())
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.peach)
                    Text("customers without power across \(store.countyOutages.count) counties")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button { showReport = true } label: {
                        Label("Report an Outage", systemImage: "bolt.slash.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(12)
                            .background(Theme.peach, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.white.opacity(0.06))

            if !store.reports.isEmpty {
                Section("My reports") {
                    ForEach(store.reports) { report in
                        OutageReportRow(report: report)
                    }
                    .onDelete { offsets in
                        offsets.map { store.reports[$0] }.forEach(store.delete)
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))
            }

            Section("By county") {
                ForEach(store.countyOutages.sorted { $0.customersOut > $1.customersOut }) { county in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(county.county).font(.headline)
                            Spacer()
                            Text(county.customersOut.formatted()).font(.headline.monospacedDigit())
                        }
                        ProgressView(value: county.percentOut, total: 0.1)
                            .tint(county.percentOut > 0.05 ? Theme.danger : Theme.peach)
                        Text("\(county.percentOut.formatted(.percent.precision(.fractionLength(1)))) of \(county.customersServed.formatted()) customers")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
            .listRowBackground(Color.white.opacity(0.06))

            if let guide = SafetyGuide.guide(id: "power") {
                Section {
                    NavigationLink {
                        SafetyGuideView(guide: guide)
                    } label: {
                        Label("Outage & generator safety", systemImage: "powerplug.fill")
                    }
                }
                .listRowBackground(Color.white.opacity(0.06))
            }
        }
        .appBackground()
        .navigationTitle("Power Outages")
        .sheet(isPresented: $showReport) { OutageReportView() }
    }
}

private struct OutageReportRow: View {
    let report: OutageReport

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let stage = report.stage(at: context.date)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(report.referenceNumber).font(.headline.monospacedDigit())
                    Spacer()
                    Text(report.submittedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("\(report.cause.rawValue) · \(report.utility.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 0) {
                    ForEach(OutageStage.allCases, id: \.self) { step in
                        let reached = step <= stage
                        VStack(spacing: 4) {
                            Image(systemName: step.symbol)
                                .font(.caption)
                                .frame(width: 28, height: 28)
                                .background(reached ? Theme.pine : Color.white.opacity(0.1), in: Circle())
                            if step == stage {
                                Circle().fill(Theme.peach).frame(width: 5, height: 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                Label(stage.title, systemImage: stage.symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(stage == .restored ? Theme.pine : Theme.peachLight)
            }
            .padding(.vertical, 4)
        }
    }
}
