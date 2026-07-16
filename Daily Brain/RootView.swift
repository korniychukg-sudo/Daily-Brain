import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: BrainStore
    @State private var tab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            BrainTheme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0: NavigationView { TodayView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 1: NavigationView { GamesLibraryView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 2: NavigationView { ProfileView() }.navigationViewStyle(StackNavigationViewStyle())
                    default: NavigationView { MoreView() }.navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
        .onAppear { store.refreshPlanIfNeeded() }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Today", .home)
            tabButton(1, "Games", .grid)
            tabButton(2, "Profile", .radar)
            tabButton(3, "More", .menu)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(
            BrainTheme.card
                .shadow(color: BrainTheme.ink.opacity(0.06), radius: 10, y: -2)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(_ index: Int, _ label: String, _ glyph: BrainGlyph) -> some View {
        Button {
            BrainHaptics.tap()
            tab = index
        } label: {
            VStack(spacing: 5) {
                BrainIcon(glyph: glyph, size: 24,
                          color: tab == index ? BrainTheme.primary : BrainTheme.subtle.opacity(0.7),
                          weight: 2.2)
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(tab == index ? BrainTheme.primary : BrainTheme.subtle.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
        }
    }
}
