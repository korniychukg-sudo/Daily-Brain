import SwiftUI

// Simple geometric glyphs used across memory games.
enum MiniShapeKind: Int, CaseIterable {
    case circle, square, triangle, diamond, plus, ring, star, chevron

    func draw(in ctx: inout GraphicsContext, rect: CGRect, color: Color) {
        let s = min(rect.width, rect.height)
        let cx = rect.midX, cy = rect.midY
        let r = s * 0.34
        var path = Path()
        switch self {
        case .circle:
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r))
            ctx.fill(path, with: .color(color))
        case .square:
            path.addRoundedRect(in: CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r), cornerSize: CGSize(width: r*0.25, height: r*0.25))
            ctx.fill(path, with: .color(color))
        case .triangle:
            path.move(to: CGPoint(x: cx, y: cy - r))
            path.addLine(to: CGPoint(x: cx + r, y: cy + r))
            path.addLine(to: CGPoint(x: cx - r, y: cy + r))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
        case .diamond:
            path.move(to: CGPoint(x: cx, y: cy - r))
            path.addLine(to: CGPoint(x: cx + r, y: cy))
            path.addLine(to: CGPoint(x: cx, y: cy + r))
            path.addLine(to: CGPoint(x: cx - r, y: cy))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
        case .plus:
            let t = r * 0.5
            path.addRoundedRect(in: CGRect(x: cx - t/2, y: cy - r, width: t, height: 2*r), cornerSize: CGSize(width: 2, height: 2))
            path.addRoundedRect(in: CGRect(x: cx - r, y: cy - t/2, width: 2*r, height: t), cornerSize: CGSize(width: 2, height: 2))
            ctx.fill(path, with: .color(color))
        case .ring:
            path.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: 2*r, height: 2*r))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: s*0.11))
        case .star:
            var sp = Path(); let pts = 5; let step = CGFloat.pi/CGFloat(pts); var a = -CGFloat.pi/2
            for i in 0..<(pts*2) { let rr = (i%2==0) ? r : r*0.44; let p = CGPoint(x: cx+cos(a)*rr, y: cy+sin(a)*rr); if i==0 { sp.move(to:p) } else { sp.addLine(to:p) }; a += step }
            sp.closeSubpath(); ctx.fill(sp, with: .color(color))
        case .chevron:
            path.move(to: CGPoint(x: cx - r*0.7, y: cy - r*0.7))
            path.addLine(to: CGPoint(x: cx + r*0.7, y: cy))
            path.addLine(to: CGPoint(x: cx - r*0.7, y: cy + r*0.7))
            ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: s*0.16, lineCap: .round, lineJoin: .round))
        }
    }
}

struct MiniShapeView: View {
    let kind: MiniShapeKind
    var color: Color
    var body: some View {
        Canvas { ctx, size in
            var c = ctx
            kind.draw(in: &c, rect: CGRect(origin: .zero, size: size), color: color)
        }
    }
}

// MARK: - 1. Grid Recall

struct GridRecallGame: View {
    let onFinish: GameReport
    private let n = 4
    @State private var round = 1
    @State private var targets: Set<Int> = []
    @State private var found: Set<Int> = []
    @State private var showing = true
    @State private var showTimer: Timer?
    @State private var flash: Color?
    @State private var done = false
    @State private var bestCount = 0

    private var count: Int { min(2 + round, 9) }

