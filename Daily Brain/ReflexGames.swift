import SwiftUI

// MARK: - 16. Tap Go (reaction time)

struct TapGoGame: View {
    let onFinish: GameReport
    private let trials = 5
    @State private var trial = 0
    @State private var waiting = true          // true = "wait", false = "go"
    @State private var goDate = Date()
    @State private var samples: [Double] = []
    @State private var message = "Wait for green"
    @State private var lastMs: Double? = nil
    @State private var armTimer: Timer?
    @State private var done = false

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Trial \(min(trial + 1, trials))/\(trials)", center: nil,
                          right: lastMs != nil ? "\(Int(lastMs!)) ms" : "—", accent: BrainDomain.reflex.color)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(waiting ? BrainTheme.subtle.opacity(0.35) : BrainDomain.reflex.color)
                VStack(spacing: 10) {
                    BrainIcon(glyph: waiting ? .clock : .reflex, size: 46, color: .white, weight: 3)
                    Text(waiting ? message : "TAP!")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(height: 320)
            .padding(.horizontal, 22)
            .onTapGesture { tap() }
            Text("Tap the instant the panel turns bright.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(BrainTheme.subtle)
            Spacer()
        }
        .onAppear { armTrial() }
        .onDisappear { armTimer?.invalidate() }
    }

    private func armTrial() {
        waiting = true
        message = "Wait for green"
        let delay = Double.random(in: 1.1...2.8)
        armTimer?.invalidate()
        armTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            waiting = false
            goDate = Date()
            BrainHaptics.soft()
        }
    }

    private func tap() {
        guard !done else { return }
        if waiting {
            // false start
            armTimer?.invalidate()
            BrainHaptics.warn()
            message = "Too early!"
            samples.append(560)
            advance()
        } else {
            let ms = Date().timeIntervalSince(goDate) * 1000
            lastMs = ms
            samples.append(ms)
            BrainHaptics.tap()
            advance()
        }
    }

    private func advance() {
        trial += 1
        if trial >= trials { finish() }
        else { DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { armTrial() } }
    }

    private func finish() {
        guard !done else { return }
        done = true; armTimer?.invalidate()
        let avg = samples.isEmpty ? 600 : samples.reduce(0, +) / Double(samples.count)
        let score = GameScore.reaction(ms: avg)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { onFinish(score, "\(Int(avg)) ms avg") }
    }
}

// MARK: - 17. Catch Green

struct CatchGreenGame: View {
    let onFinish: GameReport
    @State private var isGreen = true
    @State private var visible = false
    @State private var locked = false
    @State private var caught = 0
    @State private var mistakes = 0
    @State private var timeLeft = 25.0
    @State private var tickTimer: Timer?
    @State private var swapTimer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 25.0
    private let green = Color(red: 0.16, green: 0.70, blue: 0.42)
    private let red = Color(red: 0.90, green: 0.28, blue: 0.30)

    var body: some View {
        VStack(spacing: 18) {
            GameStatusBar(left: "Caught \(caught)", center: "Tap green, avoid red", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.reflex.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.reflex.color)
            Spacer()
            ZStack {
                if visible {
                    Circle().fill(isGreen ? green : red)
                        .frame(width: 180, height: 180)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Circle().stroke(BrainTheme.line, style: StrokeStyle(lineWidth: 3, dash: [8, 8]))
                        .frame(width: 180, height: 180)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 260)
            .contentShape(Rectangle())
            .onTapGesture { tap() }
            Text("Let every red token pass by.")
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { startTimer(); nextToken() }
        .onDisappear { tickTimer?.invalidate(); swapTimer?.invalidate() }
    }

    private func startTimer() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func nextToken() {
        guard !done else { return }
        locked = false
        isGreen = Double.random(in: 0...1) < 0.6
        withAnimation(.easeOut(duration: 0.12)) { visible = true }
        let life = Double.random(in: 0.65...1.0)
        swapTimer?.invalidate()
        swapTimer = Timer.scheduledTimer(withTimeInterval: life, repeats: false) { _ in
            withAnimation(.easeIn(duration: 0.12)) { visible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) { nextToken() }
        }
    }

    private func tap() {
        guard !done, visible, !locked else { return }
        locked = true
        if isGreen { caught += 1; BrainHaptics.soft(); tint(BrainDomain.reflex.color) }
        else { mistakes += 1; BrainHaptics.warn(); tint(BrainTheme.gold) }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; tickTimer?.invalidate(); swapTimer?.invalidate()
        let net = max(0, caught - mistakes)
        let score = GameScore.ramp(Double(net), floor: 0, ceil: 20)
        onFinish(score, "\(caught) caught")
    }
}

// MARK: - 18. Pop Order

struct PopOrderGame: View {
    let onFinish: GameReport
    @State private var target: CGPoint = .zero
    @State private var visible = false
    @State private var popped = 0
    @State private var timeLeft = 25.0
    @State private var tickTimer: Timer?
    @State private var moveTimer: Timer?
    @State private var done = false
    @State private var flash: Color?
    private let total = 25.0

    var body: some View {
        VStack(spacing: 14) {
            GameStatusBar(left: "Popped \(popped)", center: "Tap the dots fast", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.reflex.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.reflex.color)
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(BrainTheme.card)
                        .shadow(color: BrainTheme.ink.opacity(0.05), radius: 6, y: 2)
                    if visible {
                        Circle()
                            .fill(BrainDomain.reflex.color)
                            .frame(width: 62, height: 62)
                            .position(x: target.x * geo.size.width, y: target.y * geo.size.height)
                            .transition(.scale)
                            .onTapGesture { hit() }
                    }
                }
                .onAppear { relocate() }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { startTimer() }
        .onDisappear { tickTimer?.invalidate(); moveTimer?.invalidate() }
    }

    private func startTimer() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func relocate() {
        guard !done else { return }
        target = CGPoint(x: CGFloat.random(in: 0.12...0.88), y: CGFloat.random(in: 0.12...0.88))
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { visible = true }
        moveTimer?.invalidate()
        moveTimer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 1.1...1.6), repeats: false) { _ in
            relocate()  // timed out (miss) -> move on
        }
    }

