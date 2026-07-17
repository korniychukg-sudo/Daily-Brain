import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// argv[1] = artDir, argv[2] = iconPath
let artDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./Art"
let iconPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "./AppIcon-1024.png"

let space = CGColorSpace(name: CGColorSpace.sRGB)!

func makeContext(_ w: Int, _ h: Int) -> CGContext {
    CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
              bytesPerRow: 0, space: space,
              bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
}

func write(_ ctx: CGContext, to path: String) {
    guard let img = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: path)
    guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}

struct RGB { var r: CGFloat; var g: CGFloat; var b: CGFloat
    func cg(_ a: CGFloat = 1) -> CGColor { CGColor(colorSpace: space, components: [r, g, b, a])! }
    func mix(_ o: RGB, _ t: CGFloat) -> RGB { RGB(r: r+(o.r-r)*t, g: g+(o.g-g)*t, b: b+(o.b-b)*t) }
    func darker(_ t: CGFloat) -> RGB { mix(RGB(r:0,g:0,b:0), t) }
    func lighter(_ t: CGFloat) -> RGB { mix(RGB(r:1,g:1,b:1), t) }
}

let midnight = RGB(r: 0.051, g: 0.055, b: 0.114)
let deep     = RGB(r: 0.031, g: 0.033, b: 0.075)
let violet   = RGB(r: 0.580, g: 0.502, b: 1.0)
let vDark    = RGB(r: 0.337, g: 0.255, b: 0.796)
let teal     = RGB(r: 0.196, g: 0.812, b: 0.722)
let orange   = RGB(r: 1.0,   g: 0.596, b: 0.267)
let rose     = RGB(r: 1.0,   g: 0.427, b: 0.588)
let gold     = RGB(r: 0.984, g: 0.760, b: 0.310)
let white    = RGB(r: 1, g: 1, b: 1)

func domainColor(_ d: String) -> RGB {
    switch d { case "memory": return violet; case "numbers": return teal
    case "focus": return orange; default: return rose }
}

// MARK: - RNG (deterministic)

struct Rand {
    var s: UInt64
    init(_ seedStr: String) {
        var h: UInt64 = 1469598103934665603
        for b in seedStr.utf8 { h = (h ^ UInt64(b)) &* 1099511628211 }
        s = h
    }
    mutating func next() -> UInt64 { s = s &* 6364136223846793005 &+ 1442695040888963407; return s }
    mutating func f() -> CGFloat { CGFloat((next() >> 11) % 100000) / 100000.0 }
    mutating func range(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { lo + f() * (hi - lo) }
    mutating func int(_ n: Int) -> Int { Int(next() % UInt64(max(1, n))) }
}

// MARK: - Noise (drives PNG entropy => file size, and adds texture)

var noiseState: UInt64 = 0x9E3779B97F4A7C15
@inline(__always) func nrand() -> UInt64 {
    noiseState ^= noiseState << 13; noiseState ^= noiseState >> 7; noiseState ^= noiseState << 17
    return noiseState
}

/// Adds +-amp per-pixel grain directly to the bitmap.
func addNoise(_ ctx: CGContext, amp: Int) {
    guard amp > 0, let data = ctx.data else { return }
    let w = ctx.width, h = ctx.height, bpr = ctx.bytesPerRow
    let buf = data.bindMemory(to: UInt8.self, capacity: bpr * h)
    let span = UInt64(2 * amp + 1)
    for y in 0..<h {
        var idx = y * bpr
        for _ in 0..<w {
            let r = nrand()
            let d0 = Int(r % span) - amp
            let d1 = Int((r >> 16) % span) - amp
            let d2 = Int((r >> 32) % span) - amp
            buf[idx]   = UInt8(clamping: Int(buf[idx]) + d0)
            buf[idx+1] = UInt8(clamping: Int(buf[idx+1]) + d1)
            buf[idx+2] = UInt8(clamping: Int(buf[idx+2]) + d2)
            idx += 4
        }
    }
}

// MARK: - Paint helpers

func fillRadial(_ ctx: CGContext, rect: CGRect, inner: CGColor, outer: CGColor,
                center: CGPoint? = nil, radiusScale: CGFloat = 0.75) {
    let grad = CGGradient(colorsSpace: space, colors: [inner, outer] as CFArray, locations: [0, 1])!
    let c = center ?? CGPoint(x: rect.midX, y: rect.midY)
    ctx.saveGState(); ctx.addRect(rect); ctx.clip()
    ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c,
                           endRadius: max(rect.width, rect.height) * radiusScale,
                           options: [.drawsAfterEndLocation])
    ctx.restoreGState()
}

