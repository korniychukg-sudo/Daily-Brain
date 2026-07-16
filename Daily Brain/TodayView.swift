import SwiftUI

struct ProgressRing: View {
    var progress: Double
    var size: CGFloat = 120
    var lineWidth: CGFloat = 12
    var color: Color = BrainTheme.primary
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.16), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct TodayView: View {
    @EnvironmentObject var store: BrainStore
    @State private var activeGame: GameKind?

    private var nextGame: GameKind? {
        store.todayPlan.first { !store.completedToday.contains($0.rawValue) }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                if store.dailyComplete {
                    completeCard
                }
                planSection
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .background(BrainTheme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(item: $activeGame) { kind in
            GameHost(kind: kind, partOfDaily: true) { _ in activeGame = nil }
                .environmentObject(store)
        }
    }

    // MARK: Header

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Brain")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Your five-minute workout")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                HStack(spacing: 5) {
                    BrainIcon(glyph: .flame, size: 20, color: BrainTheme.gold, weight: 2)
                    Text("\(store.streak)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Capsule().fill(Color.white.opacity(0.16)))
            }

            HStack(spacing: 18) {
                ZStack {
                    ProgressRing(progress: store.dailyProgress, size: 96, lineWidth: 10, color: .white)
                    VStack(spacing: 0) {
                        Text("\(store.completedToday.count)/\(store.todayPlan.count)")
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("done").font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    miniStat(icon: .star, value: "Lvl \(store.level)", label: "Level")
                    miniStat(icon: .spark, value: "\(store.totalXP)", label: "Total XP")
                    miniStat(icon: .radar, value: "\(store.profile.overall)", label: "Brain score")
                }
                Spacer()
            }

            if let g = nextGame {
                Button { activeGame = g } label: {
                    HStack(spacing: 8) {
                        BrainIcon(glyph: .play, size: 18, color: BrainTheme.primary, weight: 2)
                        Text(store.completedToday.isEmpty ? "Start today's set" : "Continue")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(BrainTheme.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Color.white))
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 26, style: .continuous).fill(BrainTheme.heroGradient))
    }

    private func miniStat(icon: BrainGlyph, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            BrainIcon(glyph: icon, size: 16, color: .white.opacity(0.9), weight: 2)
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(.white)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.75))
        }
    }

    private var completeCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(BrainTheme.goldSoft).frame(width: 52, height: 52)
                BrainIcon(glyph: .trophy, size: 28, color: BrainTheme.gold, weight: 2)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily set complete")
                    .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                Text("Streak at \(store.streak) day\(store.streak == 1 ? "" : "s"). Explore the full library any time.")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
            }
            Spacer()
        }
        .brainCard()
    }

    // MARK: Plan list

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Set")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            ForEach(Array(store.todayPlan.enumerated()), id: \.element) { idx, kind in
                planRow(index: idx, kind: kind)
            }
        }
    }

    private func planRow(index: Int, kind: GameKind) -> some View {
        let done = store.completedToday.contains(kind.rawValue)
        return Button { activeGame = kind } label: {
            HStack(spacing: 14) {
                GameArtView(kind: kind, cornerRadius: 14)
                    .frame(width: 62, height: 62)
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                    HStack(spacing: 6) {
                        Circle().fill(kind.domain.color).frame(width: 8, height: 8)
                        Text(kind.domain.title)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainTheme.subtle)
                    }
                }
                Spacer()
                if done {
                    ZStack {
                        Circle().fill(kind.domain.color).frame(width: 30, height: 30)
                        BrainIcon(glyph: .check, size: 16, color: .white, weight: 2.4)
                    }
                } else {
                    ZStack {
                        Circle().fill(kind.domain.colorSoft).frame(width: 30, height: 30)
                        BrainIcon(glyph: .play, size: 14, color: kind.domain.color, weight: 2)
                    }
                }
            }
            .brainCard(padding: 12)
        }
        .buttonStyle(.plain)
    }
}
