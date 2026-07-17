import SwiftUI

struct SkillRadar: View {
    var values: [BrainDomain: Int]   // 0...100
    var size: CGFloat = 220

    var body: some View {
        Canvas { ctx, sz in
            let c = CGPoint(x: sz.width/2, y: sz.height/2)
            let radius = min(sz.width, sz.height)/2 - 26
            let domains = BrainDomain.allCases
            let n = domains.count
            func point(_ i: Int, _ frac: Double) -> CGPoint {
                let angle = -Double.pi/2 + Double(i) * (2 * Double.pi / Double(n))
                return CGPoint(x: c.x + CGFloat(cos(angle) * frac) * radius,
                               y: c.y + CGFloat(sin(angle) * frac) * radius)
            }
            // grid rings
            for ring in [0.25, 0.5, 0.75, 1.0] {
                var p = Path()
                for i in 0..<n {
                    let pt = point(i, ring)
                    if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                p.closeSubpath()
                ctx.stroke(p, with: .color(BrainTheme.line), lineWidth: 1)
            }
            // spokes
            for i in 0..<n {
                var s = Path(); s.move(to: c); s.addLine(to: point(i, 1.0))
                ctx.stroke(s, with: .color(BrainTheme.line), lineWidth: 1)
            }
            // value polygon
            var poly = Path()
            for i in 0..<n {
                let v = Double(values[domains[i]] ?? 0) / 100.0
                let pt = point(i, max(0.04, v))
                if i == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
            }
            poly.closeSubpath()
            ctx.fill(poly, with: .color(BrainTheme.primary.opacity(0.22)))
            ctx.stroke(poly, with: .color(BrainTheme.primary), lineWidth: 2.5)
            // vertex dots + labels
            for i in 0..<n {
                let v = Double(values[domains[i]] ?? 0) / 100.0
                let pt = point(i, max(0.04, v))
                var dot = Path(); dot.addEllipse(in: CGRect(x: pt.x-4, y: pt.y-4, width: 8, height: 8))
                ctx.fill(dot, with: .color(domains[i].color))
                let labelPt = point(i, 1.24)
                let text = Text(domains[i].title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(domains[i].color)
                ctx.draw(text, at: labelPt, anchor: .center)
            }
        }
        .frame(width: size, height: size)
    }
}

struct ProfileView: View {
    @EnvironmentObject var store: BrainStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                radarCard
                domainBars
                weeklyCard
                awardsSection
                lifetimeCard
                if !store.history.isEmpty { historySection }
                bestsSection
            }
            .padding(16)
            .padding(.bottom, 10)
        }
        .background(LuxeScreenBackground(tint: BrainTheme.primary))
        .navigationBarHidden(true)
    }

    // MARK: Weekly activity

    private var weeklyCard: some View {
        let days = store.weeklyActivity()
        let maxCount = max(1, days.map { $0.count }.max() ?? 1)
        return VStack(alignment: .leading, spacing: 14) {
            Text("This Week")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(days.indices, id: \.self) { i in
                    let day = days[i]
                    VStack(spacing: 6) {
                        Text(day.count > 0 ? "\(day.count)" : "")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(BrainTheme.gold)
                        ZStack(alignment: .bottom) {
                            Capsule().fill(BrainTheme.card).frame(height: 74)
                                .overlay(Capsule().strokeBorder(BrainTheme.cardStroke, lineWidth: 1))
                            if day.count > 0 {
                                Capsule().fill(
                                    LinearGradient(colors: [BrainTheme.gold, BrainTheme.primary],
                                                   startPoint: .top, endPoint: .bottom))
                                    .frame(height: max(12, 74 * CGFloat(day.count) / CGFloat(maxCount)))
                                    .luxeGlow(BrainTheme.gold, radius: 6, opacity: 0.35)
                            }
                        }
                        .frame(height: 74)
                        Text(day.label)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(i == days.count - 1 ? BrainTheme.gold : BrainTheme.subtle)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .brainCard()
    }

    // MARK: Awards strip

    private var awardsSection: some View {
        let unlockedCount = AwardCatalog.all.filter { store.unlockedAwards.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Awards")
                    .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                Spacer()
                NavigationLink {
                    AwardsView().environmentObject(store)
                } label: {
                    HStack(spacing: 4) {
                        Text("\(unlockedCount)/\(AwardCatalog.all.count) · See all")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(BrainTheme.gold)
                        BrainIcon(glyph: .chevronRight, size: 15, color: BrainTheme.gold, weight: 2)
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    let sorted = AwardCatalog.all.sorted {
                        (store.unlockedAwards.contains($0.id) ? 0 : 1) < (store.unlockedAwards.contains($1.id) ? 0 : 1)
                    }
                    ForEach(sorted.prefix(8)) { award in
                        AwardBadgeView(award: award,
                                       unlocked: store.unlockedAwards.contains(award.id),
                                       size: 66)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .brainCard()
    }

    // MARK: Lifetime stats

    private var lifetimeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("All Time")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            HStack(spacing: 12) {
                lifetimeTile(value: "\(store.lifetimeGames)", label: "Games", color: BrainTheme.primary)
                lifetimeTile(value: "\(store.lifetimeThreeStars)", label: "3-star runs", color: BrainTheme.gold)
            }
            HStack(spacing: 12) {
                lifetimeTile(value: "\(store.history.count)", label: "Sets done", color: BrainDomain.numbers.color)
                lifetimeTile(value: "\(store.bestStreak)", label: "Best streak", color: BrainDomain.reflex.color)
            }
        }
        .brainCard()
    }

    private func lifetimeTile(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(BrainTheme.subtle)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(color.opacity(0.10))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.30), lineWidth: 1)))
    }

    private var header: some View {
        let lp = BrainTheme.levelProgress(forXP: store.totalXP)
        return VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Skill Profile")
                        .font(.system(size: 26, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    Text("Level \(lp.level) · \(store.profile.overall) brain score")
                        .font(.system(size: 14, weight: .medium, design: .rounded)).foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                ZStack {
                    Circle().fill(Color.white.opacity(0.18)).frame(width: 56, height: 56)
                    BrainIcon(glyph: .brain, size: 30, color: .white, weight: 2.4)
                }
            }
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.25))
                        Capsule().fill(Color.white)
                            .frame(width: geo.size.width * CGFloat(lp.span == 0 ? 0 : Double(lp.into)/Double(lp.span)))
                    }
                }
                .frame(height: 8)
                HStack {
                    Text("\(lp.into) / \(lp.span) XP to next level")
                        .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.85))
                    Spacer()
                    HStack(spacing: 4) {
                        BrainIcon(glyph: .flame, size: 14, color: BrainTheme.gold, weight: 2)
                        Text("\(store.streak) day streak")
                            .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(BrainTheme.heroGradient))
    }

    private var radarCard: some View {
        var vals: [BrainDomain: Int] = [:]
        for d in BrainDomain.allCases { vals[d] = store.profile.rating(d) }
        return VStack(spacing: 6) {
            Text("Cognitive Balance")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            SkillRadar(values: vals, size: 230)
                .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity)
        .brainCard()
    }

    private var domainBars: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Skill Ratings")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            ForEach(BrainDomain.allCases) { d in
                let rating = store.profile.rating(d)
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        BrainIcon(glyph: BrainGlyph.forDomain(d), size: 16, color: d.color, weight: 2)
                        Text(d.title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.ink)
                        Spacer()
                        Text("\(rating)").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(d.color)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(d.colorSoft)
                            Capsule().fill(d.color).frame(width: geo.size.width * CGFloat(rating)/100)
                        }
                    }
                    .frame(height: 8)
                }
            }
        }
        .brainCard()
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Sessions")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            ForEach(store.history.prefix(8)) { rec in
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(BrainTheme.primarySoft).frame(width: 44, height: 44)
                        Text("\(rec.averageScore)")
                            .font(.system(size: 16, weight: .heavy, design: .rounded)).foregroundColor(BrainTheme.primary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(prettyDate(rec.dateStamp))
                            .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
                        Text("\(rec.gamesPlayed) games · +\(rec.xpEarned) XP · \(rec.timeLabel)")
                            .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
                    }
                    Spacer()
                }
            }
        }
        .brainCard()
    }

    private var bestsSection: some View {
        let played = GameKind.allCases.filter { store.best(for: $0).plays > 0 }
        return VStack(alignment: .leading, spacing: 12) {
            Text("Personal Bests")
                .font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(BrainTheme.ink)
            if played.isEmpty {
                Text("Play a few games and your records will appear here.")
                    .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
            } else {
                ForEach(played) { kind in
                    let b = store.best(for: kind)
                    HStack(spacing: 12) {
                        Circle().fill(kind.domain.color).frame(width: 10, height: 10)
                        Text(kind.title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(BrainTheme.ink)
                        Spacer()
                        Text(b.bestStat.isEmpty ? "—" : b.bestStat)
                            .font(.system(size: 13, weight: .medium, design: .rounded)).foregroundColor(BrainTheme.subtle)
                        Text("\(b.bestScore)")
                            .font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(kind.domain.color)
                            .frame(width: 34, alignment: .trailing)
                    }
                }
            }
        }
        .brainCard()
    }

    private func prettyDate(_ stamp: String) -> String {
        let inFmt = DateFormatter(); inFmt.dateFormat = "yyyy-MM-dd"; inFmt.locale = Locale(identifier: "en_US_POSIX")
        let outFmt = DateFormatter(); outFmt.dateFormat = "MMM d"; outFmt.locale = Locale(identifier: "en_US_POSIX")
        if let d = inFmt.date(from: stamp) { return outFmt.string(from: d) }
        return stamp
    }
}
