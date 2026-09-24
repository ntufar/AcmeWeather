import SwiftUI
import AVFoundation

/// Emergency light: camera torch, SOS in Morse code, or a bright screen.
struct FlashlightView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case steady = "Steady"
        case sos = "SOS"
        case screen = "Screen"
        var id: String { rawValue }
    }

    @State private var mode: Mode = .steady
    @State private var isOn = false
    @State private var lit = false

    private var hasTorch: Bool { AVCaptureDevice.default(for: .video)?.hasTorch ?? false }

    /// Screen mode, or SOS on a device without a flash, lights up the display.
    private var screenLit: Bool { isOn && lit && (mode == .screen || (mode == .sos && !hasTorch)) }

    var body: some View {
        ZStack {
            (screenLit ? Color.white : Color.clear)
                .background(Theme.appBackground)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Spacer()

                Button { isOn.toggle() } label: {
                    Image(systemName: isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .font(.system(size: 80))
                        .frame(width: 200, height: 200)
                        .background((isOn ? Color.yellow : Color.white.opacity(0.1)).gradient, in: Circle())
                        .foregroundStyle(isOn ? .black : .white)
                        .shadow(color: isOn ? .yellow.opacity(0.7) : .clear, radius: 30)
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.impact, trigger: isOn)
                .accessibilityLabel(isOn ? "Turn light off" : "Turn light on")

                Text(caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(screenLit ? .black : .secondary)
                    .padding(.horizontal, 30)

                Spacer()
            }
            .padding(.top)
        }
        .navigationTitle("Flashlight & SOS")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: "\(mode.rawValue)-\(isOn)") { await run() }
        .onDisappear { setTorch(false) }
    }

    private var caption: String {
        switch mode {
        case .steady: hasTorch ? "Uses your camera flash." : "No flash on this device — try Screen mode."
        case .sos: "Flashes · · · — — — · · · repeatedly. The universal distress signal."
        case .screen: "Turns your screen into a soft light. Tap SOS for signaling."
        }
    }

    private func run() async {
        setTorch(false)
        lit = false
        guard isOn else { return }
        switch mode {
        case .steady:
            setTorch(true)
        case .screen:
            lit = true
        case .sos:
            // Morse timing in units: dot = 1, dash = 3, gap between symbols = 1, between letters = 3, between words = 7.
            let unit = 0.2
            let pattern: [(on: Bool, units: Double)] =
                [(true, 1), (false, 1), (true, 1), (false, 1), (true, 1), (false, 3),
                 (true, 3), (false, 1), (true, 3), (false, 1), (true, 3), (false, 3),
                 (true, 1), (false, 1), (true, 1), (false, 1), (true, 1), (false, 7)]
            while !Task.isCancelled {
                for step in pattern {
                    if Task.isCancelled { break }
                    setTorch(step.on)
                    lit = step.on
                    try? await Task.sleep(for: .seconds(step.units * unit))
                }
            }
            setTorch(false)
        }
    }

    private func setTorch(_ on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
        } catch {
            // Torch busy or unavailable; screen mode still works.
        }
    }
}
