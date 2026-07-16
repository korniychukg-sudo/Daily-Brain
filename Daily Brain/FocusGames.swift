import SwiftUI

private struct NamedColor { let name: String; let color: Color }

private let clashPalette: [NamedColor] = [
    NamedColor(name: "RED", color: Color(red: 0.90, green: 0.26, blue: 0.28)),
    NamedColor(name: "BLUE", color: Color(red: 0.20, green: 0.45, blue: 0.90)),
    NamedColor(name: "GREEN", color: Color(red: 0.16, green: 0.66, blue: 0.42)),
    NamedColor(name: "ORANGE", color: Color(red: 0.92, green: 0.55, blue: 0.15)),
    NamedColor(name: "PURPLE", color: Color(red: 0.55, green: 0.32, blue: 0.80))
]

// MARK: - 11. Color Clash (Stroop)

struct ColorClashGame: View {
    let onFinish: GameReport
    @State private var wordIdx = 0
    @State private var inkIdx = 1
    @State private var options: [Int] = []
    @State private var correct = 0
    @State private var streak = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    var body: some View {
        VStack(spacing: 20) {
            GameStatusBar(left: "Correct \(correct)", center: "Tap the ink color", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.focus.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.focus.color)
            Spacer()
            Text(clashPalette[wordIdx].name)
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .foregroundColor(clashPalette[inkIdx].color)
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { i in
                    Button { choose(i) } label: {
                        Text(clashPalette[i].name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 20)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(clashPalette[i].color))
                    }
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newRound(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newRound() {
        wordIdx = Int.random(in: 0..<clashPalette.count)
        repeat { inkIdx = Int.random(in: 0..<clashPalette.count) } while inkIdx == wordIdx
        var set: Set<Int> = [inkIdx]
        while set.count < 4 { set.insert(Int.random(in: 0..<clashPalette.count)) }
        options = Array(set).shuffled()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func choose(_ i: Int) {
        guard !done else { return }
        if i == inkIdx { correct += 1; streak += 1; BrainHaptics.soft(); tint(BrainDomain.focus.color) }
        else { streak = 0; BrainHaptics.warn(); tint(BrainTheme.gold) }
        newRound()
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 22)
        onFinish(score, "\(correct) correct")
    }
}

// MARK: - 12. Find Target

struct FindTargetGame: View {
    let onFinish: GameReport
    @State private var gridN = 3
    @State private var baseShape: MiniShapeKind = .circle
    @State private var oddShape: MiniShapeKind = .square
    @State private var oddIndex = 0
    @State private var found = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    var body: some View {
        VStack(spacing: 16) {
            GameStatusBar(left: "Found \(found)", center: "Spot the odd shape", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.focus.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.focus.color)
            Spacer()
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 12
                let cell = side / CGFloat(gridN)
                VStack(spacing: 6) {
                    ForEach(0..<gridN, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<gridN, id: \.self) { col in
                                let idx = row * gridN + col
                                let isOdd = idx == oddIndex
                                MiniShapeView(kind: isOdd ? oddShape : baseShape, color: BrainDomain.focus.color)
                                    .frame(width: cell - 6, height: cell - 6)
                                    .contentShape(Rectangle())
                                    .onTapGesture { tap(idx) }
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
        .onAppear { newBoard(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newBoard() {
        gridN = min(3 + found / 3, 6)
        var shapes = MiniShapeKind.allCases.shuffled()
        baseShape = shapes.removeFirst()
        oddShape = shapes.removeFirst()
        oddIndex = Int.random(in: 0..<(gridN * gridN))
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func tap(_ idx: Int) {
        guard !done else { return }
        if idx == oddIndex { found += 1; BrainHaptics.soft(); tint(BrainDomain.focus.color); newBoard() }
        else { BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 1.5) }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(found), floor: 0, ceil: 16)
        onFinish(score, "\(found) found")
    }
}

// MARK: - 13. Symbol Hunt

struct SymbolHuntGame: View {
    let onFinish: GameReport
    private let gridN = 4
    @State private var tiles: [MiniShapeKind] = []
    @State private var target: MiniShapeKind = .circle
    @State private var cleared: Set<Int> = []
    @State private var matchesFound = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    private var targetIndices: [Int] { tiles.indices.filter { tiles[$0] == target } }

    var body: some View {
        VStack(spacing: 14) {
            GameStatusBar(left: "Marks \(matchesFound)", center: nil, right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.focus.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.focus.color)
            HStack(spacing: 8) {
                Text("Tap all").font(.system(size: 16, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                MiniShapeView(kind: target, color: BrainDomain.focus.color).frame(width: 28, height: 28)
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: gridN)
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(tiles.indices, id: \.self) { i in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(cleared.contains(i) ? BrainDomain.focus.color.opacity(0.18) : BrainTheme.card)
                            .shadow(color: BrainTheme.ink.opacity(0.04), radius: 3, y: 1)
                        if !cleared.contains(i) {
                            MiniShapeView(kind: tiles[i], color: BrainTheme.ink.opacity(0.8)).padding(12)
                        } else {
                            BrainIcon(glyph: .check, size: 20, color: BrainDomain.focus.color, weight: 2.4)
                        }
                    }
                    .frame(height: 64)
                    .onTapGesture { tap(i) }
                }
            }
            .padding(.horizontal, 18)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newBoard(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newBoard() {
        let kinds = Array(MiniShapeKind.allCases.prefix(5))
        target = kinds.randomElement()!
        var arr: [MiniShapeKind] = []
        let targetCount = Int.random(in: 3...6)
        for _ in 0..<targetCount { arr.append(target) }
        while arr.count < gridN * gridN {
            let k = kinds.randomElement()!
            if k != target { arr.append(k) }
        }
        tiles = arr.shuffled()
        cleared = []
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func tap(_ i: Int) {
        guard !done, !cleared.contains(i) else { return }
        if tiles[i] == target {
            cleared.insert(i); matchesFound += 1; BrainHaptics.soft()
            if Set(targetIndices).isSubset(of: cleared) {
                tint(BrainDomain.focus.color)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { newBoard() }
            }
        } else {
            BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 1.5)
        }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(matchesFound), floor: 0, ceil: 26)
        onFinish(score, "\(matchesFound) marks")
    }
}

// MARK: - 14. Odd Color Out

struct OddColorOutGame: View {
    let onFinish: GameReport
    @State private var gridN = 3
    @State private var baseColor = Color.gray
    @State private var oddColor = Color.gray
    @State private var oddIndex = 0
    @State private var found = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    var body: some View {
        VStack(spacing: 16) {
            GameStatusBar(left: "Found \(found)", center: "Tap the different tile", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.focus.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.focus.color)
            Spacer()
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 12
                let cell = side / CGFloat(gridN)
                VStack(spacing: 6) {
                    ForEach(0..<gridN, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<gridN, id: \.self) { col in
                                let idx = row * gridN + col
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(idx == oddIndex ? oddColor : baseColor)
                                    .frame(width: cell - 6, height: cell - 6)
                                    .onTapGesture { tap(idx) }
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
        .onAppear { newBoard(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newBoard() {
        gridN = min(3 + found / 2, 6)
        let hue = Double.random(in: 0...1)
        let sat = Double.random(in: 0.45...0.7)
        let bri = Double.random(in: 0.62...0.82)
        baseColor = Color(hue: hue, saturation: sat, brightness: bri)
        // Difference shrinks as you progress (harder), floored so it stays visible.
        let delta = max(0.06, 0.20 - Double(found) * 0.012)
        oddColor = Color(hue: hue, saturation: min(1, sat + delta * 0.4), brightness: max(0.2, bri - delta))
        oddIndex = Int.random(in: 0..<(gridN * gridN))
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func tap(_ idx: Int) {
        guard !done else { return }
        if idx == oddIndex { found += 1; BrainHaptics.soft(); tint(BrainDomain.focus.color); newBoard() }
        else { BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 1.5) }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(found), floor: 0, ceil: 16)
        onFinish(score, "\(found) found")
    }
}

// MARK: - 15. Gap Count (subitizing)

struct GapCountGame: View {
    let onFinish: GameReport
    private let n = 4
    @State private var filled: Set<Int> = []
    @State private var showing = true
    @State private var options: [Int] = []
    @State private var round = 1
    @State private var correct = 0
    @State private var done = false
    @State private var showTimer: Timer?
    @State private var flash: Color?

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Round \(round)/8", center: showing ? "Look" : "How many?", right: "Correct \(correct)", accent: BrainDomain.focus.color)
            Spacer()
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height) - 16
                let cell = side / CGFloat(n)
                VStack(spacing: 6) {
                    ForEach(0..<n, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<n, id: \.self) { col in
                                let idx = row * n + col
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(showing && filled.contains(idx) ? BrainDomain.focus.color : BrainTheme.card)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(BrainTheme.line, lineWidth: 1))
                                    .frame(width: cell - 6, height: cell - 6)
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 16)
            if !showing {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(options, id: \.self) { opt in
                        Button { choose(opt) } label: {
                            Text("\(opt)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                                .frame(maxWidth: .infinity).padding(.vertical, 14)
                                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(BrainTheme.card)
                                    .shadow(color: BrainTheme.ink.opacity(0.05), radius: 4, y: 2))
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { startRound() }
        .onDisappear { showTimer?.invalidate() }
    }

    private func startRound() {
        showing = true
        let count = Int.random(in: 3...min(10, 3 + round))
        var set: Set<Int> = []
        while set.count < count { set.insert(Int.random(in: 0..<(n*n))) }
        filled = set
        var opts: Set<Int> = [count]
        while opts.count < 4 {
            let cand = count + Int.random(in: -3...3)
            if cand >= 1 && cand <= n*n { opts.insert(cand) }
        }
        options = Array(opts).shuffled()
        let showFor = max(0.6, 1.4 - Double(round) * 0.08)
        showTimer?.invalidate()
        showTimer = Timer.scheduledTimer(withTimeInterval: showFor, repeats: false) { _ in
            withAnimation { showing = false }
        }
    }

    private func choose(_ opt: Int) {
        guard !done, !showing else { return }
        if opt == filled.count { correct += 1; BrainHaptics.soft(); tint(BrainDomain.focus.color) }
        else { BrainHaptics.warn(); tint(BrainTheme.gold) }
        if round >= 8 { finish() }
        else { round += 1; DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { startRound() } }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; showTimer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onFinish(score, "\(correct)/8 right") }
    }
}