func fillLinear(_ ctx: CGContext, rect: CGRect, from: CGColor, to: CGColor, horizontal: Bool = false) {
    let grad = CGGradient(colorsSpace: space, colors: [from, to] as CFArray, locations: [0,1])!
    ctx.saveGState(); ctx.addRect(rect); ctx.clip()
    let s = CGPoint(x: rect.minX, y: rect.minY)
    let e = horizontal ? CGPoint(x: rect.maxX, y: rect.minY) : CGPoint(x: rect.minX, y: rect.maxY)
    ctx.drawLinearGradient(grad, start: s, end: e, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
    ctx.restoreGState()
}

/// Soft glow blob: radial gradient from tinted color to transparent.
func blob(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: RGB, _ alpha: CGFloat) {
    let grad = CGGradient(colorsSpace: space,
                          colors: [color.cg(alpha), color.cg(0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: r, options: [])
}

func circle(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: CGColor) {
    ctx.setFillColor(color); ctx.fillEllipse(in: CGRect(x: c.x-r, y: c.y-r, width: 2*r, height: 2*r))
}
func ring(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: CGColor, _ w: CGFloat) {
    ctx.setStrokeColor(color); ctx.setLineWidth(w)
    ctx.strokeEllipse(in: CGRect(x: c.x-r, y: c.y-r, width: 2*r, height: 2*r))
}

func starPath(_ c: CGPoint, outer: CGFloat, inner: CGFloat, points: Int) -> CGPath {
    let p = CGMutablePath(); let step = CGFloat.pi / CGFloat(points); var a = -CGFloat.pi/2
    for i in 0..<(points*2) {
        let r = (i % 2 == 0) ? outer : inner
        let pt = CGPoint(x: c.x + cos(a)*r, y: c.y + sin(a)*r)
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        a += step
    }
    p.closeSubpath(); return p
}

func sparkle(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, _ color: CGColor) {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: c.x, y: c.y - r))
    p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
    p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
    ctx.setFillColor(color); ctx.addPath(p); ctx.fillPath()
}

func gem(_ ctx: CGContext, center: CGPoint, radius r: CGFloat, top: RGB, bottom: RGB, facet: RGB) {
    let topY = center.y - r, botY = center.y + r
    let midY = center.y - r*0.15
    let hw = r*0.86
    let p = CGMutablePath()
    p.move(to: CGPoint(x: center.x, y: topY))
    p.addLine(to: CGPoint(x: center.x + hw, y: midY))
    p.addLine(to: CGPoint(x: center.x + hw*0.5, y: botY))
    p.addLine(to: CGPoint(x: center.x - hw*0.5, y: botY))
    p.addLine(to: CGPoint(x: center.x - hw, y: midY))
    p.closeSubpath()
    ctx.saveGState(); ctx.addPath(p); ctx.clip()
    fillLinear(ctx, rect: CGRect(x: center.x-hw, y: topY, width: hw*2, height: r*2),
               from: top.cg(), to: bottom.cg())
    ctx.restoreGState()
    ctx.setStrokeColor(facet.cg(0.5)); ctx.setLineWidth(r*0.028)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: center.x - hw, y: midY)); ctx.addLine(to: CGPoint(x: center.x + hw, y: midY))
    ctx.move(to: CGPoint(x: center.x, y: topY)); ctx.addLine(to: CGPoint(x: center.x, y: botY))
    ctx.move(to: CGPoint(x: center.x, y: topY)); ctx.addLine(to: CGPoint(x: center.x - hw, y: midY))
    ctx.move(to: CGPoint(x: center.x, y: topY)); ctx.addLine(to: CGPoint(x: center.x + hw, y: midY))
    ctx.strokePath()
}