    var body: some View {
        VStack(spacing: 20) {
            GameStatusBar(left: "Round \(round)", center: showing ? "Memorize" : "Reproduce",
                          right: "\(count) cells", accent: BrainDomain.memory.color)
            Spacer()
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 20
                let cell = side / CGFloat(n)
                VStack(spacing: 6) {
                    ForEach(0..<n, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<n, id: \.self) { col in
                                let idx = row * n + col
                                cellView(idx)
                                    .frame(width: cell - 6, height: cell - 6)
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { startRound() }
        .onDisappear { showTimer?.invalidate() }
    }

    private func cellView(_ idx: Int) -> some View {
        let lit = showing && targets.contains(idx)
        let hit = found.contains(idx)
        return RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(lit || hit ? BrainDomain.memory.color : BrainTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(BrainTheme.line, lineWidth: 1))
            .shadow(color: BrainTheme.ink.opacity(0.04), radius: 4, y: 2)
            .scaleEffect(hit ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: hit)
            .onTapGesture { tap(idx) }
    }

    private func startRound() {
        found = []
        showing = true
        var t: Set<Int> = []
        while t.count < count { t.insert(Int.random(in: 0..<(n*n))) }
        targets = t
        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: 0.7 + Double(count) * 0.22, repeats: false) { _ in
            withAnimation { showing = false }
        }
    }

    private func tap(_ idx: Int) {
        guard !showing, !done else { return }
        if targets.contains(idx) {
            if found.contains(idx) { return }
            BrainHaptics.soft()
            found.insert(idx)
            if found.count == targets.count {
                bestCount = max(bestCount, count)
                flashTint(BrainDomain.memory.color)
                if round >= 8 { finish() }
                else { round += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { startRound() } }
            }
        } else {
            BrainHaptics.warn()
            flashTint(BrainTheme.gold)
            bestCount = max(bestCount, count - 1)
            finish()
        }
    }

    private func flashTint(_ c: Color) {
        flash = c
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { flash = nil }
    }

    private func finish() {
        guard !done else { return }
        done = true
        showTimer?.invalidate()
        let score = GameScore.ramp(Double(bestCount), floor: 2, ceil: 9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onFinish(score, "\(bestCount) cells")
        }
    }
}

// MARK: - 2. Symbol Pairs

struct SymbolPairsGame: View {
    let onFinish: GameReport
    private let cols = 3
    private let pairCount = 6
    @State private var deck: [MiniShapeKind] = []
    @State private var revealed: [Int] = []
    @State private var matched: Set<Int> = []
    @State private var lock = false
    @State private var tries = 0
    @State private var done = false

    private let palette: [Color] = [
        BrainDomain.memory.color, BrainDomain.numbers.color, BrainDomain.focus.color,
        BrainDomain.reflex.color, BrainTheme.gold, BrainTheme.primaryDark
    ]

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Flips \(tries)", center: "Match all pairs",
                          right: "\(matched.count/2)/\(pairCount)", accent: BrainDomain.memory.color)
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: cols)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(deck.indices, id: \.self) { i in
                    card(i)
                }
            }
            .padding(.horizontal, 22)
            Spacer()
        }
        .onAppear { setup() }
    }

    private func card(_ i: Int) -> some View {
        let up = revealed.contains(i) || matched.contains(i)
        return ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(up ? BrainTheme.card : BrainTheme.primarySoft)
                .shadow(color: BrainTheme.ink.opacity(0.06), radius: 6, y: 3)
            if up {
                MiniShapeView(kind: deck[i], color: palette[deck[i].rawValue % palette.count])
                    .padding(18)
            } else {
                BrainIcon(glyph: .brain, size: 26, color: BrainTheme.primary.opacity(0.5), weight: 2)
            }
        }
        .frame(height: 92)
        .opacity(matched.contains(i) ? 0.45 : 1)
        .onTapGesture { flip(i) }
    }

    private func setup() {
        let kinds = Array(MiniShapeKind.allCases.prefix(pairCount))
        var d = kinds + kinds
        d.shuffle()
        deck = d
    }

    private func flip(_ i: Int) {
        guard !lock, !done, !revealed.contains(i), !matched.contains(i) else { return }
        BrainHaptics.tap()
        revealed.append(i)
        if revealed.count == 2 {
            tries += 1
            lock = true
            let a = revealed[0], b = revealed[1]
            if deck[a] == deck[b] {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    matched.insert(a); matched.insert(b)
                    revealed = []; lock = false
                    BrainHaptics.success()
                    if matched.count == deck.count { finish() }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    revealed = []; lock = false
                }
            }
        }
    }

    private func finish() {
        guard !done else { return }
        done = true
        // Perfect = pairCount flips. Worse as tries grow.
        let score = GameScore.ramp(Double(pairCount * 2 - tries) + Double(pairCount), floor: 0, ceil: Double(pairCount) + 2)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onFinish(score, "\(tries) flips")
        }
    }
}

// MARK: - 3. Sequence Echo

struct SequenceEchoGame: View {
    let onFinish: GameReport
    @State private var sequence: [Int] = []
    @State private var inputIdx = 0
    @State private var activePad: Int? = nil
    @State private var showing = true
    @State private var level = 1
    @State private var done = false
    @State private var playTimer: Timer?

