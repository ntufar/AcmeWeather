import SwiftUI

/// Animated sky that reflects current conditions: drifting clouds, rain,
/// snow, twinkling stars, a glowing sun and lightning flashes.
struct WeatherBackground: View {
    let condition: WeatherCondition
    let isDay: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                if isDay && condition.showsSun {
                    drawSun(in: &context, size: size, t: t)
                }
                if !isDay && condition.showsStars {
                    drawStars(in: &context, size: size, t: t)
                }
                if condition.cloudCover > 0 {
                    drawClouds(in: &context, size: size, t: t)
                }
                switch condition.particle {
                case .rain(let heavy): drawRain(in: &context, size: size, t: t, heavy: heavy)
                case .snow: drawSnow(in: &context, size: size, t: t)
                case .none: break
                }
                if condition.hasLightning {
                    drawLightning(in: &context, size: size, t: t)
                }
            }
        }
        .background(
            LinearGradient(colors: condition.gradient(isDay: isDay), startPoint: .top, endPoint: .bottom)
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Layers

    private func drawSun(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let center = CGPoint(x: size.width * 0.82, y: size.height * 0.12)
        let pulse = 1 + 0.06 * sin(t * 0.8)
        let radius = size.width * 0.55 * pulse
        let rect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                Gradient(colors: [Color.yellow.opacity(0.55), Color.orange.opacity(0.18), .clear]),
                center: center, startRadius: 0, endRadius: radius
            )
        )
    }

    private func drawStars(in context: inout GraphicsContext, size: CGSize, t: Double) {
        for i in 0..<70 {
            let x = fract(sin(Double(i) * 12.9898) * 43758.5453) * size.width
            let y = fract(sin(Double(i) * 78.233) * 12345.6789) * size.height * 0.6
            let twinkle = 0.35 + 0.65 * abs(sin(t * (0.5 + Double(i % 7) * 0.2) + Double(i)))
            let r = 0.6 + Double(i % 3) * 0.5
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                with: .color(.white.opacity(twinkle * 0.8))
            )
        }
    }

    private func drawClouds(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let count = Int(condition.cloudCover * 7) + 2
        let tint: Color = condition.hasLightning || condition == .heavyRain
            ? Color(white: 0.35) : Color(white: isDay ? 1 : 0.6)
        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 28))
            for i in 0..<count {
                let seed = Double(i) * 3.17
                let width = size.width * (0.5 + fract(sin(seed) * 999) * 0.5)
                let speed = 6 + fract(sin(seed * 2.1) * 777) * 10
                let span = size.width + width
                let x = (fract(sin(seed * 5.3) * 555) * span + t * speed).truncatingRemainder(dividingBy: span) - width
                let y = size.height * (0.02 + fract(sin(seed * 7.7) * 333) * 0.35)
                let rect = CGRect(x: x, y: y, width: width, height: width * 0.38)
                layer.fill(Path(ellipseIn: rect), with: .color(tint.opacity(0.10 + condition.cloudCover * 0.14)))
            }
        }
    }

    private func drawRain(in context: inout GraphicsContext, size: CGSize, t: Double, heavy: Bool) {
        let drops = heavy ? 220 : 110
        for i in 0..<drops {
            let rx = fract(sin(Double(i) * 12.9898) * 43758.5453)
            let ry = fract(sin(Double(i) * 4.1414) * 24634.6345)
            let speed = (heavy ? 700 : 480) + rx * 280
            let x = (rx * (size.width + 60) + t * 60).truncatingRemainder(dividingBy: size.width + 60) - 30
            let y = (ry * (size.height + 40) + t * speed).truncatingRemainder(dividingBy: size.height + 40) - 20
            var drop = Path()
            drop.move(to: CGPoint(x: x, y: y))
            drop.addLine(to: CGPoint(x: x - 3, y: y + (heavy ? 18 : 12)))
            context.stroke(drop, with: .color(.white.opacity(0.18 + ry * 0.3)), lineWidth: 1.1)
        }
    }

    private func drawSnow(in context: inout GraphicsContext, size: CGSize, t: Double) {
        for i in 0..<120 {
            let rx = fract(sin(Double(i) * 12.9898) * 43758.5453)
            let ry = fract(sin(Double(i) * 4.1414) * 24634.6345)
            let speed = 30 + rx * 50
            let sway = sin(t * (0.6 + rx) + Double(i)) * 18
            let x = (rx * size.width + sway).truncatingRemainder(dividingBy: size.width)
            let y = (ry * (size.height + 20) + t * speed).truncatingRemainder(dividingBy: size.height + 20) - 10
            let r = 1.2 + ry * 2.2
            context.fill(
                Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                with: .color(.white.opacity(0.5 + rx * 0.4))
            )
        }
    }

    private func drawLightning(in context: inout GraphicsContext, size: CGSize, t: Double) {
        let cycle = t.truncatingRemainder(dividingBy: 6.5)
        let flashing = cycle < 0.08 || (cycle > 0.16 && cycle < 0.24)
        guard flashing else { return }
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(0.28)))

        // A jagged bolt whose position changes every cycle.
        let boltSeed = floor(t / 6.5)
        var x = size.width * (0.2 + fract(sin(boltSeed * 91.7) * 4375.5) * 0.6)
        var y = 0.0
        var bolt = Path()
        bolt.move(to: CGPoint(x: x, y: y))
        var step = 0.0
        while y < size.height * 0.45 {
            step += 1
            y += 26
            x += (fract(sin(boltSeed * 13 + step * 7.1) * 999) - 0.5) * 50
            bolt.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(bolt, with: .color(.white.opacity(0.9)), lineWidth: 2.5)
    }

    private func fract(_ value: Double) -> Double { value - floor(value) }
}

#Preview {
    WeatherBackground(condition: .thunderstorm, isDay: false)
}