/// Faint diagonal pinstripes for texture.
func pinstripes(_ ctx: CGContext, rect: CGRect, color: CGColor, gap: CGFloat, width: CGFloat) {
    ctx.saveGState(); ctx.addRect(rect); ctx.clip()
    ctx.setStrokeColor(color); ctx.setLineWidth(width)
    var x = rect.minX - rect.height
    while x < rect.maxX + rect.height {
        ctx.beginPath()
        ctx.move(to: CGPoint(x: x, y: rect.maxY))
        ctx.addLine(to: CGPoint(x: x + rect.height, y: rect.minY))
        ctx.strokePath()
        x += gap
    }
    ctx.restoreGState()
}

/// Dotted halo of orbiting accent dots.
func orbitDots(_ ctx: CGContext, _ c: CGPoint, _ r: CGFloat, count: Int, colors: [RGB], rnd: inout Rand) {
    for i in 0..<count {
        let a = CGFloat(i) / CGFloat(count) * 2 * .pi + rnd.range(-0.2, 0.2)
        let rr = r * rnd.range(0.92, 1.12)
        let pt = CGPoint(x: c.x + cos(a)*rr, y: c.y + sin(a)*rr)
        circle(ctx, pt, rnd.range(3, 9), colors[i % colors.count].cg(rnd.range(0.35, 0.85)))
    }
}

// MARK: - Emblem motifs (cycled per game, tinted per domain)

func drawMotif(_ ctx: CGContext, kind: Int, c: CGPoint, s: CGFloat, base: RGB, rnd: inout Rand) {
    switch kind % 8 {
    case 0: // faceted gem
        blob(ctx, c, s*1.5, white, 0.10)
        gem(ctx, center: c, radius: s, top: white.mix(base, 0.15), bottom: base.lighter(0.30), facet: deep)
    case 1: // concentric target rings
        ring(ctx, c, s*1.25, white.cg(0.16), s*0.13)
        ring(ctx, c, s*0.85, white.cg(0.30), s*0.11)
        circle(ctx, c, s*0.40, white.cg(0.95))
        circle(ctx, c, s*0.16, base.darker(0.2).cg())
    case 2: // gold coin
        circle(ctx, c, s*1.08, gold.darker(0.25).cg())
        circle(ctx, c, s*0.98, gold.lighter(0.08).cg())
        ring(ctx, c, s*0.72, gold.darker(0.30).cg(0.8), s*0.07)
        ctx.setFillColor(gold.darker(0.35).cg())
        ctx.addPath(starPath(c, outer: s*0.42, inner: s*0.19, points: 5)); ctx.fillPath()
    case 3: // chevron stack
        ctx.setLineCap(.round); ctx.setLineJoin(.round)
        for i in 0..<3 {
            let off = CGFloat(i - 1) * s * 0.55
            ctx.setStrokeColor(white.cg(i == 1 ? 0.95 : 0.55))
            ctx.setLineWidth(s * 0.20)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: c.x - s*0.75, y: c.y - s*0.42 + off))
            ctx.addLine(to: CGPoint(x: c.x, y: c.y + s*0.20 + off))
            ctx.addLine(to: CGPoint(x: c.x + s*0.75, y: c.y - s*0.42 + off))
            ctx.strokePath()
        }
    case 4: // orb cluster
        blob(ctx, c, s*1.6, white, 0.10)
        circle(ctx, CGPoint(x: c.x - s*0.32, y: c.y - s*0.15), s*0.58, white.cg(0.92))
        circle(ctx, CGPoint(x: c.x + s*0.46, y: c.y + s*0.26), s*0.40, gold.cg())
        circle(ctx, CGPoint(x: c.x + s*0.24, y: c.y - s*0.50), s*0.25, base.lighter(0.42).cg())
    case 5: // star token
        blob(ctx, c, s*1.5, gold, 0.16)
        ctx.setFillColor(gold.lighter(0.05).cg())
        ctx.addPath(starPath(c, outer: s*0.98, inner: s*0.43, points: 5)); ctx.fillPath()
        ctx.setStrokeColor(white.cg(0.5)); ctx.setLineWidth(s*0.05)
        ctx.addPath(starPath(c, outer: s*0.98, inner: s*0.43, points: 5)); ctx.strokePath()
    case 6: // hex nut / prism
        let p = CGMutablePath()
        for i in 0..<6 {
            let a = CGFloat(i) / 6 * 2 * .pi - .pi/2
            let pt = CGPoint(x: c.x + cos(a)*s, y: c.y + sin(a)*s)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        ctx.saveGState(); ctx.addPath(p); ctx.clip()
        fillLinear(ctx, rect: CGRect(x: c.x-s, y: c.y-s, width: 2*s, height: 2*s),
                   from: white.mix(base, 0.10).cg(), to: base.lighter(0.25).cg())
        ctx.restoreGState()
        ring(ctx, c, s*0.45, deep.cg(0.55), s*0.09)
    default: // crescent + dot
        circle(ctx, c, s, white.cg(0.92))
        circle(ctx, CGPoint(x: c.x + s*0.38, y: c.y - s*0.18), s*0.86, base.lighter(0.10).cg())
        circle(ctx, CGPoint(x: c.x + s*0.55, y: c.y + s*0.45), s*0.16, gold.cg())
    }
}

