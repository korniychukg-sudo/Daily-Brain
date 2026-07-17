import SwiftUI

// Shared 30s countdown driver.
private struct CountdownState {
    var total: Double
    var left: Double
}

// MARK: - 6. Quick Sums

struct QuickSumsGame: View {
    let onFinish: GameReport
    @State private var a = 0
    @State private var b = 0
    @State private var op = "+"
    @State private var answer = 0
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
            GameStatusBar(left: "Solved \(correct)", center: nil, right: "Streak \(streak)", accent: BrainDomain.numbers.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.numbers.color)
            Spacer()
            Text("\(a)  \(op)  \(b)")
                .font(.system(size: 52, weight: .heavy, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            Text("= ?").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.subtle)
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(options, id: \.self) { opt in
                    OptionButton(text: "\(opt)", color: BrainTheme.ink) { choose(opt) }
                }
            }
            .padding(.horizontal, 20)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newProblem(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newProblem() {
        let ops = ["+", "-", "×"]
        op = ops.randomElement()!
        switch op {
        case "+": a = Int.random(in: 4...40); b = Int.random(in: 3...40); answer = a + b
        case "-": a = Int.random(in: 10...50); b = Int.random(in: 2...a); answer = a - b
        default:  a = Int.random(in: 2...12); b = Int.random(in: 2...9); answer = a * b
        }
        var set: Set<Int> = [answer]
        while set.count < 4 {
            let delta = Int.random(in: -6...6)
            let cand = answer + (delta == 0 ? 7 : delta)
            if cand >= 0 { set.insert(cand) }
        }
        options = Array(set).shuffled()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func choose(_ opt: Int) {
        guard !done else { return }
        if opt == answer {
            correct += 1; streak += 1; BrainHaptics.soft(); tint(BrainDomain.numbers.color)
        } else {
            streak = 0; BrainHaptics.warn(); tint(BrainTheme.gold)
        }
        newProblem()
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 20)
        onFinish(score, "\(correct) solved")
    }
}

// MARK: - 7. Equation Pick

struct EquationPickGame: View {
    let onFinish: GameReport
    @State private var target = 0
    @State private var options: [(String, Int)] = []
    @State private var correct = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Hits \(correct)", center: nil, right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.numbers.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.numbers.color)
            Spacer()
            VStack(spacing: 4) {
                Text("Target").font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                Text("\(target)").font(.system(size: 56, weight: .heavy, design: .rounded)).foregroundColor(BrainDomain.numbers.color)
            }
            Spacer()
            VStack(spacing: 12) {
                ForEach(options.indices, id: \.self) { i in
                    OptionButton(text: options[i].0, color: BrainTheme.ink) { choose(options[i].1) }
                }
            }
            .padding(.horizontal, 22)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newProblem(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func makeExpr(result: Int?) -> (String, Int) {
        let ops = ["+", "-", "×"]
        let op = ops.randomElement()!
        var x = 0, y = 0, val = 0, tries = 0
        repeat {
            switch op {
            case "+": x = Int.random(in: 3...30); y = Int.random(in: 2...30); val = x + y
            case "-": x = Int.random(in: 8...40); y = Int.random(in: 2...x); val = x - y
            default:  x = Int.random(in: 2...12); y = Int.random(in: 2...9); val = x * y
            }
            tries += 1
        } while (result != nil && val != result! && tries < 40)
        return ("\(x) \(op) \(y)", val)
    }

    private func newProblem() {
        // target chosen, one correct expr equals it, others differ
        let base = makeExpr(result: nil)
        target = base.1
        var opts: [(String, Int)] = [base]
        var guard2 = 0
        while opts.count < 4 && guard2 < 60 {
            let e = makeExpr(result: nil)
            if e.1 != target && !opts.contains(where: { $0.1 == e.1 }) { opts.append(e) }
            guard2 += 1
        }
        while opts.count < 4 {
            let k = opts.count  // consistent text and value for the filler distractor
            opts.append(("\(target) + \(k)", target + k))
        }
        options = opts.shuffled()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func choose(_ val: Int) {
        guard !done else { return }
        if val == target { correct += 1; BrainHaptics.soft(); tint(BrainDomain.numbers.color) }
        else { BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 2) }
        newProblem()
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 16)
        onFinish(score, "\(correct) hits")
    }
}

// MARK: - 8. Number Sort

struct NumberSortGame: View {
    let onFinish: GameReport
    @State private var numbers: [Int] = []
    @State private var nextIndex = 0            // position in sorted order
    @State private var tapped: Set<Int> = []    // tapped values
    @State private var boards = 0
    @State private var timeLeft = 35.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 35.0
    private let perBoard = 6

    private var sorted: [Int] { numbers.sorted() }

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Boards \(boards)", center: "Small → large", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.numbers.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.numbers.color)
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(numbers, id: \.self) { num in
                    numberTile(num)
                }
            }
            .padding(.horizontal, 22)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newBoard(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func numberTile(_ num: Int) -> some View {
        let isTapped = tapped.contains(num)
        return Text("\(num)")
            .font(.system(size: 26, weight: .bold, design: .rounded))
            .foregroundColor(isTapped ? .white : BrainTheme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isTapped ? BrainDomain.numbers.color : BrainTheme.card)
                .shadow(color: BrainTheme.ink.opacity(0.05), radius: 5, y: 2))
            .opacity(isTapped ? 0.55 : 1)
            .onTapGesture { tap(num) }
    }