    private func hit() {
        guard !done, visible else { return }
        popped += 1; BrainHaptics.soft(); tint(BrainDomain.reflex.color)
        moveTimer?.invalidate()
        visible = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { relocate() }
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; tickTimer?.invalidate(); moveTimer?.invalidate()
        let score = GameScore.ramp(Double(popped), floor: 0, ceil: 24)
        onFinish(score, "\(popped) popped")
    }
}

// MARK: - 19. Arrow Rush

struct ArrowRushGame: View {
    let onFinish: GameReport
    enum Dir: CaseIterable { case up, down, left, right
        var angle: Double { switch self { case .up: return -90; case .down: return 90; case .left: return 180; case .right: return 0 } }
    }
    @State private var dir: Dir = .right
    @State private var correct = 0
    @State private var timeLeft = 25.0
    @State private var timer: Timer?
    @State private var done = false
    @State private var flash: Color?
    @State private var wobble = false
    private let total = 25.0

    var body: some View {
        VStack(spacing: 16) {
            GameStatusBar(left: "Correct \(correct)", center: "Swipe where it points", right: "\(Int(ceil(timeLeft)))s", accent: BrainDomain.reflex.color)
            TimerBar(progress: timeLeft / total, color: BrainDomain.reflex.color)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(BrainDomain.reflex.color.opacity(0.12))
                ArrowShape()
                    .fill(BrainDomain.reflex.color)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(dir.angle))
                    .scaleEffect(wobble ? 0.9 : 1)
                    .animation(.easeOut(duration: 0.12), value: wobble)
            }
            .frame(height: 320)
            .padding(.horizontal, 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { g in handleSwipe(g.translation) }
            )
            Text("Flick in the arrow's direction.")
                .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
            Spacer()
        }
        .overlay(FlashOverlay(tint: flash))
        .onAppear { newArrow(); startTimer() }
        .onDisappear { timer?.invalidate() }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeLeft -= 0.1; if timeLeft <= 0 { finish() }
        }
    }

    private func newArrow() { dir = Dir.allCases.randomElement()! }

    private func handleSwipe(_ t: CGSize) {
        guard !done else { return }
        let swiped: Dir
        if abs(t.width) > abs(t.height) { swiped = t.width > 0 ? .right : .left }
        else { swiped = t.height > 0 ? .down : .up }
        wobble = true; DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { wobble = false }
        if swiped == dir { correct += 1; BrainHaptics.soft(); tint(BrainDomain.reflex.color) }
        else { BrainHaptics.warn(); tint(BrainTheme.gold); timeLeft = max(0, timeLeft - 1) }
        newArrow()
    }

    private func tint(_ c: Color) { flash = c; DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { flash = nil } }

    private func finish() {
        guard !done else { return }
        done = true; timer?.invalidate()
        let score = GameScore.ramp(Double(correct), floor: 0, ceil: 24)
        onFinish(score, "\(correct) swipes")
    }
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let midY = h / 2
        p.move(to: CGPoint(x: 0, y: midY - h*0.14))
        p.addLine(to: CGPoint(x: w*0.55, y: midY - h*0.14))
        p.addLine(to: CGPoint(x: w*0.55, y: midY - h*0.34))
        p.addLine(to: CGPoint(x: w, y: midY))
        p.addLine(to: CGPoint(x: w*0.55, y: midY + h*0.34))
        p.addLine(to: CGPoint(x: w*0.55, y: midY + h*0.14))
        p.addLine(to: CGPoint(x: 0, y: midY + h*0.14))
        p.closeSubpath()
        return p
    }
}
