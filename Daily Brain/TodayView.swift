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
                .luxeGlow(color, radius: 10, opacity: 0.55)
                .animation(.easeOut(duration: 0.6), value: progress)
        }
        .frame(width: size, height: size)
    }
}

struct TodayView: View {
    @EnvironmentObject var store: BrainStore
    @State private var activeGame: GameKind?
    @State private var showSummary = false
    @State private var wasCompleteAtLaunch = false

    private var nextGame: GameKind? {
        store.todayPlan.first { !store.completedToday.contains($0.rawValue) }
    }

    var body: some View {
        ZStack {
            AuroraBackground(tint: BrainTheme.primary,
                             secondary: BrainDomain.reflex.color)
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
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $activeGame) { kind in
            GameHost(kind: kind, partOfDaily: true) { _ in
                activeGame = nil
                if store.dailyComplete && !wasCompleteAtLaunch {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        showSummary = true
                    }
                }
            }
            .environmentObject(store)
        }
        .fullScreenCover(isPresented: $showSummary) {
            DailySummaryView { showSummary = false }
                .environmentObject(store)
        }
    }

    // MARK: Header

    private var headerCard: some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily Brain")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                    Text("Your five-minute workout")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(BrainTheme.subtle)
                }
                Spacer()
                HStack(spacing: 5) {
                    BrainIcon(glyph: .flame, size: 20, color: BrainTheme.gold, weight: 2)
                    Text("\(store.streak)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                }
                .padding(.horizontal, 13).padding(.vertical, 8)
                .background(Capsule().fill(BrainTheme.goldSoft)
                    .overlay(Capsule().strokeBorder(BrainTheme.gold.opacity(0.4), lineWidth: 1)))
                .luxeGlow(BrainTheme.gold, radius: 12, opacity: 0.35)
            }

            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(progress: store.dailyProgress, size: 104, lineWidth: 11,
                                 color: BrainTheme.gold)
                    VStack(spacing: 0) {
                        Text("\(store.completedToday.count)/\(store.todayPlan.count)")
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(BrainTheme.ink)
                        Text("done").font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainTheme.subtle)
                    }
                }
                VStack(alignment: .leading, spacing: 11) {
                    miniStat(icon: .star, value: "Lvl \(store.level)", label: "Level")
                    miniStat(icon: .spark, value: "\(store.totalXP)", label: "Total XP")
                    miniStat(icon: .radar, value: "\(store.profile.overall)", label: "Brain score")
                }
                Spacer()
            }

            if let g = nextGame {
                Button {
                    launch(g)
                } label: {
                    HStack(spacing: 8) {
                        BrainIcon(glyph: .play, size: 18, color: .white, weight: 2)
                        Text(store.completedToday.isEmpty ? "Start today's set" : "Continue")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(BrainTheme.heroGradient))
                    .luxeGlow(BrainTheme.primary, radius: 16, opacity: 0.5)
                }
                .buttonStyle(PressableScaleStyle())
            }
        }
        .brainCard(padding: 18, radius: 26)
    }

    private func miniStat(icon: BrainGlyph, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            BrainIcon(glyph: icon, size: 16, color: BrainTheme.gold, weight: 2)
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            Text(label).font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
        }
    }

    private var completeCard: some View {
        Button {
            showSummary = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(BrainTheme.goldSoft).frame(width: 52, height: 52)
                    BrainIcon(glyph: .trophy, size: 28, color: BrainTheme.gold, weight: 2)
                }
                .luxeGlow(BrainTheme.gold, radius: 12, opacity: 0.4)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Daily set complete")
                        .font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                    Text("Streak at \(store.streak) day\(store.streak == 1 ? "" : "s"). Tap for today's summary.")
                        .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
                }
                Spacer()
                BrainIcon(glyph: .chevronRight, size: 18, color: BrainTheme.subtle.opacity(0.7), weight: 2)
            }
            .brainCard()
        }
        .buttonStyle(PressableScaleStyle())
    }

    // MARK: Plan list

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            LuxeSectionTitle(text: "Today's Set")
            ForEach(Array(store.todayPlan.enumerated()), id: \.element) { idx, kind in
                planRow(index: idx, kind: kind)
            }
        }
    }

    private func planRow(index: Int, kind: GameKind) -> some View {
        let done = store.completedToday.contains(kind.rawValue)
        return Button {
            launch(kind)
        } label: {
            HStack(spacing: 14) {
                GameArtView(kind: kind, cornerRadius: 14)
                    .frame(width: 64, height: 64)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                    HStack(spacing: 6) {
                        Circle().fill(kind.domain.color).frame(width: 8, height: 8)
                            .luxeGlow(kind.domain.color, radius: 6, opacity: 0.8)
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
                    .luxeGlow(kind.domain.color, radius: 10, opacity: 0.6)
                } else {
                    ZStack {
                        Circle().fill(kind.domain.colorSoft).frame(width: 30, height: 30)
                            .overlay(Circle().strokeBorder(kind.domain.color.opacity(0.4), lineWidth: 1))
                        BrainIcon(glyph: .play, size: 14, color: kind.domain.color, weight: 2)
                    }
                }
            }
            .brainCard(padding: 12)
        }
        .buttonStyle(PressableScaleStyle())
    }

    private func launch(_ kind: GameKind) {
        BrainHaptics.tap()
        wasCompleteAtLaunch = store.dailyComplete
        activeGame = kind
    }
}
