import SwiftUI

struct DailySummaryView: View {
    @EnvironmentObject var store: BrainStore
    var onDone: () -> Void
    @State private var confetti = false

    private var record: SessionRecord? {
        store.history.first { $0.dateStamp == store.todayStamp() }
    }

    var body: some View {
        ZStack {
            AuroraBackground(tint: BrainTheme.gold,
                             secondary: BrainTheme.primary)
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle().fill(BrainTheme.goldSoft).frame(width: 118, height: 118)
                        BrainIcon(glyph: .trophy, size: 58, color: BrainTheme.gold, weight: 2.4)
                    }
                    .luxeGlow(BrainTheme.gold, radius: 26, opacity: 0.5)
                    .padding(.top, 34)

                    VStack(spacing: 6) {
                        Text("Daily Set Complete")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                            .foregroundColor(BrainTheme.ink)
                        HStack(spacing: 6) {
                            BrainIcon(glyph: .flame, size: 18, color: BrainTheme.gold, weight: 2)
                            Text("\(store.streak) day streak")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(BrainTheme.gold)
                        }
                    }

                    if let rec = record {
                        VStack(spacing: 4) {
                            CountUpText(target: rec.averageScore,
                                        font: .system(size: 64, weight: .heavy, design: .rounded),
                                        color: BrainTheme.ink)
                            Text("average score")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(BrainTheme.subtle)
                        }
                        .padding(.vertical, 6)

                        VStack(spacing: 14) {
                            ForEach(BrainDomain.allCases) { d in
                                if let s = rec.domainScores[d.rawValue] {
                                    domainRow(d, score: s)
                                }
                            }
                        }
                        .brainCard(padding: 18)
                        .padding(.horizontal, 22)

                        HStack(spacing: 6) {
                            BrainIcon(glyph: .spark, size: 18, color: BrainTheme.gold, weight: 2)
                            Text("+\(rec.xpEarned) XP earned today")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(BrainTheme.gold)
                        }
                    }

                    Button {
                        BrainHaptics.tap()
                        onDone()
                    } label: {
                        Text("Continue")
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
                    .padding(.vertical, 18)
                }
            }
            BrainConfetti(trigger: confetti)
        }
        .onAppear {
            BrainHaptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { confetti = true }
        }
    }

    private func domainRow(_ d: BrainDomain, score: Int) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(d.colorSoft).frame(width: 38, height: 38)
                BrainIcon(glyph: BrainGlyph.forDomain(d), size: 19, color: d.color, weight: 2)
            }
            Text(d.title)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(d.colorSoft)
                    Capsule().fill(d.color)
                        .frame(width: geo.size.width * CGFloat(score) / 100)
                        .luxeGlow(d.color, radius: 6, opacity: 0.5)
                }
            }
            .frame(width: 110, height: 8)
            Text("\(score)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(d.color)
                .frame(width: 32, alignment: .trailing)
        }
    }
}
