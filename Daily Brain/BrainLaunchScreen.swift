import SwiftUI

struct BrainLaunchScreen: View {
    @State private var pulse = false

    var body: some View {
        ZStack {
            BrainTheme.heroGradient.ignoresSafeArea()
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(Color.white.opacity(0.14))
                        .frame(width: 128, height: 128)
                        .scaleEffect(pulse ? 1.08 : 0.94)
                    Circle().fill(Color.white.opacity(0.92))
                        .frame(width: 96, height: 96)
                    BrainIcon(glyph: .brain, size: 52, color: BrainTheme.primary, weight: 2.6)
                }
                Text("Daily Brain")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("Warming up...")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
