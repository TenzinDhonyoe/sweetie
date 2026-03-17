import SwiftUI

struct HeartView: View {
    @Environment(SupabaseService.self) private var supabase

    @State private var heartScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 20
    @State private var showQuickActions = false
    @State private var todayTaps: [Tap] = []
    @State private var isPressed = false
    @State private var showRipple = false
    @State private var floatingText: String?
    @State private var floatingOffset: CGFloat = 0
    @State private var floatingOpacity: Double = 1
    @State private var tapSent = false
    @State private var partnerName: String = "Partner"

    private var userId: String? {
        supabase.userId
    }

    private let presets: [(emoji: String, label: String, pattern: String)] = [
        ("💕", "Love", "love"),
        ("🤗", "Hug", "hug"),
        ("😘", "Kiss", "kiss"),
        ("🌙", "Night", "goodnight"),
        ("☀️", "Morning", "morning"),
    ]

    var body: some View {
        ZStack {
            BackgroundGradient(style: .heart)

            VStack(spacing: Spacing.xxxl) {
                Spacer()

                // Main heart
                heartButton

                // Preset circles
                presetRow

                // Today card
                todayCard

                Spacer()
            }
            .padding(.horizontal, Spacing.xl)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadTodayTaps()
            if let partner = await supabase.fetchPartnerProfile() {
                partnerName = partner.displayName ?? "Partner"
            }
        }
        .onAppear {
            startPulse()
        }
        .sheet(isPresented: $showQuickActions) {
            QuickActionMenu { emoji, pattern in
                Task {
                    try? await supabase.sendTap(pattern: pattern, emoji: emoji)
                    await loadTodayTaps()
                }
            }
        }
    }

    // MARK: - Heart Button

    private var heartButton: some View {
        ZStack {
            // Ripple rings
            if showRipple {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .stroke(Color.rose.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                        .frame(width: 120 + CGFloat(i) * 30, height: 120 + CGFloat(i) * 30)
                        .scaleEffect(showRipple ? 1.5 : 1)
                        .opacity(showRipple ? 0 : 1)
                        .animation(
                            .spring(duration: 0.6).delay(Double(i) * 0.1),
                            value: showRipple
                        )
                }
            }

            // Floating text
            if let text = floatingText {
                Text(text)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.rose)
                    .offset(y: floatingOffset)
                    .opacity(floatingOpacity)
            }

            // Pulsing shadow
            Circle()
                .fill(Color.rose.opacity(0.15))
                .frame(width: 140, height: 140)
                .blur(radius: shadowRadius)
                .scaleEffect(heartScale)

            // Heart icon
            Image(systemName: "heart.fill")
                .font(.system(size: 120))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.rose, .roseDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isPressed ? 0.85 : heartScale)
                .shadow(color: .rose.opacity(0.4), radius: shadowRadius, y: 8)
        }
        .onTapGesture {
            performTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            HapticService.heavyTap()
            showQuickActions = true
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: tapSent)
    }

    // MARK: - Preset Row

    private var presetRow: some View {
        HStack(spacing: Spacing.lg) {
            ForEach(presets, id: \.pattern) { preset in
                Button {
                    Task {
                        try? await supabase.sendTap(pattern: preset.pattern, emoji: preset.emoji)
                        HapticService.tap()
                        await loadTodayTaps()
                    }
                } label: {
                    VStack(spacing: Spacing.xs) {
                        Text(preset.emoji)
                            .font(.system(size: 24))
                            .frame(width: 52, height: 52)
                            .sweetieGlass(cornerRadius: 26)

                        Text(preset.label)
                            .font(.system(size: 11))
                            .foregroundStyle(Color.inkSoft)
                    }
                }
                .buttonStyle(PresetButtonStyle())
            }
        }
    }

    // MARK: - Today Card

    private var groupedTaps: [TapGroup] {
        let userId = self.userId
        let grouped = Dictionary(grouping: todayTaps) { tap in
            "\(tap.senderId == userId)-\(tap.emoji ?? "💕")"
        }
        return grouped.map { key, taps in
            let isMe = taps[0].senderId == userId
            let emoji = taps[0].emoji ?? "💕"
            return TapGroup(
                id: key,
                isMe: isMe,
                emoji: emoji,
                count: taps.count,
                label: isMe ? "You" : partnerName
            )
        }
        .sorted { a, b in
            if a.isMe != b.isMe { return a.isMe }
            return a.count > b.count
        }
    }

    private var todayCard: some View {
        GlassCard {
            VStack(spacing: Spacing.sm) {
                Text("Today")
                    .sectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)

                if todayTaps.isEmpty {
                    Text("No taps yet today")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkFaint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(groupedTaps, id: \.id) { group in
                        tapGroupRow(group)
                    }
                }
            }
        }
    }

    private func tapGroupRow(_ group: TapGroup) -> some View {
        HStack(spacing: Spacing.xs) {
            Text(group.label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(group.isMe ? Color.ink : Color.rose)

            Text("sent")
                .font(.system(size: 15))
                .foregroundStyle(Color.inkSoft)

            Text("\(group.count)")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color.ink)

            Text(group.emoji)
                .font(.system(size: 16))

            Spacer()
        }
    }

    // MARK: - Actions

    private func performTap() {
        withAnimation(.spring(duration: 0.15)) {
            isPressed = true
        }
        HapticService.heavyTap()

        withAnimation(.spring(duration: 0.4, bounce: 0.4)) {
            isPressed = false
            showRipple = true
        }

        HapticService.success()
        SoundService.play(.pop)
        tapSent.toggle()

        showFloatingText("+1 💕")

        Task {
            try? await supabase.sendTap(pattern: "default", emoji: "💕")
            await loadTodayTaps()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            showRipple = false
        }
    }

    private func showFloatingText(_ text: String) {
        floatingText = text
        floatingOffset = 0
        floatingOpacity = 1

        withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
            floatingOffset = -80
            floatingOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            floatingText = nil
        }
    }

    private func startPulse() {
        withAnimation(.spring(duration: 1.5, bounce: 0.1).repeatForever(autoreverses: true)) {
            heartScale = 1.06
            shadowRadius = 30
        }
    }

    private func loadTodayTaps() async {
        todayTaps = await supabase.fetchRecentTaps(limit: 20)
        // Filter to today only
        let calendar = Calendar.current
        todayTaps = todayTaps.filter { tap in
            guard let date = DateFormatting.parse(tap.createdAt) else { return false }
            return calendar.isDateInToday(date)
        }
    }
}

// MARK: - Tap Group

private struct TapGroup {
    let id: String
    let isMe: Bool
    let emoji: String
    let count: Int
    let label: String
}

// MARK: - Preset Button Style

private struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