    private func newBoard() {
        var set: Set<Int> = []
        while set.count < perBoard { set.insert(Int.random(in: 1...99)) }
        numbers = Array(set).shuffled()
        nextIndex = 0
        tapped = []
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func tap(_ num: Int) {
        guard !done, !tapped.contains(num) else { return }
        if num == sorted[nextIndex] {
            tapped.insert(num); nextIndex += 1; BrainHaptics.soft()
            if nextIndex == numbers.count {
                boards += 1; tint(BrainDomain.numbers.color)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { newBoard() }
            }
        } else {
            BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 2)
        }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(boards), floor: 0, ceil: 7)
        onFinish(score, "\(boards) boards")
    }
}

// MARK: - 9. Change Maker

struct ChangeMakerGame: View {
    let onFinish: GameReport
    private let coins = [1, 2, 5, 10]
    @State private var target = 0
    @State private var current = 0
    @State private var made = 0
    @State private var timeLeft = 35.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 35.0

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Made \(made)", center: nil, right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.numbers.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.numbers.color)
            Spacer()
            VStack(spacing: 6) {
                Text("Reach exactly").font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                Text("\(target)").font(.system(size: 54, weight: .heavy, design: .rounded)).foregroundColor(BrainDomain.numbers.color)
                Text("current: \(current)").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            }
            Spacer()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 2)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(coins, id: \.self) { coin in
                    Button { add(coin) } label: {
                        ZStack {
                            Circle().fill(BrainTheme.goldSoft).frame(height: 76)
                            Circle().stroke(BrainTheme.gold, lineWidth: 3).frame(height: 76)
                            Text("+\(coin)").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(BrainTheme.gold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 40)
            Button { reset() } label: {
                Text("Clear").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.subtle)
                    .padding(.horizontal, 22).padding(.vertical, 9)
                    .background(Capsule().fill(BrainTheme.card))
            }
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newTarget(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func newTarget() {
        target = Int.random(in: 8...28)
        current = 0
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func add(_ coin: Int) {
        guard !done else { return }
        current += coin; BrainHaptics.tap()
        if current == target {
            made += 1; BrainHaptics.success(); tint(BrainDomain.numbers.color)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { newTarget() }
        } else if current > target {
            BrainHaptics.warn(); tint(BrainTheme.gold); current = 0
        }
    }

    private func reset() { current = 0; BrainHaptics.tap() }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(made), floor: 0, ceil: 9)
        onFinish(score, "\(made) made")
    }
}

// MARK: - 10. Balance Scale

struct BalanceScaleGame: View {
    let onFinish: GameReport
    @State private var leftValues: [Int] = []
    @State private var rightValues: [Int] = []
    @State private var correct = 0
    @State private var rounds = 0
    @State private var timeLeft = 30.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 30.0

    var body: some View {
        VStack(spacing: 16) {
            GameStatusBar(left: "Right \(correct)", center: nil, right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.numbers.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.numbers.color)
            Spacer()
            HStack(spacing: 16) {
                tray(values: leftValues, label: "Left")
                tray(values: rightValues, label: "Right")
            }
            .padding(.horizontal, 20)
            Spacer()
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    choiceButton("Left", .left)
                    choiceButton("Right", .right)
                }
                choiceButton("Even", .even)
            }
            .padding(.horizontal, 22)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newRound(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private enum Side { case left, right, even }

    private func tray(values: [Int], label: String) -> some View {
        VStack(spacing: 8) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(values.indices, id: \.self) { i in
                    ZStack {
                        Circle().fill(BrainDomain.numbers.color).frame(width: 34, height: 34)
                        Text("\(values[i])").font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    }
                }
            }
            .frame(minHeight: 96, alignment: .top)
            Text(label).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(BrainTheme.card)
            .shadow(color: BrainTheme.ink.opacity(0.05), radius: 6, y: 2))
    }

    private func choiceButton(_ label: String, _ side: Side) -> some View {
        Button { choose(side) } label: {
            Text(label).font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(BrainTheme.card)
                    .shadow(color: BrainTheme.ink.opacity(0.05), radius: 5, y: 2))
        }
    }

    private func newRound() {
        leftValues = (0..<Int.random(in: 2...4)).map { _ in Int.random(in: 1...5) }
        rightValues = (0..<Int.random(in: 2...4)).map { _ in Int.random(in: 1...5) }
        // Nudge ~1/5 of the time to an exact tie so "Even" is a live answer.
        if Int.random(in: 0..<5) == 0 {
            let diff = leftValues.reduce(0, +) - rightValues.reduce(0, +)
            if diff > 0 { rightValues.append(diff) }
            else if diff < 0 { leftValues.append(-diff) }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1
            if timeLeft <= 0 { finish() }
        }
    }

    private func choose(_ side: Side) {
        guard !done else { return }
        rounds += 1
        let lw = leftValues.reduce(0, +), rw = rightValues.reduce(0, +)
        let answer: Side = lw == rw ? .even : (lw > rw ? .left : .right)
        if side == answer { correct += 1; BrainHaptics.soft(); tint(BrainDomain.numbers.color) }
        else { BrainHaptics.warn(); tint(BrainTheme.gold) }
        newRound()
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 14)
        onFinish(score, "\(correct) right")
    }
}
