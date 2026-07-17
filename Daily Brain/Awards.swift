import SwiftUI

// MARK: - Award model

struct BrainAward: Identifiable {
    let id: String
    let title: String
    let blurb: String
    let isUnlocked: (BrainStore) -> Bool

    var artAsset: String { "badge_\(id)" }
}

enum AwardCatalog {
    static let all: [BrainAward] = [
        BrainAward(id: "firstStep", title: "First Step",
                   blurb: "Finish your very first game.",
                   isUnlocked: { $0.lifetimeGames >= 1 }),
        BrainAward(id: "warmedUp", title: "Warmed Up",
                   blurb: "Finish 10 games.",
                   isUnlocked: { $0.lifetimeGames >= 10 }),
        BrainAward(id: "gamer50", title: "In The Groove",
                   blurb: "Finish 50 games.",
                   isUnlocked: { $0.lifetimeGames >= 50 }),
        BrainAward(id: "centurion", title: "Centurion",
                   blurb: "Finish 100 games.",
                   isUnlocked: { $0.lifetimeGames >= 100 }),
        BrainAward(id: "marathon", title: "Marathon Mind",
                   blurb: "Finish 250 games.",
                   isUnlocked: { $0.lifetimeGames >= 250 }),
        BrainAward(id: "streak3", title: "Kindled",
                   blurb: "Reach a 3-day streak.",
                   isUnlocked: { $0.bestStreak >= 3 }),
        BrainAward(id: "streak7", title: "One Full Week",
                   blurb: "Reach a 7-day streak.",
                   isUnlocked: { $0.bestStreak >= 7 }),
        BrainAward(id: "streak14", title: "Fortnight Flame",
                   blurb: "Reach a 14-day streak.",
                   isUnlocked: { $0.bestStreak >= 14 }),
        BrainAward(id: "streak30", title: "Iron Habit",
                   blurb: "Reach a 30-day streak.",
                   isUnlocked: { $0.bestStreak >= 30 }),
        BrainAward(id: "firstSet", title: "Day One Done",
                   blurb: "Complete your first daily set.",
                   isUnlocked: { $0.history.count >= 1 }),
        BrainAward(id: "tenSets", title: "Ten Mornings",
                   blurb: "Complete 10 daily sets.",
                   isUnlocked: { $0.history.count >= 10 }),
        BrainAward(id: "thirtySets", title: "Thirty Rituals",
                   blurb: "Complete 30 daily sets.",
                   isUnlocked: { $0.history.count >= 30 }),
        BrainAward(id: "sharp", title: "Razor Sharp",
                   blurb: "Earn your first 3-star round.",
                   isUnlocked: { $0.lifetimeThreeStars >= 1 }),
        BrainAward(id: "brilliant", title: "Brilliant Run",
                   blurb: "Earn 25 three-star rounds.",
                   isUnlocked: { $0.lifetimeThreeStars >= 25 }),
        BrainAward(id: "balanced", title: "Balanced Mind",
                   blurb: "Raise every skill rating to 50+.",
                   isUnlocked: { s in BrainDomain.allCases.allSatisfy { s.profile.rating($0) >= 50 } }),
        BrainAward(id: "mastermind", title: "Mastermind",
                   blurb: "Reach a brain score of 80.",
                   isUnlocked: { $0.profile.overall >= 80 }),
        BrainAward(id: "xp5k", title: "Powerhouse",
                   blurb: "Collect 5,000 XP.",
                   isUnlocked: { $0.totalXP >= 5000 }),
        BrainAward(id: "explorer", title: "Explorer",
                   blurb: "Play every one of the 19 games.",
                   isUnlocked: { s in GameKind.allCases.allSatisfy { s.best(for: $0).plays > 0 } })
    ]

    static func byID(_ id: String) -> BrainAward? { all.first { $0.id == id } }
}

// MARK: - Badge view

struct AwardBadgeView: View {
    let award: BrainAward
    let unlocked: Bool
    var size: CGFloat = 84

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                if let ui = BrainArtLoader.image(named: award.artAsset) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .saturation(unlocked ? 1 : 0)
                        .opacity(unlocked ? 1 : 0.35)
                } else {
                    Circle()
                        .fill(unlocked ? BrainTheme.goldSoft : BrainTheme.card)
                        .frame(width: size, height: size)
                        .overlay(BrainIcon(glyph: .trophy, size: size * 0.42,
                                           color: unlocked ? BrainTheme.gold : BrainTheme.subtle, weight: 2))
                }
                if !unlocked {
                    Circle()
                        .fill(Color.black.opacity(0.45))
                        .frame(width: size, height: size)
                    BrainIcon(glyph: .lock, size: size * 0.30, color: .white.opacity(0.85), weight: 2)
                }
            }
            .overlay(Circle().strokeBorder(unlocked ? BrainTheme.gold.opacity(0.7) : BrainTheme.line, lineWidth: 1.5))
            .luxeGlow(unlocked ? BrainTheme.gold : .clear, radius: 10, opacity: unlocked ? 0.35 : 0)

            Text(award.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(unlocked ? BrainTheme.ink : BrainTheme.subtle)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Awards grid screen

struct AwardsView: View {
    @EnvironmentObject var store: BrainStore
    @State private var selected: BrainAward?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                let unlockedCount = AwardCatalog.all.filter { store.unlockedAwards.contains($0.id) }.count
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Awards")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(BrainTheme.ink)
                        Text("\(unlockedCount) of \(AwardCatalog.all.count) unlocked")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(BrainTheme.subtle)
                    }
                    Spacer()
                    ZStack {
                        Circle().fill(BrainTheme.goldSoft).frame(width: 52, height: 52)
                        BrainIcon(glyph: .trophy, size: 26, color: BrainTheme.gold, weight: 2)
                    }
                    .luxeGlow(BrainTheme.gold, radius: 12, opacity: 0.3)
                }

                let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(AwardCatalog.all) { award in
                        Button {
                            BrainHaptics.tap()
                            selected = award
                        } label: {
                            AwardBadgeView(award: award, unlocked: store.unlockedAwards.contains(award.id))
                        }
                        .buttonStyle(PressableScaleStyle())
                    }
                }
                .brainCard(padding: 18)
            }
            .padding(16)
            .padding(.bottom, 10)
        }
        .background(LuxeScreenBackground(tint: BrainTheme.gold))
        .navigationBarHidden(true)
        .overlay(detailOverlay)
    }

    @ViewBuilder private var detailOverlay: some View {
        if let award = selected {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()
                    .onTapGesture { selected = nil }
                VStack(spacing: 14) {
                    AwardBadgeView(award: award, unlocked: store.unlockedAwards.contains(award.id), size: 130)
                    Text(award.title)
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                    Text(award.blurb)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(BrainTheme.subtle)
                        .multilineTextAlignment(.center)
                    Button { selected = nil } label: {
                        Text("Close")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(BrainTheme.ink)
                            .padding(.horizontal, 34).padding(.vertical, 11)
                            .background(Capsule().fill(BrainTheme.card)
                                .overlay(Capsule().strokeBorder(BrainTheme.cardStroke, lineWidth: 1)))
                    }
                    .buttonStyle(PressableScaleStyle())
                }
                .padding(26)
                .brainCard(padding: 22)
                .padding(.horizontal, 44)
            }
            .transition(.opacity)
        }
    }
}