    private let padColors: [Color] = [
        BrainDomain.memory.color, BrainDomain.numbers.color,
        BrainDomain.focus.color, BrainDomain.reflex.color
    ]

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Level \(level)", center: showing ? "Watch" : "Repeat",
                          right: "\(sequence.count) steps", accent: BrainDomain.memory.color)
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(0..<4, id: \.self) { pad in
                    padView(pad)
                }
            }
            .padding(.horizontal, 30)
            Spacer()
        }
        .onAppear { startLevel() }
        .onDisappear { playTimer?.invalidate() }
    }

    private func padView(_ pad: Int) -> some View {
        let active = activePad == pad
        return RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(padColors[pad].opacity(active ? 1 : 0.32))
            .frame(height: 120)
            .scaleEffect(active ? 1.04 : 1)
            .animation(.easeOut(duration: 0.12), value: active)
            .onTapGesture { tapPad(pad) }
    }

    private func startLevel() {
        showing = true
        inputIdx = 0
        sequence.append(Int.random(in: 0..<4))
        playSequence()
    }

    private func playSequence() {
        var step = 0
        playTimer?.invalidate()
        playTimer = Timer.scheduledTimer(withTimeInterval: 0.62, repeats: true) { t in
            if step >= sequence.count {
                t.invalidate()
                activePad = nil
                showing = false
                return
            }
            let pad = sequence[step]
            activePad = pad
            BrainHaptics.soft()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
                if activePad == pad { activePad = nil }
            }
            step += 1
        }
    }

    private func tapPad(_ pad: Int) {
        guard !showing, !done else { return }
        activePad = pad
        BrainHaptics.tap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { if activePad == pad { activePad = nil } }
        if sequence[inputIdx] == pad {
            inputIdx += 1
            if inputIdx == sequence.count {
                if level >= 9 { finish(reached: level) }
                else { level += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startLevel() } }
            }
        } else {
            BrainHaptics.warn()
            finish(reached: level - 1)
        }
    }

    private func finish(reached: Int) {
        guard !done else { return }
        done = true
        playTimer?.invalidate()
        let steps = max(0, reached)
        let score = GameScore.ramp(Double(steps), floor: 1, ceil: 9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onFinish(score, "\(steps) steps")
        }
    }
}

// MARK: - 4. Number Span

struct NumberSpanGame: View {
    let onFinish: GameReport
    @State private var digits: [Int] = []
    @State private var entry: [Int] = []
    @State private var showing = true
    @State private var span = 3
    @State private var bestSpan = 0
    @State private var done = false
    @State private var showTimer: Timer?

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Span \(span)", center: showing ? "Memorize" : "Type it back",
                          right: "\(entry.count)/\(digits.count)", accent: BrainDomain.memory.color)
            Spacer()
            if showing {
                Text(digits.map(String.init).joined(separator: "  "))
                    .font(.system(size: 46, weight: .heavy, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
                    .padding(.vertical, 30)
            } else {
                Text(entry.isEmpty ? "· · ·" : entry.map(String.init).joined(separator: "  "))
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundColor(BrainTheme.primary)
                    .padding(.vertical, 24)
                keypad
            }
            Spacer()
        }
        .onAppear { startSpan() }
        .onDisappear { showTimer?.invalidate() }
    }

    private var keypad: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(1...9, id: \.self) { key in keyButton("\(key)", value: key) }
            keyButton("←", value: -1)
            keyButton("0", value: 0)
            keyButton("OK", value: -2)
        }
        .padding(.horizontal, 26)
    }

    private func keyButton(_ label: String, value: Int) -> some View {
        Button {
            press(value)
        } label: {
            Text(label)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(value < 0 ? BrainTheme.subtle : BrainTheme.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(BrainTheme.card)
                    .shadow(color: BrainTheme.ink.opacity(0.05), radius: 4, y: 2))
        }
    }

    private func startSpan() {
        entry = []
        showing = true
        digits = (0..<span).map { _ in Int.random(in: 0...9) }
        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: 0.7 + Double(span) * 0.6, repeats: false) { _ in
            withAnimation { showing = false }
        }
    }

    private func press(_ value: Int) {
        guard !showing, !done else { return }
        if value == -1 { if !entry.isEmpty { entry.removeLast() }; BrainHaptics.tap(); return }
        if value == -2 { submit(); return }
        if entry.count < digits.count {
            entry.append(value); BrainHaptics.tap()
            if entry.count == digits.count { submit() }
        }
    }

    private func submit() {
        guard entry.count == digits.count else { return }
        if entry == digits {
            bestSpan = max(bestSpan, span)
            BrainHaptics.success()
            if span >= 9 { finish() }
            else { span += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { startSpan() } }
        } else {
            BrainHaptics.warn()
            bestSpan = max(bestSpan, span - 1)
            finish()
        }
    }

    private func finish() {
        guard !done else { return }
        done = true
        showTimer?.invalidate()
        let score = GameScore.ramp(Double(bestSpan), floor: 2, ceil: 9)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onFinish(score, "\(bestSpan) digits")
        }
    }
}

