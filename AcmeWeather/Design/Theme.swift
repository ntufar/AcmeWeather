import SwiftUI

enum Theme {
    static let peach = Color(red: 1.00, green: 0.55, blue: 0.38)
    static let peachLight = Color(red: 1.00, green: 0.78, blue: 0.62)
    static let navy = Color(red: 0.05, green: 0.11, blue: 0.24)
    static let midnight = Color(red: 0.02, green: 0.04, blue: 0.11)
    static let pine = Color(red: 0.16, green: 0.52, blue: 0.38)
    static let danger = Color(red: 0.94, green: 0.23, blue: 0.27)
    static let sky = Color(red: 0.35, green: 0.68, blue: 1.00)

    static let appBackground = LinearGradient(
        colors: [navy, midnight],
        startPoint: .top,
        endPoint: .bottom
    )

    static let peachGradient = LinearGradient(
        colors: [peachLight, peach],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    /// Frosted card used across the app.
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            )
    }

    /// Dark navy backdrop for list-style screens.
    func appBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(Theme.appBackground.ignoresSafeArea())
    }
}
