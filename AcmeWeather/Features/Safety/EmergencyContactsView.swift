import SwiftUI

struct EmergencyContactsView: View {
    var body: some View {
        List {
            ForEach(EmergencyContact.all) { contact in
                HStack(spacing: 14) {
                    Image(systemName: contact.symbol)
                        .font(.title3)
                        .foregroundStyle(contact.phone == "911" ? Theme.danger : Theme.peach)
                        .frame(width: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(.headline)
                        Text(contact.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let phone = contact.phone, let url = URL(string: "tel://\(phone)") {
                        Link(destination: url) {
                            Image(systemName: "phone.fill")
                                .padding(10)
                                .background(Theme.pine, in: Circle())
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Call \(contact.name)")
                    }
                    if let url = contact.url {
                        Link(destination: url) {
                            Image(systemName: "safari.fill")
                                .padding(10)
                                .background(Theme.sky.opacity(0.4), in: Circle())
                                .foregroundStyle(.white)
                        }
                        .accessibilityLabel("Open \(contact.name) website")
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.white.opacity(0.06))
            }

            Section {
                Text("To report an outage directly, call the number on your power bill or use your utility's website or app. Georgia Power, your EMC, or your city utility can give the most accurate restoration times.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)
        }
        .appBackground()
        .navigationTitle("Emergency Contacts")
    }
}
