import SwiftUI

enum BrainGlyph {
    case brain
    case memory
    case numbers
    case focus
    case reflex
    case star
    case flame
    case trophy
    case chevronRight
    case chevronLeft
    case lock
    case check
    case close
    case play
    case home
    case grid
    case radar
    case menu
    case clock
    case spark
    case refresh

    static func forDomain(_ d: BrainDomain) -> BrainGlyph {
        switch d {
        case .memory:  return .memory
        case .numbers: return .numbers
        case .focus:   return .focus
        case .reflex:  return .reflex
        }
    }
}

/// Custom vector icon rendered with Canvas. No SF Symbols, no emoji.
struct BrainIcon: View {
    let glyph: BrainGlyph
    var size: CGFloat = 24
    var color: Color = BrainTheme.ink
    var weight: CGFloat = 2.0

    var body: some View {
        Canvas { ctx, sz in
            let w = sz.width, h = sz.height
            let s = min(w, h)
            let ox = (w - s) / 2, oy = (h - s) / 2
            func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: ox + x * s, y: oy + y * s) }
            let line = StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)

            switch glyph {
            case .brain:
                var path = Path()
                // left lobe
                path.addRoundedRect(in: CGRect(x: ox + 0.16*s, y: oy + 0.20*s, width: 0.34*s, height: 0.60*s),
                                    cornerSize: CGSize(width: 0.17*s, height: 0.22*s))
                path.addRoundedRect(in: CGRect(x: ox + 0.50*s, y: oy + 0.20*s, width: 0.34*s, height: 0.60*s),
                                    cornerSize: CGSize(width: 0.17*s, height: 0.22*s))
                ctx.stroke(path, with: .color(color), style: line)
                var mid = Path(); mid.move(to: p(0.5, 0.22)); mid.addLine(to: p(0.5, 0.78))
                ctx.stroke(mid, with: .color(color.opacity(0.7)), style: line)

            case .memory:
                for (i, dy) in [0.28, 0.5, 0.72].enumerated() {
                    var row = Path()
                    let inset = 0.18 + CGFloat(i) * 0.0
                    row.move(to: p(inset, dy)); row.addLine(to: p(1 - inset, dy))
                    ctx.stroke(row, with: .color(color.opacity(i == 1 ? 1 : 0.55)), style: line)
                }
                for dx in [0.28, 0.5, 0.72] {
                    var dot = Path()
                    dot.addEllipse(in: CGRect(x: ox + dx*s - 0.03*s, y: oy + 0.28*s - 0.03*s, width: 0.06*s, height: 0.06*s))
                    ctx.fill(dot, with: .color(color))
                }

            case .numbers:
                var hash = Path()
                hash.move(to: p(0.36, 0.18)); hash.addLine(to: p(0.28, 0.82))
                hash.move(to: p(0.68, 0.18)); hash.addLine(to: p(0.60, 0.82))
                hash.move(to: p(0.18, 0.40)); hash.addLine(to: p(0.82, 0.40))
                hash.move(to: p(0.16, 0.62)); hash.addLine(to: p(0.80, 0.62))
                ctx.stroke(hash, with: .color(color), style: line)

            case .focus:
                for r in [0.40, 0.26, 0.12] {
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: ox + (0.5 - r)*s, y: oy + (0.5 - r)*s, width: 2*r*s, height: 2*r*s))
                    ctx.stroke(ring, with: .color(color.opacity(r == 0.12 ? 1 : 0.7)), style: line)
                }
                var dot = Path(); dot.addEllipse(in: CGRect(x: ox + 0.46*s, y: oy + 0.46*s, width: 0.08*s, height: 0.08*s))
                ctx.fill(dot, with: .color(color))

            case .reflex:
                var bolt = Path()
                bolt.move(to: p(0.56, 0.12))
                bolt.addLine(to: p(0.30, 0.54))
                bolt.addLine(to: p(0.48, 0.54))
                bolt.addLine(to: p(0.42, 0.88))
                bolt.addLine(to: p(0.70, 0.44))
                bolt.addLine(to: p(0.52, 0.44))
                bolt.closeSubpath()
                ctx.fill(bolt, with: .color(color))

            case .star:
                ctx.fill(starPath(center: CGPoint(x: ox + 0.5*s, y: oy + 0.52*s), outer: 0.42*s, inner: 0.18*s, points: 5), with: .color(color))

            case .flame:
                var flame = Path()
                flame.move(to: p(0.5, 0.10))
                flame.addQuadCurve(to: p(0.80, 0.56), control: p(0.86, 0.28))
                flame.addQuadCurve(to: p(0.5, 0.90), control: p(0.80, 0.86))
                flame.addQuadCurve(to: p(0.20, 0.56), control: p(0.20, 0.86))
                flame.addQuadCurve(to: p(0.5, 0.10), control: p(0.14, 0.28))
                ctx.fill(flame, with: .color(color))
                var inner = Path()
                inner.move(to: p(0.5, 0.40))
                inner.addQuadCurve(to: p(0.62, 0.68), control: p(0.66, 0.52))
                inner.addQuadCurve(to: p(0.5, 0.82), control: p(0.62, 0.80))
                inner.addQuadCurve(to: p(0.38, 0.68), control: p(0.38, 0.80))
                inner.addQuadCurve(to: p(0.5, 0.40), control: p(0.34, 0.52))
                ctx.fill(inner, with: .color(.white.opacity(0.55)))

            case .trophy:
                var cup = Path()
                cup.move(to: p(0.30, 0.20)); cup.addLine(to: p(0.70, 0.20))
                cup.addLine(to: p(0.66, 0.46))
                cup.addQuadCurve(to: p(0.50, 0.58), control: p(0.58, 0.58))
                cup.addQuadCurve(to: p(0.34, 0.46), control: p(0.42, 0.58))
                cup.closeSubpath()
                ctx.fill(cup, with: .color(color))
                var handleL = Path(); handleL.move(to: p(0.30, 0.24)); handleL.addQuadCurve(to: p(0.30, 0.42), control: p(0.14, 0.33))
                var handleR = Path(); handleR.move(to: p(0.70, 0.24)); handleR.addQuadCurve(to: p(0.70, 0.42), control: p(0.86, 0.33))
                ctx.stroke(handleL, with: .color(color), style: line)
                ctx.stroke(handleR, with: .color(color), style: line)
                var stem = Path(); stem.move(to: p(0.5, 0.58)); stem.addLine(to: p(0.5, 0.72))
                ctx.stroke(stem, with: .color(color), style: line)
                var base = Path(); base.move(to: p(0.34, 0.80)); base.addLine(to: p(0.66, 0.80))
                ctx.stroke(base, with: .color(color), style: StrokeStyle(lineWidth: weight * 1.4, lineCap: .round))

            case .chevronRight:
                var c = Path(); c.move(to: p(0.40, 0.24)); c.addLine(to: p(0.64, 0.5)); c.addLine(to: p(0.40, 0.76))
                ctx.stroke(c, with: .color(color), style: line)

            case .chevronLeft:
                var c = Path(); c.move(to: p(0.60, 0.24)); c.addLine(to: p(0.36, 0.5)); c.addLine(to: p(0.60, 0.76))
                ctx.stroke(c, with: .color(color), style: line)

            case .lock:
                var body = Path()
                body.addRoundedRect(in: CGRect(x: ox + 0.28*s, y: oy + 0.44*s, width: 0.44*s, height: 0.36*s),
                                    cornerSize: CGSize(width: 0.06*s, height: 0.06*s))
                ctx.fill(body, with: .color(color))
                var shackle = Path()
                shackle.addArc(center: p(0.5, 0.44), radius: 0.14*s, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                ctx.stroke(shackle, with: .color(color), style: StrokeStyle(lineWidth: weight * 1.2, lineCap: .round))

            case .check:
                var c = Path(); c.move(to: p(0.24, 0.52)); c.addLine(to: p(0.44, 0.72)); c.addLine(to: p(0.78, 0.30))
                ctx.stroke(c, with: .color(color), style: StrokeStyle(lineWidth: weight * 1.2, lineCap: .round, lineJoin: .round))

            case .close:
                var c = Path()
                c.move(to: p(0.30, 0.30)); c.addLine(to: p(0.70, 0.70))
                c.move(to: p(0.70, 0.30)); c.addLine(to: p(0.30, 0.70))
                ctx.stroke(c, with: .color(color), style: StrokeStyle(lineWidth: weight * 1.1, lineCap: .round))

            case .play:
                var t = Path(); t.move(to: p(0.34, 0.24)); t.addLine(to: p(0.74, 0.5)); t.addLine(to: p(0.34, 0.76)); t.closeSubpath()
                ctx.fill(t, with: .color(color))

            case .home:
                var roof = Path(); roof.move(to: p(0.18, 0.5)); roof.addLine(to: p(0.5, 0.20)); roof.addLine(to: p(0.82, 0.5))
                ctx.stroke(roof, with: .color(color), style: line)
                var walls = Path()
                walls.addRoundedRect(in: CGRect(x: ox + 0.28*s, y: oy + 0.46*s, width: 0.44*s, height: 0.34*s),
                                     cornerSize: CGSize(width: 0.04*s, height: 0.04*s))
                ctx.stroke(walls, with: .color(color), style: line)

            case .grid:
                for gx in [0.30, 0.55] {
                    for gy in [0.30, 0.55] {
                        var r = Path()
                        r.addRoundedRect(in: CGRect(x: ox + gx*s, y: oy + gy*s, width: 0.16*s, height: 0.16*s),
                                         cornerSize: CGSize(width: 0.03*s, height: 0.03*s))
                        ctx.stroke(r, with: .color(color), style: line)
                    }
                }

            case .radar:
                for r in [0.40, 0.24] {
                    var ring = Path()
                    ring.addEllipse(in: CGRect(x: ox + (0.5 - r)*s, y: oy + (0.5 - r)*s, width: 2*r*s, height: 2*r*s))
                    ctx.stroke(ring, with: .color(color.opacity(0.6)), style: line)
                }
                var sweep = Path(); sweep.move(to: p(0.5, 0.5)); sweep.addLine(to: p(0.82, 0.34))
                ctx.stroke(sweep, with: .color(color), style: line)
                var dot = Path(); dot.addEllipse(in: CGRect(x: ox + 0.47*s, y: oy + 0.47*s, width: 0.06*s, height: 0.06*s))
                ctx.fill(dot, with: .color(color))

            case .menu:
                for dy in [0.34, 0.5, 0.66] {
                    var l = Path(); l.move(to: p(0.24, dy)); l.addLine(to: p(0.76, dy))
                    ctx.stroke(l, with: .color(color), style: line)
                }

            case .clock:
                var ring = Path(); ring.addEllipse(in: CGRect(x: ox + 0.16*s, y: oy + 0.16*s, width: 0.68*s, height: 0.68*s))
                ctx.stroke(ring, with: .color(color), style: line)
                var hands = Path(); hands.move(to: p(0.5, 0.5)); hands.addLine(to: p(0.5, 0.30)); hands.move(to: p(0.5, 0.5)); hands.addLine(to: p(0.66, 0.56))
                ctx.stroke(hands, with: .color(color), style: line)

            case .spark:
                var v = Path(); v.move(to: p(0.5, 0.14)); v.addLine(to: p(0.5, 0.86))
                var hh = Path(); hh.move(to: p(0.14, 0.5)); hh.addLine(to: p(0.86, 0.5))
                var d1 = Path(); d1.move(to: p(0.26, 0.26)); d1.addLine(to: p(0.74, 0.74))
                var d2 = Path(); d2.move(to: p(0.74, 0.26)); d2.addLine(to: p(0.26, 0.74))
                ctx.stroke(v, with: .color(color), style: line)
                ctx.stroke(hh, with: .color(color), style: line)
                ctx.stroke(d1, with: .color(color.opacity(0.6)), style: line)
                ctx.stroke(d2, with: .color(color.opacity(0.6)), style: line)

            case .refresh:
                var arc = Path()
                arc.addArc(center: p(0.5, 0.5), radius: 0.30*s, startAngle: .degrees(60), endAngle: .degrees(340), clockwise: false)
                ctx.stroke(arc, with: .color(color), style: line)
                var head = Path()
                head.move(to: p(0.74, 0.30)); head.addLine(to: p(0.80, 0.16)); head.move(to: p(0.80, 0.16)); head.addLine(to: p(0.90, 0.30))
                ctx.stroke(head, with: .color(color), style: line)
            }
        }
        .frame(width: size, height: size)
    }

    private func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat, points: Int) -> Path {
        var path = Path()
        let step = CGFloat.pi / CGFloat(points)
        var angle = -CGFloat.pi / 2
        for i in 0..<(points * 2) {
            let r = (i % 2 == 0) ? outer : inner
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            angle += step
        }
        path.closeSubpath()
        return path
    }
}
