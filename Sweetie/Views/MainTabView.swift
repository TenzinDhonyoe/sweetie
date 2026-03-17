import SwiftUI

struct MainTabView: View {
    @Environment(SupabaseService.self) private var supabase
    @Binding var selectedTab: Int
    @State private var receivedTap = false
    @State private var incomingTapBanner: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area — show the selected tab
            Group {
                switch selectedTab {
                case 0: HomeView()
                case 1: HeartView()
                case 2: SettingsView()
                default: HomeView()
                }
            }

            // Custom tab bar
            customTabBar
                .padding(.horizontal, Spacing.xl)
                .padding(.bottom, Spacing.sm)

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

    // MARK: - Custom Tab Bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(icon: "house", label: "Home", tag: 0)
            tabButton(icon: "heart.fill", label: "Heart", tag: 1)
            tabButton(icon: "gearshape", label: "Settings", tag: 2)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.md)
        .sweetieGlass(cornerRadius: 28)
    }

    private func tabButton(icon: String, label: String, tag: Int) -> some View {
        let isSelected = selectedTab == tag

        return Button {
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                selectedTab = tag
            }
            HapticService.tap()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolEffect(.bounce, value: isSelected)

                Text(label)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(isSelected ? Color.rose : Color.inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
        }
        .buttonStyle(.plain)
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
