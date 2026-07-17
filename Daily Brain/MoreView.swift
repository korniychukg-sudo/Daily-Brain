import SwiftUI

private struct BrainTip: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let glyph: BrainGlyph
    let color: Color
}

private let brainTips: [BrainTip] = [
    BrainTip(title: "Short and daily beats long and rare",
             body: "A focused five minutes every day builds more durable gains than a single long session once a week. Consistency is the real training effect.",
             glyph: .flame, color: BrainDomain.reflex.color),
    BrainTip(title: "Warm up the weak corner",
             body: "Check your radar. The lowest domain is where a few extra rounds move your brain score the most. Balance beats a single spiky skill.",
             glyph: .radar, color: BrainTheme.primary),
    BrainTip(title: "Speed follows accuracy",
             body: "Chase clean answers first. Once the pattern is automatic, quickness arrives on its own. Rushing before accuracy just trains mistakes.",
             glyph: .spark, color: BrainDomain.numbers.color),
    BrainTip(title: "Rest is part of the rep",
             body: "Sleep and short breaks are when memory consolidates. If a score dips when you are tired, that is data, not failure.",
             glyph: .clock, color: BrainDomain.focus.color),
    BrainTip(title: "Name the strategy",
             body: "Chunk digits into pairs, group tiles by color, read the ink before the word. A stated tactic is far stronger than a vague effort.",
             glyph: .brain, color: BrainDomain.memory.color)
]

struct MoreView: View {
    @EnvironmentObject var store: BrainStore
    @State private var showPrivacy = false
    @State private var showReset = false
    private let privacyURL = "https://example.com"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                aboutCard
                scoringCard
                tipsSection
                settingsCard
            }
            .padding(16)
            .padding(.bottom, 10)
        }
        .background(LuxeScreenBackground(tint: BrainDomain.focus.color))
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            BrainWebPanel(urlString: privacyURL)
                .edgesIgnoringSafeArea(.bottom)
        }
        .alert("Reset all progress?", isPresented: $showReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { store.resetAll() }
        } message: {
            Text("This clears your streak, XP, skill profile, history and records. This cannot be undone.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("More")
                .font(.system(size: 28, weight: .heavy, design: .rounded)).foregroundColor(BrainTheme.ink)
            Text("About, training tips and settings")
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
        }
    }

    private var aboutCard: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(BrainTheme.heroGradient).frame(width: 56, height: 56)
                BrainIcon(glyph: .brain, size: 30, color: .white, weight: 2.4)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Brain")
                    .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                Text("A calm daily set of quick mini-games that trains memory, numbers, focus and reflex — and charts how each skill grows. Fully offline.")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
            }
        }
        .brainCard()
    }

    private var scoringCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How scoring works")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            scoreRow(icon: .star, title: "Round score", text: "Every game gives a 0–100 score based on how far or how fast you got.")
            scoreRow(icon: .radar, title: "Skill rating", text: "Each score blends into that domain's rolling rating, so a bad round never erases weeks of work.")
            scoreRow(icon: .spark, title: "XP & levels", text: "Scores earn XP; finishing the daily set adds a streak bonus that grows with your streak.")
            scoreRow(icon: .flame, title: "Streak", text: "Complete every game in the daily set to extend your streak. Miss a day and it resets to one.")
        }
        .brainCard()
    }

    private func scoreRow(icon: BrainGlyph, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(BrainTheme.primarySoft).frame(width: 36, height: 36)
                BrainIcon(glyph: icon, size: 18, color: BrainTheme.primary, weight: 2)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                Text(text).font(.system(size: 13, weight: .regular, design: .rounded)).foregroundColor(BrainTheme.subtle)
            }
        }
    }

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Training Tips")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            ForEach(brainTips) { tip in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle().fill(tip.color.opacity(0.16)).frame(width: 40, height: 40)
                        BrainIcon(glyph: tip.glyph, size: 20, color: tip.color, weight: 2)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(tip.title).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                        Text(tip.body).font(.system(size: 13, weight: .regular, design: .rounded)).foregroundColor(BrainTheme.subtle).lineSpacing(2)
                    }
                }
                .brainCard(padding: 14)
            }
        }
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            Button { showPrivacy = true } label: {
                settingsRow(icon: .lock, title: "Privacy Policy", tint: BrainTheme.primary)
            }
            Divider().padding(.leading, 52)
            Button { showReset = true } label: {
                settingsRow(icon: .refresh, title: "Reset progress", tint: BrainDomain.reflex.color)
            }
        }
        .brainCard(padding: 4)
    }

    private func settingsRow(icon: BrainGlyph, title: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(0.15)).frame(width: 36, height: 36)
                BrainIcon(glyph: icon, size: 18, color: tint, weight: 2)
            }
            Text(title).font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.ink)
            Spacer()
            BrainIcon(glyph: .chevronRight, size: 18, color: BrainTheme.subtle.opacity(0.6), weight: 2)
        }
        .padding(.horizontal, 12).padding(.vertical, 14)
    }
}
