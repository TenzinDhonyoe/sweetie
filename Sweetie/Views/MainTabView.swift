import SwiftUI

struct MainTabView: View {
    @Environment(SupabaseService.self) private var supabase
    @State private var selectedTab = 0
    @State private var receivedTap = false
    @State private var incomingTapBanner: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                    .tag(0)

                HeartView()
                    .tabItem {
                        Image(systemName: "heart.fill")
                        Text("Heart")
                    }
                    .tag(1)

                SettingsView()
                    .tabItem {
                        Image(systemName: "gearshape")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .tint(Color.rose)
            .toolbarBackground(.automatic, for: .tabBar)

            // Incoming tap banner
            if let bannerEmoji = incomingTapBanner {
                incomingBanner(emoji: bannerEmoji)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, 60)
            }
        }
        .onAppear {
            subscribeToBroadcastTaps()
        }
    }

    // MARK: - Incoming Tap Banner

    private func incomingBanner(emoji: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Text("They're thinking of you \(emoji)")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.ink)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.vertical, Spacing.md)
        .sweetieGlass(cornerRadius: 20)
        .shadow(color: .rose.opacity(0.15), radius: 12, y: 4)
    }

    // MARK: - Broadcast Subscription

    private func subscribeToBroadcastTaps() {
        guard let coupleId = supabase.couple?.id else { return }

        supabase.subscribeToBroadcastTaps(coupleId: coupleId) { emoji, pattern in
            receivedTap = true
            HapticService.playPattern(pattern)
            SoundService.play(.pop)

            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                incomingTapBanner = emoji
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.spring(duration: 0.4)) {
                    incomingTapBanner = nil
                }
            }
        }
    }
}
