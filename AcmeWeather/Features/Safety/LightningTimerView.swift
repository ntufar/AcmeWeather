import SwiftUI

/// Flash-to-bang timer: sound travels about a mile every 5 seconds, so the
/// gap between lightning and thunder tells you how far away the strike was.
struct LightningTimerView: View {
    enum Phase { case ready, timing(Date), result(TimeInterval) }

    @State private var phase: Phase = .ready
    @State private var flash = false

    var body: some View {
        ZStack {
            Theme.appBackground.ignoresSafeArea()
            Color.white.opacity(flash ? 0.6 : 0).ignoresSafeArea()

            VStack(spacing: 28) {
                Text("Flash-to-Bang")
                    .font(.largeTitle.weight(.bold))
                Text(instructions)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                display
                    .frame(height: 170)

                Button(action: tap) {
                    Text(buttonTitle)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .frame(width: 220, height: 220)
                        .background(buttonColor.gradient, in: Circle())
                        .foregroundStyle(.black)
                        .shadow(color: buttonColor.opacity(0.6), radius: 24)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact(weight: .heavy), trigger: buttonTitle)

                Text("If you can hear thunder, you're close enough to be struck. Go indoors and wait 30 minutes after the last thunder.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 30)
            }
            .padding()
        }
    }

    private var instructions: String {
        switch phase {
        case .ready: "Tap FLASH the moment you see lightning."
        case .timing: "Now tap BOOM when you hear the thunder."
        case .result: "Tap again to time another strike."
        }
    }

    private var buttonTitle: String {
        switch phase {
        case .ready, .result: "⚡️ FLASH"
        case .timing: "💥 BOOM"
        }
    }

    private var buttonColor: Color {
        switch phase {
        case .timing: Theme.peach
        default: .yellow
        }
    }

    @ViewBuilder
    private var display: some View {
        switch phase {
        case .ready:
            Image(systemName: "cloud.bolt.fill")
                .font(.system(size: 90))
                .symbolRenderingMode(.multicolor)
        case .timing(let start):
            TimelineView(.periodic(from: start, by: 0.1)) { context in
                let seconds = context.date.timeIntervalSince(start)
                VStack {
                    Text(String(format: "%.1f s", seconds))
                        .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    Text(String(format: "≈ %.1f miles and counting…", seconds / 5))
                        .foregroundStyle(.secondary)
                }
            }
        case .result(let seconds):
            let miles = seconds / 5
            VStack(spacing: 6) {
                Text(String(format: "%.1f miles", miles))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(miles < 6 ? Theme.danger : .yellow)
                Text(String(format: "%.1f seconds between flash and thunder", seconds))
                    .foregroundStyle(.secondary)
                Label(miles < 6 ? "Danger zone — get indoors now!" : "Storm is close enough to strike. Head inside.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.headline)
                    .foregroundStyle(miles < 6 ? Theme.danger : .orange)
            }
        }
    }

    private func tap() {
        switch phase {
        case .ready, .result:
            phase = .timing(.now)
            withAnimation(.easeOut(duration: 0.08)) { flash = true }
            withAnimation(.easeIn(duration: 0.4).delay(0.08)) { flash = false }
        case .timing(let start):
            withAnimation(.spring) { phase = .result(Date.now.timeIntervalSince(start)) }
        }
    }
}
