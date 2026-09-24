import SwiftUI

struct FamilyPlanView: View {
    @Environment(AppState.self) private var app
    @State private var showAddMember = false

    var body: some View {
        @Bindable var family = app.family

        Form {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    ProgressView(value: family.plan.completion)
                        .tint(Theme.sky)
                    Text("Your family may not be together when disaster strikes. Decide now how you'll reach each other and where you'll meet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Household") {
                ForEach(family.plan.members) { member in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name).font(.headline)
                        if !member.phone.isEmpty {
                            Text(member.phone).font(.subheadline).foregroundStyle(.secondary)
                        }
                        if !member.notes.isEmpty {
                            Text(member.notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { family.plan.members.remove(atOffsets: $0) }
                Button {
                    showAddMember = true
                } label: {
                    Label("Add family member", systemImage: "person.badge.plus")
                }
            }

            Section {
                TextField("e.g. Downstairs hall closet", text: $family.plan.shelterRoom)
            } header: {
                Text("Tornado shelter spot")
            } footer: {
                Text("Lowest floor, interior room, no windows.")
            }

            Section("Meeting places") {
                TextField("Near home (e.g. the Smiths' mailbox)", text: $family.plan.meetingPlaceNearby)
                TextField("Outside the neighborhood (e.g. church on Main St)", text: $family.plan.meetingPlaceOutOfTown)
            }

            Section {
                TextField("Name", text: $family.plan.outOfTownContactName)
                TextField("Phone", text: $family.plan.outOfTownContactPhone)
                    .keyboardType(.phonePad)
            } header: {
                Text("Out-of-town contact")
            } footer: {
                Text("Long-distance calls and texts often go through when local lines are jammed.")
            }

            Section("Evacuation") {
                TextField("Where would you go? (e.g. Aunt May's in Macon)", text: $family.plan.evacuationDestination)
                TextField("Pet plan (carrier, pet-friendly hotel…)", text: $family.plan.petPlan)
            }

            Section {
                ShareLink(item: planSummary) {
                    Label("Share plan with family", systemImage: "square.and.arrow.up")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.appBackground.ignoresSafeArea())
        .navigationTitle("Family Plan")
        .sheet(isPresented: $showAddMember) {
            AddMemberSheet { family.plan.members.append($0) }
                .presentationDetents([.medium])
        }
    }

    private var planSummary: String {
        let plan = app.family.plan
        var lines = ["🏠 Our Family Emergency Plan"]
        if !plan.members.isEmpty {
            lines.append("\nFamily:")
            lines += plan.members.map { "• \($0.name)\($0.phone.isEmpty ? "" : " — \($0.phone)")" }
        }
        func add(_ title: String, _ value: String) {
            if !value.isEmpty { lines.append("\(title): \(value)") }
        }
        lines.append("")
        add("🌪️ Tornado shelter", plan.shelterRoom)
        add("📍 Meet near home", plan.meetingPlaceNearby)
        add("📍 Meet outside neighborhood", plan.meetingPlaceOutOfTown)
        add("☎️ Out-of-town contact", [plan.outOfTownContactName, plan.outOfTownContactPhone].filter { !$0.isEmpty }.joined(separator: " "))
        add("🚗 Evacuate to", plan.evacuationDestination)
        add("🐾 Pets", plan.petPlan)
        return lines.joined(separator: "\n")
    }
}

private struct AddMemberSheet: View {
    let onAdd: (FamilyMember) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
                TextField("Phone", text: $phone).keyboardType(.phonePad)
                TextField("Medical needs, school, work…", text: $notes, axis: .vertical)
            }
            .navigationTitle("Family Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(FamilyMember(name: name, phone: phone, notes: notes))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