// MARK: - 5. Where Was It

struct WhereWasItGame: View {
    let onFinish: GameReport
    private let n = 3
    @State private var placement: [Int: MiniShapeKind] = [:]  // tile -> shape
    @State private var target: MiniShapeKind = .circle
    @State private var showing = true
    @State private var round = 1
    @State private var bestRound = 0
    @State private var done = false
    @State private var showTimer: Timer?
    @State private var flash: Color?

    private let palette: [Color] = [
        BrainDomain.memory.color, BrainDomain.numbers.color, BrainDomain.focus.color,
        BrainDomain.reflex.color, BrainTheme.gold
    ]
    private var count: Int { min(2 + round, 5) }

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Round \(round)", center: showing ? "Memorize" : "Find it",
                          right: "\(count) shapes", accent: BrainDomain.memory.color)
            Spacer()
            if !showing {
                HStack(spacing: 8) {
                    Text("Where was").font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                    MiniShapeView(kind: target, color: palette[target.rawValue % palette.count])
                        .frame(width: 30, height: 30)
                    Text("?").font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                }
            }
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 20
                let cell = side / CGFloat(n)
                VStack(spacing: 8) {
                    ForEach(0..<n, id: \.self) { row in
                        HStack(spacing: 8) {
                            ForEach(0..<n, id: \.self) { col in
                                tile(row * n + col).frame(width: cell - 8, height: cell - 8)
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { startRound() }
        .onDisappear { showTimer?.invalidate() }
    }

    private func tile(_ idx: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(BrainTheme.card)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(BrainTheme.line, lineWidth: 1))
                .shadow(color: BrainTheme.ink.opacity(0.04), radius: 4, y: 2)
            if showing, let shape = placement[idx] {
                MiniShapeView(kind: shape, color: palette[shape.rawValue % palette.count]).padding(16)
            }
        }
        .onTapGesture { tap(idx) }
    }

    private func startRound() {
        showing = true
        placement = [:]
        var tiles = Array(0..<(n*n)).shuffled()
        var shapes = MiniShapeKind.allCases.shuffled()
        for _ in 0..<count {
            guard let tile = tiles.popLast(), let shape = shapes.popLast() else { break }
            placement[tile] = shape
        }
        target = placement.randomElement()?.value ?? .circle
        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: 0.9 + Double(count) * 0.35, repeats: false) { _ in
            withAnimation { showing = false }
        }
    }

    private func tap(_ idx: Int) {
        guard !showing, !done else { return }
        let correctTile = placement.first(where: { $0.value == target })?.key
        if idx == correctTile {
            BrainHaptics.success()
            bestRound = max(bestRound, round)
            flashTint(BrainDomain.memory.color)
            if round >= 7 { finish() }
            else { round += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { startRound() } }
        } else {
            BrainHaptics.warn()
            flashTint(BrainTheme.gold)
            bestRound = max(bestRound, round - 1)
            finish()
        }
    }

    private func flashTint(_ c: Color) {
        flash = c
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { flash = nil }
    }

    private func finish() {
        guard !done else { return }
        done = true
        showTimer?.invalidate()
        let score = GameScore.ramp(Double(bestRound), floor: 0, ceil: 7)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onFinish(score, "round \(max(1,bestRound))")
        }
    }
}
