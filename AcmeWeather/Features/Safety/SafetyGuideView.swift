import SwiftUI

struct SafetyGuideView: View {
    let guide: SafetyGuide

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: guide.symbol)
                        .font(.system(size: 44))
                        .foregroundStyle(guide.color)
                    Text(guide.title).font(.largeTitle.weight(.bold))
                    Text(guide.tagline).font(.title3).foregroundStyle(guide.color)
                }
                .padding(.bottom, 4)

                ForEach(guide.sections, id: \.self) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        Label(section.title, systemImage: section.symbol)
                            .font(.headline)
                            .foregroundStyle(guide.color)
                        ForEach(section.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 10) {
                                Circle().fill(guide.color).frame(width: 6, height: 6).padding(.top, 7)
                                Text(tip).font(.body).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .glassCard()
                }

                Text("Sources: NOAA/National Weather Service, Ready.gov, GEMA/HS. In an emergency, call 911.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Theme.appBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
}