// MARK: - Game tiles

let gamesByDomain: [(String, [String])] = [
    ("memory",  ["gridRecall","symbolPairs","sequenceEcho","numberSpan","whereWasIt"]),
    ("numbers", ["quickSums","equationPick","numberSort","changeMaker","balanceScale"]),
    ("focus",   ["colorClash","findTarget","symbolHunt","oddColorOut","gapCount"]),
    ("reflex",  ["tapGo","catchGreen","popOrder","arrowRush"])
]

func drawGameTile(domain: String, name: String, index: Int) {
    let W = 720, H = 480
    let ctx = makeContext(W, H)
    let rect = CGRect(x: 0, y: 0, width: W, height: H)
    let base = domainColor(domain)
    var rnd = Rand("tile_" + name)

    // layered background: deep vertical + tinted radial + accent blobs
    fillLinear(ctx, rect: rect, from: midnight.mix(base, 0.16).cg(), to: deep.cg())
    fillRadial(ctx, rect: rect,
               inner: base.mix(gold, rnd.range(0.0, 0.25)).cg(0.35), outer: deep.cg(0),
               center: CGPoint(x: rnd.range(0.3, 0.7) * CGFloat(W), y: rnd.range(0.25, 0.5) * CGFloat(H)),
               radiusScale: 0.6)
    blob(ctx, CGPoint(x: rnd.range(0.05, 0.3) * CGFloat(W), y: rnd.range(0.6, 0.95) * CGFloat(H)),
         CGFloat(W) * 0.45, base, 0.22)
    blob(ctx, CGPoint(x: rnd.range(0.7, 0.95) * CGFloat(W), y: rnd.range(0.05, 0.4) * CGFloat(H)),
         CGFloat(W) * 0.35, gold, 0.10)
    pinstripes(ctx, rect: rect, color: white.cg(0.028), gap: rnd.range(46, 70), width: 2)

    // emblem
    let c = CGPoint(x: CGFloat(W) * 0.5, y: CGFloat(H) * 0.52)
    let s = CGFloat(H) * 0.27
    ring(ctx, c, s * 1.55, white.cg(0.07), 8)
    ring(ctx, c, s * 1.32, base.lighter(0.2).cg(0.20), 3)
    drawMotif(ctx, kind: index, c: c, s: s, base: base, rnd: &rnd)
    var colors = [gold, white, base.lighter(0.3)]
    orbitDots(ctx, c, s * 1.55, count: 7, colors: colors, rnd: &rnd)

    // sparkles + vignette
    sparkle(ctx, CGPoint(x: CGFloat(W)*rnd.range(0.72, 0.86), y: CGFloat(H)*rnd.range(0.14, 0.26)),
            rnd.range(16, 26), white.cg(0.85))
    sparkle(ctx, CGPoint(x: CGFloat(W)*rnd.range(0.10, 0.24), y: CGFloat(H)*rnd.range(0.68, 0.85)),
            rnd.range(10, 18), gold.lighter(0.2).cg(0.9))
    fillRadial(ctx, rect: rect, inner: deep.cg(0), outer: deep.cg(0.55),
               center: CGPoint(x: W/2, y: H/2), radiusScale: 0.85)

    addNoise(ctx, amp: 1)
    write(ctx, to: "\(artDir)/game_\(name).png")
    _ = colors.popLast()
}

