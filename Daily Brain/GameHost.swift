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
            backdrop
            VStack(spacing: 0) {
                header
                content
            }
        }
        .onDisappear { readyTimer?.invalidate() }
    }

    /// Ambient domain art behind the whole game flow, dimmed for readability.
    private var backdrop: some View {
        ZStack {
            BrainTheme.midnightGradient
            if let ui = BrainArtLoader.image(named: kind.domain.backdropAsset) {
                GeometryReader { geo in
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .opacity(0.55)
                }
                Color.black.opacity(0.30)
            }
            GrainOverlay(opacity: 0.28)
        }
        .ignoresSafeArea()
    }

    // MARK: Header

    private var header: some View {
        HStack {
            Button { finishAbandon() } label: {
                ZStack {
                    Circle().fill(BrainTheme.card).frame(width: 38, height: 38)
                        .overlay(Circle().strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                    BrainIcon(glyph: .close, size: 18, color: BrainTheme.ink, weight: 2)
                }
            }
            .buttonStyle(PressableScaleStyle())
            Spacer()
            Text(kind.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            Spacer()
            Circle().fill(kind.domain.color).frame(width: 12, height: 12)
                .luxeGlow(kind.domain.color, radius: 8, opacity: 0.8)
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
                    .frame(height: 190)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                    .luxeGlow(kind.domain.color, radius: 24, opacity: 0.35)
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
                    .luxeGlow(BrainTheme.primary, radius: 16, opacity: 0.45)
                }
                .buttonStyle(PressableScaleStyle())
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
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(BrainTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(BrainTheme.cardStroke, lineWidth: 1)))
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
    @EnvironmentObject var store: BrainStore
    @State private var appear = false
    @State private var confetti = false
    @State private var newAwards: [BrainAward] = []

    private var stars: Int {
        if outcome.score >= 85 { return 3 }
        if outcome.score >= 60 { return 2 }
        if outcome.score >= 1 { return 1 }
        return 0
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle().fill(kind.domain.colorSoft).frame(width: 158, height: 158)
                            .overlay(Circle().strokeBorder(kind.domain.color.opacity(0.5), lineWidth: 1.5))
                            .luxeGlow(kind.domain.color, radius: 30, opacity: 0.45)
                            .scaleEffect(appear ? 1 : 0.6)
                        VStack(spacing: 2) {
                            CountUpText(target: outcome.score,
                                        font: .system(size: 56, weight: .heavy, design: .rounded),
                                        color: kind.domain.color)
                            Text("score").font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(BrainTheme.subtle)
                        }
                    }
                    .padding(.top, 36)

                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { i in
                            BrainIcon(glyph: .star, size: 32,
                                      color: i < stars ? BrainTheme.gold : BrainTheme.line, weight: 2)
                                .luxeGlow(i < stars ? BrainTheme.gold : .clear, radius: 10,
                                          opacity: i < stars ? 0.6 : 0)
                                .scaleEffect(appear ? 1 : 0.3)
                                .animation(.spring(response: 0.45, dampingFraction: 0.55).delay(0.25 + 0.14 * Double(i)), value: appear)
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

                    ForEach(newAwards) { award in
                        HStack(spacing: 14) {
                            AwardBadgeView(award: award, unlocked: true, size: 56)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Award unlocked")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                                    .foregroundColor(BrainTheme.gold)
                                    .tracking(0.8)
                                Text(award.title)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(BrainTheme.ink)
                                Text(award.blurb)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(BrainTheme.subtle)
                            }
                            Spacer()
                        }
                        .brainCard(padding: 14)
                        .padding(.horizontal, 24)
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button(action: onDone) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(BrainTheme.heroGradient))
                            .luxeGlow(BrainTheme.primary, radius: 16, opacity: 0.45)
                    }
                    .buttonStyle(PressableScaleStyle())
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
            }
            BrainConfetti(trigger: confetti)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { appear = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.5)) {
                newAwards = store.drainPendingAwards()
            }
            if stars == 3 {
                BrainHaptics.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { confetti = true }
            }
        }
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
