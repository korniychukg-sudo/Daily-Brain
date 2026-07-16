import SwiftUI

enum BrainTheme {
    // Base surfaces
    static let background = Color(red: 0.949, green: 0.957, blue: 0.984)
    static let card = Color.white
    static let ink = Color(red: 0.121, green: 0.137, blue: 0.243)
    static let subtle = Color(red: 0.451, green: 0.478, blue: 0.573)
    static let line = Color(red: 0.886, green: 0.898, blue: 0.941)

    // Brand accents
    static let primary = Color(red: 0.396, green: 0.310, blue: 0.902)     // indigo-violet
    static let primaryDark = Color(red: 0.278, green: 0.196, blue: 0.706)
    static let primarySoft = Color(red: 0.898, green: 0.886, blue: 0.988)
    static let gold = Color(red: 0.976, green: 0.729, blue: 0.243)
    static let goldSoft = Color(red: 0.996, green: 0.933, blue: 0.808)

    static let heroGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primaryDark]),
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func level(forXP xp: Int) -> Int {
        // Smooth curve: each level costs a bit more.
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

struct BrainCardStyle: ViewModifier {
    var padding: CGFloat = 16
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(BrainTheme.card)
                    .shadow(color: BrainTheme.ink.opacity(0.06), radius: 12, x: 0, y: 5)
            )
    }
}

extension View {
    func brainCard(padding: CGFloat = 16, radius: CGFloat = 20) -> some View {
        modifier(BrainCardStyle(padding: padding, radius: radius))
    }
}