// MARK: - Domain banners

func drawBanner(_ domain: String) {
    let W = 1080, H = 405
    let ctx = makeContext(W, H)
    let rect = CGRect(x: 0, y: 0, width: W, height: H)
    let base = domainColor(domain)
    var rnd = Rand("banner_" + domain)

    fillLinear(ctx, rect: rect, from: base.mix(midnight, 0.35).cg(), to: deep.cg(), horizontal: true)
    blob(ctx, CGPoint(x: CGFloat(W)*0.15, y: CGFloat(H)*0.3), CGFloat(W)*0.3, base, 0.35)
    blob(ctx, CGPoint(x: CGFloat(W)*0.65, y: CGFloat(H)*0.8), CGFloat(W)*0.25, gold, 0.12)
    pinstripes(ctx, rect: rect, color: white.cg(0.03), gap: 60, width: 2)

    let c = CGPoint(x: CGFloat(W)*0.82, y: CGFloat(H)*0.5)
    ring(ctx, c, 200, white.cg(0.10), 30)
    ring(ctx, c, 128, white.cg(0.16), 22)
    circle(ctx, c, 60, white.cg(0.20))
    circle(ctx, c, 26, gold.cg(0.85))
    var colors = [gold, white, base.lighter(0.3)]
    orbitDots(ctx, c, 210, count: 9, colors: colors, rnd: &rnd)
    for _ in 0..<8 {
        circle(ctx, CGPoint(x: rnd.range(0, 1)*CGFloat(W), y: rnd.range(0, 1)*CGFloat(H)),
               rnd.range(4, 16), white.cg(0.05))
    }
    _ = colors.popLast()

    addNoise(ctx, amp: 1)
    write(ctx, to: "\(artDir)/banner_\(domain).png")
}

// MARK: - Ambient backdrops (behind live games)

func drawAmbient(_ domain: String) {
    let W = 600, H = 1300
    let ctx = makeContext(W, H)
    let rect = CGRect(x: 0, y: 0, width: W, height: H)
    let base = domainColor(domain)
    var rnd = Rand("ambient_" + domain)

    fillLinear(ctx, rect: rect, from: midnight.mix(base, 0.10).cg(), to: deep.cg())
    blob(ctx, CGPoint(x: CGFloat(W)*0.2, y: CGFloat(H)*0.12), CGFloat(W)*0.75, base, 0.20)
    blob(ctx, CGPoint(x: CGFloat(W)*0.9, y: CGFloat(H)*0.45), CGFloat(W)*0.6, base.mix(gold, 0.5), 0.10)
    blob(ctx, CGPoint(x: CGFloat(W)*0.3, y: CGFloat(H)*0.85), CGFloat(W)*0.7, vDark, 0.16)
    ring(ctx, CGPoint(x: CGFloat(W)*0.85, y: CGFloat(H)*0.18), 190, white.cg(0.045), 26)
    ring(ctx, CGPoint(x: CGFloat(W)*0.12, y: CGFloat(H)*0.62), 150, white.cg(0.04), 20)
    for _ in 0..<26 {
        circle(ctx, CGPoint(x: rnd.range(0, 1)*CGFloat(W), y: rnd.range(0, 1)*CGFloat(H)),
               rnd.range(1.5, 5), white.cg(rnd.range(0.05, 0.16)))
    }
    addNoise(ctx, amp: 1)
    write(ctx, to: "\(artDir)/ambient_\(domain).png")
}

