import SwiftUI

// MARK: - Aurora background (slow breathing gradient blobs)

struct AuroraBackground: View {
    var tint: Color = BrainTheme.primary
    var secondary: Color = BrainDomain.reflex.color
    var animated: Bool = true
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                BrainTheme.midnightGradient
                Circle()
                    .fill(tint.opacity(0.32))
                    .frame(width: w * 1.1, height: w * 1.1)
                    .blur(radius: 90)
                    .offset(x: drift ? -w * 0.25 : -w * 0.05,
                            y: drift ? -h * 0.32 : -h * 0.22)
                Circle()
                    .fill(secondary.opacity(0.20))
                    .frame(width: w * 0.9, height: w * 0.9)
                    .blur(radius: 90)
                    .offset(x: drift ? w * 0.38 : w * 0.20,
                            y: drift ? h * 0.05 : h * 0.18)
                Circle()
                    .fill(BrainTheme.gold.opacity(0.10))
                    .frame(width: w * 0.7, height: w * 0.7)
                    .blur(radius: 80)
                    .offset(x: drift ? -w * 0.15 : w * 0.05, y: h * 0.42)
                GrainOverlay()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            guard animated else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

// MARK: - Grain texture overlay

struct GrainOverlay: View {
    var opacity: Double = 0.35
    var body: some View {
        Group {
            if let ui = BrainArtLoader.image(named: "texture_grain") {
                Image(uiImage: ui)
                    .resizable(resizingMode: .tile)
                    .blendMode(.softLight)
                    .opacity(opacity)
                    .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Standard screen backdrop (static aurora + grain, cheap)

struct LuxeScreenBackground: View {
    var tint: Color = BrainTheme.primary
    var body: some View {
        ZStack {
            BrainTheme.midnightGradient
            GeometryReader { geo in
                Circle()
                    .fill(tint.opacity(0.22))
                    .frame(width: geo.size.width * 1.2)
                    .blur(radius: 100)
                    .offset(x: -geo.size.width * 0.2, y: -geo.size.height * 0.30)
            }
            GrainOverlay(opacity: 0.30)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Count-up number

struct CountUpText: View {
    let target: Int
    var duration: Double = 0.9
    var font: Font = .system(size: 54, weight: .heavy, design: .rounded)
    var color: Color = BrainTheme.ink
    @State private var shown = 0
    @State private var timer: Timer?

    var body: some View {
        Text("\(shown)")
            .font(font)
            .foregroundColor(color)
            .onAppear { start() }
            .onDisappear { timer?.invalidate() }
    }

    private func start() {
        guard target > 0 else { shown = target; return }
        shown = 0
        let steps = 30
        var step = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { t in
            step += 1
            // ease-out curve
            let f = 1 - pow(1 - Double(step) / Double(steps), 2.2)
            shown = min(target, Int((Double(target) * f).rounded()))
            if step >= steps { shown = target; t.invalidate() }
        }
    }
}

// MARK: - Confetti burst

struct BrainConfetti: View {
    var trigger: Bool
    private let pieces = 44

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if trigger {
                    ForEach(0..<pieces, id: \.self) { i in
                        ConfettiPiece(index: i, size: geo.size)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

private struct ConfettiPiece: View {
    let index: Int
    let size: CGSize
    @State private var fly = false

    private var palette: [Color] {
        [BrainTheme.gold, BrainTheme.primary,
         BrainDomain.numbers.color, BrainDomain.reflex.color,
         BrainDomain.focus.color, Color.white.opacity(0.9)]
    }

    var body: some View {
        let seedX = CGFloat((index * 73) % 100) / 100
        let delay = Double((index * 37) % 100) / 260
        let spin = Double((index * 51) % 360)
        let wide = CGFloat((index * 29) % 100) / 100 * 0.5 - 0.25
        let isRect = index % 3 != 0
        let color = palette[index % palette.count]

        Group {
            if isRect {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 8, height: 13)
            } else {
                Circle().fill(color).frame(width: 9, height: 9)
            }
        }
        .rotationEffect(.degrees(fly ? spin + 540 : spin))
        .position(x: size.width * (0.5 + (fly ? wide * 2.4 : wide * 0.3)) + seedX * 30 - 15,
                  y: fly ? size.height + 40 : -30)
        .opacity(fly ? 0.9 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: Double.random(in: 1.5...2.3)).delay(delay)) {
                fly = true
            }
        }
    }
}

// MARK: - Section title

struct LuxeSectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .foregroundColor(BrainTheme.ink)
    }
}
