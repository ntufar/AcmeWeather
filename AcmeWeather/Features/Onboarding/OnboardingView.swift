import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var app
    let onFinish: () -> Void
    @State private var page = 0

    private struct Page {
        let symbol: String
        let title: String
        let body: String
        let condition: WeatherCondition
        let isDay: Bool
    }

    private let pages: [Page] = [
        Page(symbol: "sun.max.fill", title: "Hey, Georgia 🍑",
             body: "Hyper-local weather built for the Peach State, from the Blue Ridge to the Golden Isles.",
             condition: .clear, isDay: true),
        Page(symbol: "dot.radiowaves.left.and.right", title: "Live Radar",
             body: "Animated radar, warning polygons and hurricane cones on one map. Pinch, zoom and jump to your location.",
             condition: .rain, isDay: true),
        Page(symbol: "exclamationmark.triangle.fill", title: "Alerts That Matter",
             body: "Tornado, flood and hurricane warnings straight from the National Weather Service, with clear steps to stay safe.",
             condition: .thunderstorm, isDay: false),
        Page(symbol: "hurricane", title: "Ready for Anything",
             body: "Hurricane tracking, evacuation routes, outage reporting, an emergency kit and your family plan in one place.",
             condition: .partlyCloudy, isDay: false),
    ]

    var body: some View {
        ZStack {
            WeatherBackground(condition: pages[page].condition, isDay: pages[page].isDay)
                .animation(.easeInOut(duration: 0.6), value: page)

            VStack {
                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { index in
                        let p = pages[index]
                        VStack(spacing: 24) {
                            Spacer()
                            Image(systemName: p.symbol)
                                .font(.system(size: 96))
                                .symbolRenderingMode(.multicolor)
                                .foregroundStyle(.white)
                                .symbolEffect(.bounce, value: page == index)
                            Text(p.title)
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                            Text(p.body)
                                .font(.title3)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.85))
                                .padding(.horizontal, 32)
                            Spacer()
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                VStack(spacing: 12) {
                    if page == pages.count - 1 {
                        Button {
                            Task {
                                app.location.requestPermission()
                                await app.notifications.requestAuthorization()
                                onFinish()
                            }
                        } label: {
                            Text("Enable Location & Alerts")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Theme.peachGradient, in: RoundedRectangle(cornerRadius: 16))
                                .foregroundStyle(.black)
                        }
                        Button("Maybe later", action: onFinish)
                            .foregroundStyle(.white.opacity(0.8))
                    } else {
                        Button {
                            withAnimation { page += 1 }
                        } label: {
                            Text("Next")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.white.opacity(0.2), in: RoundedRectangle(cornerRadius: 16))
                        }
                        Button("Skip", action: onFinish)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .foregroundStyle(.white)
        }
    }
}
