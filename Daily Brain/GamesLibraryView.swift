import SwiftUI

struct GamesLibraryView: View {
    @EnvironmentObject var store: BrainStore
    @State private var activeGame: GameKind?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                ForEach(BrainDomain.allCases) { domain in
                    domainSection(domain)
                }
            }
            .padding(16)
            .padding(.bottom, 10)
        }
        .background(BrainTheme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(item: $activeGame) { kind in
            GameHost(kind: kind, partOfDaily: false) { _ in activeGame = nil }
                .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Games")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(BrainTheme.ink)
            Text("\(GameKind.allCases.count) mini-games across four skills")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(BrainTheme.subtle)
        }
    }

    private func domainSection(_ domain: BrainDomain) -> some View {
        let games = GameKind.allCases.filter { $0.domain == domain }
        return VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .bottomLeading) {
                DomainBannerView(domain: domain)
                    .frame(height: 92)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.42)], startPoint: .top, endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Color.white.opacity(0.22)).frame(width: 40, height: 40)
                        BrainIcon(glyph: BrainGlyph.forDomain(domain), size: 22, color: .white, weight: 2.2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(domain.title)
                            .font(.system(size: 19, weight: .heavy, design: .rounded)).foregroundColor(.white)
                        Text("Rating \(store.profile.rating(domain))")
                            .font(.system(size: 12, weight: .semibold, design: .rounded)).foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(14)
            }
            .frame(height: 92)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(games) { game in
                    gameCard(game)
                }
            }
        }
    }

    private func gameCard(_ kind: GameKind) -> some View {
        let best = store.best(for: kind)
        return Button { activeGame = kind } label: {
            VStack(alignment: .leading, spacing: 0) {
                GameArtView(kind: kind, cornerRadius: 0)
                    .frame(height: 96)
                    .clipShape(RoundedCorner(radius: 16, corners: [.topLeft, .topRight]))
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(BrainTheme.ink)
                        .lineLimit(1)
                    HStack(spacing: 5) {
                        if best.plays > 0 {
                            BrainIcon(glyph: .star, size: 12, color: BrainTheme.gold, weight: 2)
                            Text("Best \(best.bestScore)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(BrainTheme.subtle)
                        } else {
                            Text("Not played yet")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(BrainTheme.subtle)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(BrainTheme.card)
                .shadow(color: BrainTheme.ink.opacity(0.06), radius: 8, y: 3))
        }
        .buttonStyle(.plain)
    }
}

// Rounded specific corners helper.
struct RoundedCorner: Shape {
    var radius: CGFloat = 16
    var corners: UIRectCorner = .allCorners
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
