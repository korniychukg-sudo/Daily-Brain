import SwiftUI

final class BrainStore: ObservableObject {
    @Published var profile = SkillProfile()
    @Published var totalXP: Int = 0
    @Published var streak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var history: [SessionRecord] = []
    @Published var bests: [String: GameBest] = [:]

    // Daily plan
    @Published var planDay: String = ""
    @Published var todayPlan: [GameKind] = []
    @Published var completedToday: Set<String> = []
    @Published var todayScores: [String: Int] = [:]

    @Published var soundHint: Bool = true   // stored preference (visual hints)
    @Published var lastCompletedDay: String = ""

    private let key = "dailybrain.state.v1"

    init() {
        load()
        refreshPlanIfNeeded()
    }

    // MARK: - Date helpers

    static let dayFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()
    static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()

    func todayStamp() -> String { BrainStore.dayFmt.string(from: Date()) }

    private func yesterdayStamp() -> String {
        let d = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return BrainStore.dayFmt.string(from: d)
    }

    // MARK: - Daily plan

    func refreshPlanIfNeeded() {
        let today = todayStamp()
        if planDay != today || todayPlan.isEmpty {
            planDay = today
            todayPlan = Self.makePlan(forDay: today)
            completedToday = []
            todayScores = [:]
            save()
        }
    }

    /// Deterministic balanced 5-game plan seeded by the day so it is stable all day.
    static func makePlan(forDay day: String) -> [GameKind] {
        var seed: UInt64 = 1469598103934665603
        for b in day.utf8 { seed = (seed ^ UInt64(b)) &* 1099511628211 }
        var rng = SeededRNG(seed: seed)

        var plan: [GameKind] = []
        // one game from each domain
        for d in BrainDomain.allCases {
            let pool = GameKind.allCases.filter { $0.domain == d }
            plan.append(pool[Int(rng.next() % UInt64(pool.count))])
        }
        // one extra wildcard not already chosen
        let remaining = GameKind.allCases.filter { !plan.contains($0) }
        if let extra = remaining.isEmpty ? nil : remaining[Int(rng.next() % UInt64(remaining.count))] {
            plan.insert(extra, at: Int(rng.next() % UInt64(plan.count + 1)))
        }
        return plan
    }

    var dailyComplete: Bool {
        !todayPlan.isEmpty && completedToday.count >= todayPlan.count
    }

    var dailyProgress: Double {
        guard !todayPlan.isEmpty else { return 0 }
        return Double(completedToday.count) / Double(todayPlan.count)
    }

    // MARK: - Recording outcomes

    func record(_ outcome: GameOutcome, partOfDaily: Bool) {
        // XP
        totalXP += outcome.xp
        // Profile
        profile.absorb(domain: outcome.kind.domain, score: outcome.score)
        // Best
        var best = bests[outcome.kind.rawValue] ?? GameBest()
        best.plays += 1
        if outcome.score > best.bestScore {
            best.bestScore = outcome.score
            best.bestStat = outcome.statText
        }
        bests[outcome.kind.rawValue] = best

        if partOfDaily {
            completedToday.insert(outcome.kind.rawValue)
            todayScores[outcome.kind.rawValue] = outcome.score
            if dailyComplete { finalizeDaily() }
        }
        save()
    }

    private func finalizeDaily() {
        let today = todayStamp()
        guard lastCompletedDay != today else { return }  // already finalized

        // Streak
        if lastCompletedDay == yesterdayStamp() {
            streak += 1
        } else {
            streak = 1
        }
        bestStreak = max(bestStreak, streak)
        lastCompletedDay = today

        // Session record
        let scores = todayPlan.compactMap { todayScores[$0.rawValue] }
        let avg = scores.isEmpty ? 0 : Int(Double(scores.reduce(0, +)) / Double(scores.count))
        var domainAgg: [String: [Int]] = [:]
        for g in todayPlan {
            if let s = todayScores[g.rawValue] {
                domainAgg[g.domain.rawValue, default: []].append(s)
            }
        }
        var domainScores: [String: Int] = [:]
        for (k, v) in domainAgg {
            domainScores[k] = v.isEmpty ? 0 : Int(Double(v.reduce(0, +)) / Double(v.count))
        }
        // Games' XP was already added when each game finished; recompute it for the record.
        let xpSum = todayScores.values.reduce(0) { $0 + 12 + $1 * 55 / 100 }
        let bonus = 40 + streak * 5
        totalXP += bonus

        let rec = SessionRecord(
            dateStamp: today,
            timeLabel: BrainStore.timeFmt.string(from: Date()),
            averageScore: avg,
            gamesPlayed: scores.count,
            xpEarned: xpSum + bonus,
            domainScores: domainScores
        )
        history.insert(rec, at: 0)
        if history.count > 60 { history = Array(history.prefix(60)) }
    }

    func best(for kind: GameKind) -> GameBest { bests[kind.rawValue] ?? GameBest() }

    var level: Int { BrainTheme.level(forXP: totalXP) }

    // MARK: - Persistence

    private struct Persisted: Codable {
        var profile: SkillProfile
        var totalXP: Int
        var streak: Int
        var bestStreak: Int
        var history: [SessionRecord]
        var bests: [String: GameBest]
        var planDay: String
        var todayPlan: [GameKind]
        var completedToday: [String]
        var todayScores: [String: Int]
        var lastCompletedDay: String
        var soundHint: Bool
    }

    private func save() {
        let p = Persisted(profile: profile, totalXP: totalXP, streak: streak, bestStreak: bestStreak,
                          history: history, bests: bests, planDay: planDay, todayPlan: todayPlan,
                          completedToday: Array(completedToday), todayScores: todayScores,
                          lastCompletedDay: lastCompletedDay, soundHint: soundHint)
        if let data = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let p = try? JSONDecoder().decode(Persisted.self, from: data) else { return }
        profile = p.profile
        totalXP = p.totalXP
        streak = p.streak
        bestStreak = p.bestStreak
        history = p.history
        bests = p.bests
        planDay = p.planDay
        todayPlan = p.todayPlan
        completedToday = Set(p.completedToday)
        todayScores = p.todayScores
        lastCompletedDay = p.lastCompletedDay
        soundHint = p.soundHint
    }

    func persist() { save() }

    func resetAll() {
        profile = SkillProfile(); totalXP = 0; streak = 0; bestStreak = 0
        history = []; bests = [:]; completedToday = []; todayScores = [:]
        lastCompletedDay = ""; planDay = ""
        refreshPlanIfNeeded()
        save()
    }
}

/// Small deterministic RNG (SplitMix64) for stable daily plans.
struct SeededRNG {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
