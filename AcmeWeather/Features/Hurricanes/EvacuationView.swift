import SwiftUI

struct EvacuationView: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Run from water, hide from wind", systemImage: "water.waves")
                        .font(.headline)
                    Text("Storm surge is the greatest threat to life along Georgia's 100 miles of coastline and the Golden Isles. If officials order an evacuation for your area, leave.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Theme.peach.opacity(0.18))

            Section("Coastal counties") {
                ForEach(CoastalCounty.all) { county in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("\(county.name) County").font(.headline)
                            Spacer()
                            Text(county.seat).font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(county.routes, id: \.self) { route in
                            Label(route, systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.subheadline)
                                .foregroundStyle(Theme.peachLight)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowBackground(Color.white.opacity(0.06))

            Section("Official sources") {
                Link(destination: URL(string: "https://gema.georgia.gov")!) {
                    Label("GEMA/HS — evacuation orders & zones", systemImage: "shield.lefthalf.filled")
                }
                Link(destination: URL(string: "https://511ga.org")!) {
                    Label("Georgia 511 — live traffic & contraflow", systemImage: "car.fill")
                }
                Link(destination: URL(string: "https://www.nhc.noaa.gov")!) {
                    Label("National Hurricane Center", systemImage: "hurricane")
                }
            }
            .listRowBackground(Color.white.opacity(0.06))

            Section {
                Text("Routes shown are general guidance. Always follow the routes and instructions given by GEMA/HS, GDOT and your county emergency management agency.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
        .appBackground()
        .navigationTitle("Know Your Zone")
    }
}
