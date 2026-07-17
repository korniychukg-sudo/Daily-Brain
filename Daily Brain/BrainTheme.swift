import SwiftUI

enum BrainTheme {
    // Base surfaces — deep midnight indigo, fixed dark-luxe appearance.
    static let background = Color(red: 0.051, green: 0.055, blue: 0.114)
    static let backgroundDeep = Color(red: 0.031, green: 0.033, blue: 0.075)
    static let card = Color(red: 1.0, green: 1.0, blue: 1.0).opacity(0.055)
    static let cardStroke = Color.white.opacity(0.10)
    static let ink = Color(red: 0.933, green: 0.937, blue: 0.976)
    static let subtle = Color(red: 0.596, green: 0.616, blue: 0.741)
    static let line = Color.white.opacity(0.12)

    // Brand accents — brightened for the dark base.
    static let primary = Color(red: 0.545, green: 0.463, blue: 1.0)      // luminous violet
    static let primaryDark = Color(red: 0.337, green: 0.255, blue: 0.796)
    static let primarySoft = Color(red: 0.545, green: 0.463, blue: 1.0).opacity(0.18)
    static let gold = Color(red: 0.984, green: 0.760, blue: 0.310)
    static let goldSoft = Color(red: 0.984, green: 0.760, blue: 0.310).opacity(0.16)

    static let heroGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primaryDark]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    /// Full-screen base gradient behind every screen.
    static let midnightGradient = LinearGradient(
        gradient: Gradient(colors: [background, backgroundDeep]),
        startPoint: .top, endPoint: .bottom
    )

    static func level(forXP xp: Int) -> Int {
        var lvl = 1
        var need = 120
        var remaining = xp
        while remaining >= need {
            remaining -= need
            lvl += 1
            need = Int(Double(need) * 1.18)
        }
        return lvl
    }

    static func levelProgress(forXP xp: Int) -> (level: Int, into: Int, span: Int) {
        var lvl = 1
        var need = 120
        var remaining = xp
        while remaining >= need {
            remaining -= need
            lvl += 1
            need = Int(Double(need) * 1.18)
        }
        return (lvl, remaining, need)
    }
}

/// Glass card: translucent fill, hairline stroke, deep shadow.
struct BrainCardStyle: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 22
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(BrainTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)],
                                               startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 14, x: 0, y: 7)
            )
    }
}

extension View {
    func brainCard(padding: CGFloat = 16, radius: CGFloat = 22) -> some View {
        modifier(BrainCardStyle(padding: padding, radius: radius))
    }

    /// Neon glow behind an accent element.
    func luxeGlow(_ color: Color, radius: CGFloat = 14, opacity: Double = 0.55) -> some View {
        shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
    }
}

/// Springy press feedback for cards and buttons.
struct PressableScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
