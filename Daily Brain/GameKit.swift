import SwiftUI

// MARK: - Haptics

enum BrainHaptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light); g.impactOccurred()
    }
    static func success() {
        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.success)
    }
    static func warn() {
        let g = UINotificationFeedbackGenerator(); g.notificationOccurred(.error)
    }
    static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft); g.impactOccurred()
    }
}

// MARK: - Status bar shown at the top of a live game

struct GameStatusBar: View {
    var left: String
    var center: String?
    var right: String
    var accent: Color

    var body: some View {
        HStack {
            pill(left)
            Spacer()
            if let c = center {
                Text(c)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(BrainTheme.ink)
            }
            Spacer()
            pill(right)
        }
        .padding(.horizontal, 16)
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(accent)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(Capsule().fill(accent.opacity(0.14)))
    }
}

// MARK: - Countdown / progress bar

struct TimerBar: View {
    var progress: Double  // 1 -> 0
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(color.opacity(0.16))
                Capsule().fill(color)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 8)
        .padding(.horizontal, 16)
    }
}

// MARK: - Reusable option button

struct OptionButton: View {
    var text: String
    var color: Color = BrainTheme.ink
    var fill: Color = BrainTheme.card
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(fill)
                    .shadow(color: BrainTheme.ink.opacity(0.06), radius: 8, y: 3))
        }
    }
}

// MARK: - Flash feedback tint over the play area

struct FlashOverlay: View {
    var tint: Color?
    var body: some View {
        Group {
            if let t = tint {
                t.opacity(0.18).ignoresSafeArea().allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Shared scoring helpers

enum GameScore {
    /// Map a value into 0...100 given a floor and ceiling.
    static func ramp(_ value: Double, floor: Double, ceil: Double) -> Int {
        guard ceil > floor else { return 0 }
        let t = (value - floor) / (ceil - floor)
        return Int((min(1, max(0, t)) * 100).rounded())
    }
    /// For reaction time in ms: faster is better. 250ms ~ 100, 650ms ~ 0.
    static func reaction(ms: Double) -> Int {
        ramp(650 - ms, floor: 0, ceil: 400)
    }
}
