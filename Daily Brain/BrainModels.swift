import SwiftUI

// MARK: - Cognitive domains

enum BrainDomain: String, CaseIterable, Codable, Identifiable {
    case memory
    case numbers
    case focus
    case reflex

    var id: String { rawValue }

    var title: String {
        switch self {
        case .memory:  return "Memory"
        case .numbers: return "Numbers"
        case .focus:   return "Focus"
        case .reflex:  return "Reflex"
        }
    }

    var blurb: String {
        switch self {
        case .memory:  return "Hold and recall patterns, symbols and sequences."
        case .numbers: return "Calculate, compare and order under light pressure."
        case .focus:   return "Filter distractions and lock on the right target."
        case .reflex:  return "Read the signal and respond in a heartbeat."
        }
    }

    var color: Color {
        switch self {
        case .memory:  return Color(red: 0.396, green: 0.310, blue: 0.902) // violet
        case .numbers: return Color(red: 0.043, green: 0.588, blue: 0.533) // teal
        case .focus:   return Color(red: 0.921, green: 0.451, blue: 0.176) // orange
        case .reflex:  return Color(red: 0.902, green: 0.310, blue: 0.478) // rose
        }
    }

    var colorSoft: Color { color.opacity(0.16) }

    /// Banner asset base name (art pack).
    var bannerAsset: String { "banner_\(rawValue)" }
}

// MARK: - Mini-games

enum GameKind: String, CaseIterable, Codable, Identifiable {
    // Memory
    case gridRecall
    case symbolPairs
    case sequenceEcho
    case numberSpan
    case whereWasIt
    // Numbers
    case quickSums
    case equationPick
    case numberSort
    case changeMaker
    case balanceScale
    // Focus
    case colorClash
    case findTarget
    case symbolHunt
    case oddColorOut
    case gapCount
    // Reflex
    case tapGo
    case catchGreen
    case popOrder
    case arrowRush

    var id: String { rawValue }

    var domain: BrainDomain {
        switch self {
        case .gridRecall, .symbolPairs, .sequenceEcho, .numberSpan, .whereWasIt:
            return .memory
        case .quickSums, .equationPick, .numberSort, .changeMaker, .balanceScale:
            return .numbers
        case .colorClash, .findTarget, .symbolHunt, .oddColorOut, .gapCount:
            return .focus
        case .tapGo, .catchGreen, .popOrder, .arrowRush:
            return .reflex
        }
    }

    var title: String {
        switch self {
        case .gridRecall:   return "Grid Recall"
        case .symbolPairs:  return "Symbol Pairs"
        case .sequenceEcho: return "Sequence Echo"
        case .numberSpan:   return "Number Span"
        case .whereWasIt:   return "Where Was It"
        case .quickSums:    return "Quick Sums"
        case .equationPick: return "Equation Pick"
        case .numberSort:   return "Number Sort"
        case .changeMaker:  return "Change Maker"
        case .balanceScale: return "Balance Scale"
        case .colorClash:   return "Color Clash"
        case .findTarget:   return "Find Target"
        case .symbolHunt:   return "Symbol Hunt"
        case .oddColorOut:  return "Odd Color Out"
        case .gapCount:     return "Gap Count"
        case .tapGo:        return "Tap Go"
        case .catchGreen:   return "Catch Green"
        case .popOrder:     return "Pop Order"
        case .arrowRush:    return "Arrow Rush"
        }
    }

    var tagline: String {
        switch self {
        case .gridRecall:   return "Redraw the pattern you just saw."
        case .symbolPairs:  return "Flip and match every hidden pair."
        case .sequenceEcho: return "Repeat the glowing order, one longer each round."
        case .numberSpan:   return "Read the digits, type them back."
        case .whereWasIt:   return "Remember where each shape was hiding."
        case .quickSums:    return "Solve as many as you can before time runs out."
        case .equationPick: return "Choose the equation that hits the target."
        case .numberSort:   return "Tap the numbers from small to large."
        case .changeMaker:  return "Add the coins to the exact total."
        case .balanceScale: return "Pick the heavier side, or call it even."
        case .colorClash:   return "Tap the ink color, ignore the word."
        case .findTarget:   return "Spot the one shape that breaks the grid."
        case .symbolHunt:   return "Tap every matching mark before the timer."
        case .oddColorOut:  return "Find the tile with a different shade."
        case .gapCount:     return "Count the highlighted cells at a glance."
        case .tapGo:        return "Tap the instant it turns. Measure your spark."
        case .catchGreen:   return "Tap green, never red."
        case .popOrder:     return "Clear the targets the moment they appear."
        case .arrowRush:    return "Swipe the way the arrow points, fast."
        }
    }

