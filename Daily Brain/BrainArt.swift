import SwiftUI

/// Loads bundled art PNGs (from the copied "Art" folder reference) with an
/// in-memory cache. Falls back to a drawn emblem if a file is missing.
enum BrainArtLoader {
    private static var cache: [String: UIImage] = [:]

    static func image(named name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        if let url = Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "Art"),
           let img = UIImage(contentsOfFile: url.path) {
            cache[name] = img
            return img
        }
        if let img = UIImage(named: name) {
            cache[name] = img
            return img
        }
        return nil
    }
}

/// Art tile for a game; shows the generated illustration or a themed fallback.
struct GameArtView: View {
    let kind: GameKind
    var cornerRadius: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let ui = BrainArtLoader.image(named: kind.artAsset) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    fallback(size: geo.size)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func fallback(size: CGSize) -> some View {
        let c = kind.domain.color
        return ZStack {
            LinearGradient(colors: [c.opacity(0.92), c.opacity(0.62)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            BrainIcon(glyph: BrainGlyph.forDomain(kind.domain),
                      size: min(size.width, size.height) * 0.42,
                      color: .white.opacity(0.9), weight: 2.6)
        }
    }
}

/// Domain banner art (wide) with fallback.
struct DomainBannerView: View {
    let domain: BrainDomain

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let ui = BrainArtLoader.image(named: domain.bannerAsset) {
                    Image(uiImage: ui)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    LinearGradient(colors: [domain.color, domain.color.opacity(0.6)],
                                   startPoint: .leading, endPoint: .trailing)
                }
            }
        }
    }
}