// MARK: - Onboarding illustrations

func drawOnboard(_ i: Int) {
    let W = 800, H = 800
    let ctx = makeContext(W, H)
    let rect = CGRect(x: 0, y: 0, width: W, height: H)
    var rnd = Rand("onboard_\(i)")
    let c = CGPoint(x: CGFloat(W)/2, y: CGFloat(H)/2)

    fillLinear(ctx, rect: rect, from: midnight.mix(violet, 0.18).cg(), to: deep.cg())
    pinstripes(ctx, rect: rect, color: white.cg(0.03), gap: 54, width: 2)

    switch i {
    case 1: // five focused minutes — clock ring + play token
        blob(ctx, c, 400, violet, 0.30)
        ring(ctx, c, 300, white.cg(0.10), 34)
        ring(ctx, c, 300, gold.cg(0.85), 10)
        // tick marks
        for t in 0..<12 {
            let a = CGFloat(t) / 12 * 2 * .pi
            let p1 = CGPoint(x: c.x + cos(a)*272, y: c.y + sin(a)*272)
            let p2 = CGPoint(x: c.x + cos(a)*246, y: c.y + sin(a)*246)
            ctx.setStrokeColor(white.cg(t % 3 == 0 ? 0.75 : 0.30)); ctx.setLineWidth(t % 3 == 0 ? 10 : 6)
            ctx.beginPath(); ctx.move(to: p1); ctx.addLine(to: p2); ctx.strokePath()
        }
        circle(ctx, c, 150, violet.lighter(0.05).cg())
        circle(ctx, c, 150, white.cg(0.10))
        let tri = CGMutablePath()
        tri.move(to: CGPoint(x: c.x - 44, y: c.y - 64))
        tri.addLine(to: CGPoint(x: c.x + 72, y: c.y))
        tri.addLine(to: CGPoint(x: c.x - 44, y: c.y + 64))
        tri.closeSubpath()
        ctx.setFillColor(white.cg(0.95)); ctx.addPath(tri); ctx.fillPath()
        var cs = [gold, white, violet.lighter(0.3)]
        orbitDots(ctx, c, 330, count: 10, colors: cs, rnd: &rnd); _ = cs.popLast()
    case 2: // four skills radar
        blob(ctx, c, 400, teal, 0.18)
        let doms = [violet, teal, orange, rose]
        for (k, rr) in [0.28, 0.52, 0.76, 1.0].enumerated() {
            let p = CGMutablePath()
            for j in 0..<4 {
                let a = CGFloat(j) / 4 * 2 * .pi - .pi/2
                let pt = CGPoint(x: c.x + cos(a)*300*CGFloat(rr), y: c.y + sin(a)*300*CGFloat(rr))
                if j == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            ctx.setStrokeColor(white.cg(k == 3 ? 0.30 : 0.12)); ctx.setLineWidth(k == 3 ? 6 : 4)
            ctx.addPath(p); ctx.strokePath()
        }
        // value polygon
        let vals: [CGFloat] = [0.85, 0.62, 0.74, 0.55]
        let poly = CGMutablePath()
        for j in 0..<4 {
            let a = CGFloat(j) / 4 * 2 * .pi - .pi/2
            let pt = CGPoint(x: c.x + cos(a)*300*vals[j], y: c.y + sin(a)*300*vals[j])
            if j == 0 { poly.move(to: pt) } else { poly.addLine(to: pt) }
        }
        poly.closeSubpath()
        ctx.setFillColor(violet.cg(0.30)); ctx.addPath(poly); ctx.fillPath()
        ctx.setStrokeColor(violet.lighter(0.2).cg(0.9)); ctx.setLineWidth(8); ctx.addPath(poly); ctx.strokePath()
        for j in 0..<4 {
            let a = CGFloat(j) / 4 * 2 * .pi - .pi/2
            let pt = CGPoint(x: c.x + cos(a)*300*vals[j], y: c.y + sin(a)*300*vals[j])
            circle(ctx, pt, 16, doms[j].cg())
            circle(ctx, pt, 16, white.cg(0.25))
        }
    default: // streaks & awards — flame medal + stars
        blob(ctx, c, 400, gold, 0.20)
        circle(ctx, c, 250, gold.darker(0.30).cg())
        circle(ctx, c, 226, gold.lighter(0.05).cg())
        ring(ctx, c, 176, gold.darker(0.35).cg(0.7), 12)
        // flame
        let f = CGMutablePath()
        f.move(to: CGPoint(x: c.x, y: c.y - 120))
        f.addQuadCurve(to: CGPoint(x: c.x + 92, y: c.y + 16), control: CGPoint(x: c.x + 110, y: c.y - 70))
        f.addQuadCurve(to: CGPoint(x: c.x, y: c.y + 120), control: CGPoint(x: c.x + 92, y: c.y + 106))
        f.addQuadCurve(to: CGPoint(x: c.x - 92, y: c.y + 16), control: CGPoint(x: c.x - 92, y: c.y + 106))
        f.addQuadCurve(to: CGPoint(x: c.x, y: c.y - 120), control: CGPoint(x: c.x - 110, y: c.y - 70))
        ctx.setFillColor(gold.darker(0.45).cg()); ctx.addPath(f); ctx.fillPath()
        // stars around
        for k in 0..<5 {
            let a = CGFloat(k) / 5 * 2 * .pi - .pi/2
            let pt = CGPoint(x: c.x + cos(a)*330, y: c.y + sin(a)*330)
            ctx.setFillColor(k % 2 == 0 ? white.cg(0.85) : gold.lighter(0.15).cg(0.9))
            ctx.addPath(starPath(pt, outer: rnd.range(18, 30), inner: rnd.range(8, 13), points: 5))
            ctx.fillPath()
        }
    }

    sparkle(ctx, CGPoint(x: CGFloat(W)*0.8, y: CGFloat(H)*0.16), 26, white.cg(0.9))
    sparkle(ctx, CGPoint(x: CGFloat(W)*0.16, y: CGFloat(H)*0.8), 18, gold.lighter(0.2).cg(0.9))
    fillRadial(ctx, rect: rect, inner: deep.cg(0), outer: deep.cg(0.5),
               center: c, radiusScale: 0.8)
    addNoise(ctx, amp: 1)
    write(ctx, to: "\(artDir)/onboard_\(i).png")
}

// MARK: - Award badges (medals)

let badgeIDs = ["firstStep","warmedUp","gamer50","centurion","marathon",
                "streak3","streak7","streak14","streak30",
                "firstSet","tenSets","thirtySets",
                "sharp","brilliant","balanced","mastermind","xp5k","explorer"]

func drawBadge(_ id: String, index: Int) {
    let S = 360
    let ctx = makeContext(S, S)
    let rect = CGRect(x: 0, y: 0, width: S, height: S)
    var rnd = Rand("badge_" + id)
    let c = CGPoint(x: CGFloat(S)/2, y: CGFloat(S)/2)
    let palettes: [RGB] = [violet, teal, orange, rose, gold, vDark.lighter(0.2)]
    let base = palettes[index % palettes.count]

    // background disc (fills whole tile; app clips to circle)
    fillRadial(ctx, rect: rect, inner: midnight.mix(base, 0.35).cg(), outer: deep.cg(), radiusScale: 0.6)
    blob(ctx, CGPoint(x: CGFloat(S)*0.3, y: CGFloat(S)*0.3), CGFloat(S)*0.5, base, 0.30)

    // medal rings
    ring(ctx, c, CGFloat(S)*0.42, gold.darker(0.15).cg(), CGFloat(S)*0.045)
    ring(ctx, c, CGFloat(S)*0.36, gold.lighter(0.10).cg(0.65), CGFloat(S)*0.015)

    // inner emblem — varied per badge family
    let s = CGFloat(S) * 0.17
    drawMotif(ctx, kind: index / 2 + index, c: c, s: s, base: base, rnd: &rnd)

    // dots on the ring
    for k in 0..<8 {
        let a = CGFloat(k) / 8 * 2 * .pi
        circle(ctx, CGPoint(x: c.x + cos(a)*CGFloat(S)*0.42, y: c.y + sin(a)*CGFloat(S)*0.42),
               CGFloat(S)*0.012, white.cg(0.7))
    }
    sparkle(ctx, CGPoint(x: CGFloat(S)*0.74, y: CGFloat(S)*0.24), 16, white.cg(0.9))
    addNoise(ctx, amp: 1)
    write(ctx, to: "\(artDir)/badge_\(id).png")
}

// MARK: - Grain texture tile (soft-light overlay in app)

func drawGrain() {
    let S = 512
    let ctx = makeContext(S, S)
    ctx.setFillColor(RGB(r: 0.5, g: 0.5, b: 0.5).cg())
    ctx.fill(CGRect(x: 0, y: 0, width: S, height: S))
    addNoise(ctx, amp: 26)
    write(ctx, to: "\(artDir)/texture_grain.png")
}

// MARK: - App icon (deep midnight + gold gem)

func drawAppIcon() {
    let S = 1024
    let ctx = makeContext(S, S)
    let rect = CGRect(x: 0, y: 0, width: S, height: S)
    fillRadial(ctx, rect: rect, inner: midnight.mix(violet, 0.30).cg(), outer: deep.darker(0.2).cg(),
               center: CGPoint(x: CGFloat(S)*0.5, y: CGFloat(S)*0.40), radiusScale: 0.7)
    blob(ctx, CGPoint(x: CGFloat(S)*0.28, y: CGFloat(S)*0.24), CGFloat(S)*0.4, violet, 0.35)
    blob(ctx, CGPoint(x: CGFloat(S)*0.76, y: CGFloat(S)*0.72), CGFloat(S)*0.34, rose, 0.16)
    let c = CGPoint(x: CGFloat(S)/2, y: CGFloat(S)/2)
    circle(ctx, c, CGFloat(S)*0.30, violet.lighter(0.10).cg(0.16))
    gem(ctx, center: CGPoint(x: c.x, y: c.y - CGFloat(S)*0.01), radius: CGFloat(S)*0.26,
        top: gold.lighter(0.16), bottom: gold.darker(0.20), facet: white)
    ring(ctx, c, CGFloat(S)*0.35, gold.lighter(0.08).cg(0.8), CGFloat(S)*0.012)
    sparkle(ctx, CGPoint(x: CGFloat(S)*0.71, y: CGFloat(S)*0.29), CGFloat(S)*0.045, white.cg(0.92))
    sparkle(ctx, CGPoint(x: CGFloat(S)*0.29, y: CGFloat(S)*0.69), CGFloat(S)*0.030, gold.lighter(0.2).cg(0.92))
    addNoise(ctx, amp: 1)
    write(ctx, to: iconPath)
}

// MARK: - Run

drawAppIcon()
drawGrain()
var tileIndex = 0
for (d, games) in gamesByDomain {
    drawBanner(d)
    drawAmbient(d)
    for g in games {
        drawGameTile(domain: d, name: g, index: tileIndex)
        tileIndex += 1
    }
}
for i in 1...3 { drawOnboard(i) }
for (i, id) in badgeIDs.enumerated() { drawBadge(id, index: i) }
print("art v2 generated: \(tileIndex) tiles + 4 banners + 4 ambient + 3 onboarding + \(badgeIDs.count) badges + grain + icon")
