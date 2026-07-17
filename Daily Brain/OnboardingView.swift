import SwiftUI

private struct OnboardSlide: Identifiable {
    let id: Int
    let art: String
    let title: String
    let body: String
}

private let slides: [OnboardSlide] = [
    OnboardSlide(id: 0, art: "onboard_1",
                 title: "Five focused minutes",
                 body: "Every day you get a fresh, balanced set of five quick mini-games. One small ritual, real momentum."),
    OnboardSlide(id: 1, art: "onboard_2",
                 title: "Four skills, one profile",
                 body: "Memory, numbers, focus and reflex each grow their own rating. Watch your cognitive radar fill out over time."),
    OnboardSlide(id: 2, art: "onboard_3",
                 title: "Streaks, levels, awards",
                 body: "Keep the flame alive, level up with XP and unlock 18 badges along the way. Everything stays on your device.")
]

struct OnboardingView: View {
    var onDone: () -> Void
    @State private var page = 0

    var body: some View {
        ZStack {
            AuroraBackground(tint: BrainTheme.primary,
                             secondary: BrainDomain.reflex.color)
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        BrainHaptics.tap()
                        onDone()
                    } label: {
                        Text("Skip")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainTheme.subtle)
                            .padding(.horizontal, 18).padding(.vertical, 8)
                            .background(Capsule().fill(BrainTheme.card)
                                .overlay(Capsule().strokeBorder(BrainTheme.cardStroke, lineWidth: 1)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                TabView(selection: $page) {
                    ForEach(slides) { slide in
                        slideView(slide).tag(slide.id)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                // custom page dots
                HStack(spacing: 8) {
                    ForEach(slides) { slide in
                        Capsule()
                            .fill(page == slide.id ? BrainTheme.gold : BrainTheme.line)
                            .frame(width: page == slide.id ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: page)
                    }
                }
                .padding(.bottom, 22)

                Button {
                    BrainHaptics.tap()
                    if page < slides.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        onDone()
                    }
                } label: {
                    Text(page < slides.count - 1 ? "Next" : "Start training")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(BrainTheme.heroGradient))
                        .luxeGlow(BrainTheme.primary, radius: 16, opacity: 0.45)
                }
                .buttonStyle(PressableScaleStyle())
                .padding(.horizontal, 26)
                .padding(.bottom, 28)
            }
        }
    }

    private func slideView(_ slide: OnboardSlide) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 4)
            ZStack {
                if let ui = BrainArtLoader.image(named: slide.art) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: 320, maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                        .luxeGlow(BrainTheme.primary, radius: 26, opacity: 0.3)
                } else {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(BrainTheme.card)
                        .frame(maxWidth: 320, maxHeight: 300)
                        .overlay(BrainIcon(glyph: .brain, size: 80, color: BrainTheme.primary, weight: 2.6))
                }
            }
            .padding(.horizontal, 30)

            VStack(spacing: 10) {
                Text(slide.title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
                    .multilineTextAlignment(.center)
                Text(slide.body)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(BrainTheme.subtle)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 34)
            }
            Spacer(minLength: 4)
        }
    }
}