    /// How to play, shown on the game intro card.
    var howTo: String {
        switch self {
        case .gridRecall:   return "A set of cells lights up briefly. When the grid clears, tap the cells that were lit. Each correct round adds another cell."
        case .symbolPairs:  return "Cards hide pairs of symbols. Flip two at a time and remember where each one lives until every pair is matched."
        case .sequenceEcho: return "Watch the pads flash in order, then tap them in the same order. Every round adds one more step."
        case .numberSpan:   return "A row of digits appears for a moment. Type them back in order using the keypad."
        case .whereWasIt:   return "Shapes appear on a board, then hide. Tap the tile that held the requested shape."
        case .quickSums:    return "Solve each arithmetic problem and pick the right answer. Keep the streak going before the clock ends."
        case .equationPick: return "A target number sits on top. Tap the one equation below that equals it."
        case .numberSort:   return "Scattered numbers appear. Tap them from smallest to largest without a mistake."
        case .changeMaker:  return "Tap coins until they add up to the exact target. Overshoot resets the pile."
        case .balanceScale: return "Two trays hold weighted tokens. Choose the heavier tray, or tap Even if they match."
        case .colorClash:   return "A color word appears painted in some ink. Tap the button matching the ink color, not the word."
        case .findTarget:   return "Every tile is the same except one. Tap the odd shape as fast as you can spot it."
        case .symbolHunt:   return "A target mark is shown. Tap every tile that matches it in the grid before time runs out."
        case .oddColorOut:  return "All tiles share a shade but one. Tap the tile that is slightly different."
        case .gapCount:     return "A pattern of filled cells flashes. Pick how many were filled."
        case .tapGo:        return "Wait for the panel to turn bright, then tap immediately. Tapping early costs you the round."
        case .catchGreen:   return "Tokens flash by. Tap only when the token is green and let every red one pass."
        case .popOrder:     return "Targets pop onto the board. Tap each one the moment it appears before it fades."
        case .arrowRush:    return "An arrow points a direction. Swipe that way as quickly as you can, round after round."
        }
    }

    var artAsset: String { "game_\(rawValue)" }
}

// MARK: - Results & records

/// Normalized outcome of one game play.
struct GameOutcome {
    let kind: GameKind
    let score: Int        // 0...100 normalized skill score
    let statText: String  // human-readable raw stat, e.g. "8 cells" or "312 ms"
    let xp: Int           // XP awarded
}

struct SessionRecord: Codable, Identifiable {
    var id: UUID = UUID()
    var dateStamp: String        // yyyy-MM-dd
    var timeLabel: String        // HH:mm
    var averageScore: Int
    var gamesPlayed: Int
    var xpEarned: Int
    var domainScores: [String: Int]  // domain.rawValue -> avg score in session
}

struct GameBest: Codable {
    var bestScore: Int = 0
    var bestStat: String = ""
    var plays: Int = 0
}

// MARK: - Skill profile

struct SkillProfile: Codable {
    /// Rolling 0...100 rating per domain (rawValue keyed).
    var ratings: [String: Double] = [:]

    func rating(_ d: BrainDomain) -> Int {
        Int((ratings[d.rawValue] ?? 0).rounded())
    }

    var overall: Int {
        let vals = BrainDomain.allCases.map { ratings[$0.rawValue] ?? 0 }
        guard !vals.isEmpty else { return 0 }
        return Int((vals.reduce(0, +) / Double(vals.count)).rounded())
    }

    /// Blend a new score into the rolling rating (exponential moving average).
    mutating func absorb(domain: BrainDomain, score: Int) {
        let prior = ratings[domain.rawValue] ?? Double(score)
        let blended = prior * 0.72 + Double(score) * 0.28
        ratings[domain.rawValue] = min(100, max(0, blended))
    }
}
