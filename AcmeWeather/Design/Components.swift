import SwiftUI

struct CardHeader: View {
    let title: String
    let systemImage: String
    var trailing: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title.uppercased())
            Spacer()
            if let trailing {
                Text(trailing).textCase(nil)
            }
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.white.opacity(0.65))
    }
}

/// Big rounded tile with an icon, used for quick actions and hub grids.
struct ActionTile: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color

    init(_ title: String, subtitle: String? = nil, systemImage: String, tint: Color) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 44, height: 44)
                .background(tint.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Spacer(minLength: 0)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .glassCard(padding: 14)
    }
}

/// Small capsule label.
struct Pill: View {
    let text: String
    var color: Color = .white.opacity(0.15)
    var foreground: Color = .white

    var body: some View {
        Text(text)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color, in: Capsule())
            .foregroundStyle(foreground)
    }
}

/// Circular progress ring with a label in the middle.
struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 10
    var gradient: [Color] = [Theme.peachLight, Theme.peach, Theme.danger]

    var body: some View {
        ZStack {
            Circle().stroke(.white.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(progress, 1)))
                .stroke(
                    AngularGradient(colors: gradient, center: .center),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.8), value: progress)
        }
    }
}

struct DemoBadge: View {
    var body: some View {
        Pill(text: "DEMO", color: Theme.peach.opacity(0.25), foreground: Theme.peachLight)
    }
}

extension Date {
    var shortTime: String { formatted(date: .omitted, time: .shortened) }
    var hourLabel: String { formatted(.dateTime.hour()) }
    var weekdayShort: String { formatted(.dateTime.weekday(.abbreviated)) }
}
