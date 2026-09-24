import SwiftUI

struct EmergencyKitView: View {
    @Environment(AppState.self) private var app

    var body: some View {
        let kit = app.kit
        List {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        ProgressRing(progress: kit.progress, lineWidth: 8, gradient: [Theme.peach, .yellow, Theme.pine])
                        Text("\(Int(kit.progress * 100))%").font(.headline.monospacedDigit())
                    }
                    .frame(width: 64, height: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(kit.checked.count) of \(KitCategory.totalItems) items packed").font(.headline)
                        Text("Based on Ready.gov's basic disaster kit, plus a few Georgia essentials.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            .listRowBackground(Color.white.opacity(0.06))

            ForEach(KitCategory.all) { category in
                Section {
                    ForEach(category.items) { item in
                        Button {
                            withAnimation(.snappy) { kit.toggle(item) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: kit.isChecked(item) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(kit.isChecked(item) ? Theme.pine : .secondary)
                                    .contentTransition(.symbolEffect(.replace))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.title)
                                        .strikethrough(kit.isChecked(item), color: .secondary)
                                        .foregroundStyle(.white)
                                    if let detail = item.detail {
                                        Text(detail).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                        .sensoryFeedback(.selection, trigger: kit.isChecked(item))
                    }
                } header: {
                    Label(category.title, systemImage: category.symbol)
                }
                .listRowBackground(Color.white.opacity(0.06))
            }

            Section {
                Button("Reset checklist", role: .destructive) { kit.reset() }
            }
            .listRowBackground(Color.white.opacity(0.06))
        }
        .appBackground()
        .navigationTitle("Emergency Kit")
    }
}
