import SwiftUI

struct PlacePickerView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var grouped: [(region: String, places: [GeorgiaPlace])] {
        let filtered = GeorgiaPlace.all.filter {
            query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) || $0.region.localizedCaseInsensitiveContains(query)
        }
        let regions = Dictionary(grouping: filtered, by: \.region)
        return regions.keys.sorted().map { ($0, regions[$0]!) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        app.location.requestPermission()
                        select(.currentLocation)
                    } label: {
                        Label {
                            VStack(alignment: .leading) {
                                Text("My Location")
                                if app.location.isDenied {
                                    Text("Location access is off — enable it in Settings")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: "location.fill").foregroundStyle(Theme.sky)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }

                ForEach(grouped, id: \.region) { group in
                    Section(group.region) {
                        ForEach(group.places) { place in
                            Button { select(.place(place)) } label: {
                                HStack {
                                    Text(place.name).foregroundStyle(.white)
                                    Spacer()
                                    if app.placeSelection == .place(place) {
                                        Image(systemName: "checkmark").foregroundStyle(Theme.peach)
                                    }
                                }
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.06))
                }
            }
            .appBackground()
            .searchable(text: $query, prompt: "Search Georgia cities")
            .navigationTitle("Choose a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func select(_ selection: PlaceSelection) {
        app.placeSelection = selection
        dismiss()
    }
}
