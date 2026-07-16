import SwiftUI

typealias GameReport = (_ score: Int, _ stat: String) -> Void

private enum HostPhase { case intro, ready, playing, result }

struct GameHost: View {
    let kind: GameKind
    var partOfDaily: Bool = false
    var onExit: (GameOutcome?) -> Void

    @EnvironmentObject var store: BrainStore
    @State private var phase: HostPhase = .intro
    @State private var readyCount = 3
    @State private var outcome: GameOutcome?
    @State private var readyTimer: Timer?

    var body: some View {
        ZStack {
            BrainTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                content
            }
        }
        .onDisappear { readyTimer?.invalidate() }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { finishAbandon() } label: {
                ZStack {
                    Circle().fill(BrainTheme.card).frame(width: 38, height: 38)
                        .shadow(color: BrainTheme.ink.opacity(0.06), radius: 5, y: 2)
                    BrainIcon(glyph: .close, size: 18, color: BrainTheme.ink, weight: 2)
                }
            }
            Spacer()
            Text(kind.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            Spacer()
            Circle().fill(kind.domain.color).frame(width: 12, height: 12)
                .padding(.trailing, 13)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Content phases

    @ViewBuilder private var content: some View {
        switch phase {
        case .intro:
            introView
        case .ready:
            readyView
        case .playing:
            gameBody
                .transition(.opacity)
        case .result:
            if let o = outcome { ResultView(kind: kind, outcome: o) { onExit(o) } }
        }
    }

    private var introView: some View {
        ScrollView {
            VStack(spacing: 18) {
                GameArtView(kind: kind, cornerRadius: 24)
                    .frame(height: 180)
                    .padding(.top, 6)

                HStack(spacing: 8) {
                    Circle().fill(kind.domain.colorSoft).frame(width: 26, height: 26)
                        .overlay(BrainIcon(glyph: BrainGlyph.forDomain(kind.domain), size: 15, color: kind.domain.color, weight: 2))
                    Text(kind.domain.title.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(kind.domain.color)
                        .tracking(1.2)
                }

                Text(kind.tagline)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)

                Text(kind.howTo)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(BrainTheme.subtle)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 18)

                let best = store.best(for: kind)
                if best.plays > 0 {
                    HStack(spacing: 18) {
                        statChip(title: "Best", value: "\(best.bestScore)")
                        statChip(title: "Record", value: best.bestStat.isEmpty ? "—" : best.bestStat)
                        statChip(title: "Plays", value: "\(best.plays)")
                    }
                    .padding(.top, 2)
                }

                Button { startReady() } label: {
                    HStack(spacing: 8) {
                        BrainIcon(glyph: .play, size: 18, color: .white, weight: 2)
                        Text("Start").font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(BrainTheme.heroGradient)
                    )
                }
                .padding(.top, 6)
                .padding(.horizontal, 8)
            }
            .padding(20)
        }
    }

    private func statChip(title: String, value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            Text(title).font(.system(size: 11, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
        }
        .frame(minWidth: 66)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(BrainTheme.card))
    }

    private var readyView: some View {
        ZStack {
            kind.domain.color.opacity(0.10).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(readyCount > 0 ? "\(readyCount)" : "Go")
                    .font(.system(size: 76, weight: .heavy, design: .rounded))
                    .foregroundColor(kind.domain.color)
                    .id(readyCount)
                    .transition(.scale.combined(with: .opacity))
                Text("Get ready")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(BrainTheme.subtle)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Game factory

    @ViewBuilder private var gameBody: some View {
        let report: GameReport = { score, stat in finishGame(score: score, stat: stat) }
        switch kind {
        case .gridRecall:   GridRecallGame(onFinish: report)
        case .symbolPairs:  SymbolPairsGame(onFinish: report)
        case .sequenceEcho: SequenceEchoGame(onFinish: report)
        case .numberSpan:   NumberSpanGame(onFinish: report)
        case .whereWasIt:   WhereWasItGame(onFinish: report)
        case .quickSums:    QuickSumsGame(onFinish: report)
        case .equationPick: EquationPickGame(onFinish: report)
        case .numberSort:   NumberSortGame(onFinish: report)
        case .changeMaker:  ChangeMakerGame(onFinish: report)
        case .balanceScale: BalanceScaleGame(onFinish: report)
        case .colorClash:   ColorClashGame(onFinish: report)
        case .findTarget:   FindTargetGame(onFinish: report)
        case .symbolHunt:   SymbolHuntGame(onFinish: report)
        case .oddColorOut:  OddColorOutGame(onFinish: report)
        case .gapCount:     GapCountGame(onFinish: report)
        case .tapGo:        TapGoGame(onFinish: report)
        case .catchGreen:   CatchGreenGame(onFinish: report)
        case .popOrder:     PopOrderGame(onFinish: report)
        case .arrowRush:    ArrowRushGame(onFinish: report)
        }
    }

    // MARK: Flow

    private func startReady() {
        readyCount = 3
        withAnimation { phase = .ready }
        readyTimer?.invalidate()
        readyTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { t in
            if readyCount <= 1 {
                t.invalidate()
                withAnimation { phase = .playing }
            } else {
                withAnimation { readyCount -= 1 }
            }
        }
    }

    private func finishGame(score: Int, stat: String) {
        let clamped = min(100, max(0, score))
        let xp = 12 + clamped * 55 / 100
        let o = GameOutcome(kind: kind, score: clamped, statText: stat, xp: xp)
        store.record(o, partOfDaily: partOfDaily)
        outcome = o
        withAnimation { phase = .result }
    }

    private func finishAbandon() {
        readyTimer?.invalidate()
        onExit(nil)
    }
}

// MARK: - Result overlay

private struct ResultView: View {
    let kind: GameKind
    let outcome: GameOutcome
    var onDone: () -> Void
    @State private var appear = false

    private var stars: Int {
        if outcome.score >= 85 { return 3 }
        if outcome.score >= 60 { return 2 }
        if outcome.score >= 1 { return 1 }
        return 0
    }

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle().fill(kind.domain.colorSoft).frame(width: 150, height: 150)
                    .scaleEffect(appear ? 1 : 0.6)
                VStack(spacing: 2) {
                    Text("\(outcome.score)")
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundColor(kind.domain.color)
                    Text("score").font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(BrainTheme.subtle)
                }
            }

            HStack(spacing: 10) {
                ForEach(0..<3, id: \.self) { i in
                    BrainIcon(glyph: .star, size: 30,
                              color: i < stars ? BrainTheme.gold : BrainTheme.line, weight: 2)
                        .scaleEffect(appear ? 1 : 0.4)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.1 * Double(i)), value: appear)
                }
            }

            VStack(spacing: 6) {
                Text(outcome.statText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
                HStack(spacing: 6) {
                    BrainIcon(glyph: .spark, size: 16, color: BrainTheme.gold, weight: 2)
                    Text("+\(outcome.xp) XP")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainTheme.gold)
                }
            }

            Text(feedback)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(BrainTheme.subtle)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            Spacer()

            Button(action: onDone) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(BrainTheme.heroGradient))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true } }
    }

    private var feedback: String {
        switch stars {
        case 3: return "Sharp work. That is a top-tier round."
        case 2: return "Solid. A little more speed and you are there."
        case 1: return "Warmed up. Run it again to climb."
        default: return "Every rep counts. Give it another go."
        }
    }
}
