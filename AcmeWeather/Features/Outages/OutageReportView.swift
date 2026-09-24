import SwiftUI
import PhotosUI

/// Multi-step-feeling single form for reporting an outage. Submission is
/// simulated by `OutageStore` and nothing leaves the device.
struct OutageReportView: View {
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var useCurrentLocation = true
    @State private var address = ""
    @State private var utility: Utility = .georgiaPower
    @State private var cause: OutageCause = .unknown
    @State private var neighborsAffected = false
    @State private var notes = ""
    @State private var phone = ""
    @State private var wantsUpdates = true
    @State private var photoItem: PhotosPickerItem?
    @State private var photo: Image?
    @State private var isSubmitting = false
    @State private var submitted: OutageReport?

    private var canSubmit: Bool {
        (useCurrentLocation && app.location.coordinate != nil) || !address.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if let submitted {
                    OutageSubmittedView(report: submitted) { dismiss() }
                } else {
                    form
                }
            }
            .navigationTitle(submitted == nil ? "Report an Outage" : "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if submitted == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: submitted)
    }

    private var form: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.slash.fill")
                        .font(.title)
                        .foregroundStyle(Theme.peach)
                    Text("Tell us what's happening. We'll route it to your utility and keep you posted.")
                        .font(.subheadline)
                }
                Label("Demo — reports are stored on this device only", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if cause.isHazard {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Stay at least 30 feet away", systemImage: "exclamationmark.octagon.fill")
                            .font(.headline)
                        Text("Treat every downed line as live. Keep people and pets away and call 911.")
                            .font(.subheadline)
                        Link(destination: URL(string: "tel://911")!) {
                            Label("Call 911", systemImage: "phone.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(Theme.danger)
                        }
                    }
                    .foregroundStyle(.white)
                }
                .listRowBackground(Theme.danger)
            }

            Section("Where is the outage?") {
                Toggle("Use my current location", isOn: $useCurrentLocation)
                    .onChange(of: useCurrentLocation) { _, useIt in
                        if useIt { app.location.requestPermission() }
                    }
                if useCurrentLocation {
                    if let c = app.location.coordinate {
                        Label(String(format: "%.4f, %.4f · near %@", c.latitude, c.longitude, GeorgiaPlace.nearest(to: c).name),
                              systemImage: "location.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Waiting for location… or enter an address below.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                TextField("Street address, city", text: $address, axis: .vertical)
                    .textContentType(.fullStreetAddress)
            }

            Section("Your electric provider") {
                Picker("Utility", selection: $utility) {
                    ForEach(Utility.allCases) { Text($0.rawValue).tag($0) }
                }
            }

            Section("What do you see?") {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(OutageCause.allCases) { option in
                        Button {
                            withAnimation(.snappy) { cause = option }
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: option.symbol).font(.title3)
                                Text(option.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, minHeight: 70)
                            .background(
                                (option == cause ? (option.isHazard ? Theme.danger : Theme.peach) : Color.white.opacity(0.06)),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                            .foregroundStyle(option == cause ? .black : .white)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                Toggle("Neighbors are out too", isOn: $neighborsAffected)
            }

            Section("Photo (optional)") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photo == nil ? "Add a photo" : "Change photo", systemImage: "camera.fill")
                }
                if let photo {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    guard let data = try? await item?.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    photo = Image(uiImage: image)
                }
            }

            Section("Details") {
                TextField("Anything else? (e.g. heard a loud bang)", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Mobile number for updates", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                Toggle("Text me restoration updates", isOn: $wantsUpdates)
            }

            Section {
                Button {
                    Task { await submit() }
                } label: {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView().tint(.black)
                        } else {
                            Label("Submit Report", systemImage: "paperplane.fill").font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
                .disabled(!canSubmit || isSubmitting)
                .listRowBackground(canSubmit ? Theme.peach : Color.gray.opacity(0.3))
                .foregroundStyle(.black)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.appBackground.ignoresSafeArea())
    }

    private func submit() async {
        isSubmitting = true
        let draft = OutageReport(
            referenceNumber: "",
            submittedAt: .now,
            coordinate: useCurrentLocation ? app.location.coordinate : nil,
            address: address,
            utility: utility,
            cause: cause,
            neighborsAffected: neighborsAffected,
            notes: notes,
            hasPhoto: photo != nil,
            contactPhone: phone,
            wantsUpdates: wantsUpdates
        )
        let report = await app.outages.submit(draft)
        isSubmitting = false
        withAnimation(.spring) { submitted = report }
    }
}

private struct OutageSubmittedView: View {
    let report: OutageReport
    let done: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 90))
                .foregroundStyle(Theme.pine)
                .symbolEffect(.bounce, value: appeared)
                .scaleEffect(appeared ? 1 : 0.4)
                .animation(.spring(duration: 0.6, bounce: 0.5), value: appeared)
            Text("Report received").font(.largeTitle.weight(.bold))
            Text("Reference \(report.referenceNumber)")
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.peachLight)
            Text("Estimated restoration: \(report.estimatedRestoration.formatted(date: .omitted, time: .shortened)) (simulated). Track progress in Be Ready → Power Outages.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            Spacer()
            Button(action: done) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.peach, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.black)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.appBackground.ignoresSafeArea())
        .onAppear { appeared = true }
    }
}
