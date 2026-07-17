import SwiftUI

struct BrainLaunchScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            AuroraBackground(tint: BrainTheme.primary,
                             secondary: BrainDomain.reflex.color,
                             animated: false)
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(BrainTheme.primary.opacity(0.22))
                        .frame(width: 132, height: 132)
                        .scaleEffect(pulse ? 1.10 : 0.94)
                        .luxeGlow(BrainTheme.primary, radius: 30, opacity: 0.5)
                    Circle().fill(BrainTheme.card)
                        .overlay(Circle().strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                        .frame(width: 100, height: 100)
                    BrainIcon(glyph: .brain, size: 52, color: BrainTheme.primary, weight: 2.6)
                }
                Text("Daily Brain")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
                Text("Warming up...")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(BrainTheme.subtle)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
