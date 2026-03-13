import SwiftUI

struct PartnerStatusPill: View {
    var partnerName: String = "Partner"
    var timezone: String = "America/Toronto"
    var isOnline: Bool = false

    var body: some View {
        if isSleeping {
            sleepingCard
        } else {
            awakePill
        }
    }

    // MARK: - Awake State (original pill)

    private var awakePill: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.rose.opacity(0.3), Color.rose.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Text(String(partnerName.prefix(1)))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.rose)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(partnerName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.ink)

                Text("\(timeOfDayEmoji) \(partnerTimeDescription)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSoft)
            }

            Spacer()

            Circle()
                .fill(isOnline ? Color.sage : Color.inkFaint.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(Spacing.lg)
        .sweetieGlass()
    }

    // MARK: - Sleeping State (dreamy card)

    private var sleepingCard: some View {
        HStack(spacing: Spacing.md) {
            // Moon icon with soft glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.lavender.opacity(0.3), Color.lavender.opacity(0.05)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 24
                        )
                    )
                    .frame(width: 44, height: 44)

                Text("🌙")
                    .font(.system(size: 22))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(partnerName) is dreaming")
                    .font(.romanticSmall)
                    .foregroundStyle(Color.ink)

                Text("\(partnerTimeString) in \(cityName)")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.inkFaint)
            }

            Spacer()

            // Floating z's
            HStack(spacing: 3) {
                Text("z")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundStyle(Color.lavender.opacity(0.5))
                Text("z")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(Color.lavender.opacity(0.7))
                    .offset(y: -3)
                Text("Z")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundStyle(Color.lavender.opacity(0.9))
                    .offset(y: -7)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.lavender.opacity(0.08),
                            Color.lavender.opacity(0.15),
                            Color.lavender.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.lavender.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Computed Properties

    private var partnerHour: Int {
        let tz = TimeZone(identifier: timezone) ?? .current
        let components = Calendar.current.dateComponents(in: tz, from: Date())
        return components.hour ?? 12
    }

    private var isSleeping: Bool {
        let hour = partnerHour
        return hour >= 23 || hour < 6
    }

    private var timeOfDayEmoji: String {
        let hour = partnerHour
        switch hour {
        case 6..<12: return "☀️"
        case 12..<17: return "🌤️"
        case 17..<20: return "🌅"
        case 20..<23: return "🌙"
        default: return "💤"
        }
    }

    private var partnerTimeString: String {
        let tz = TimeZone(identifier: timezone) ?? .current
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private var cityName: String {
        timezone.split(separator: "/").last.map(String.init) ?? timezone
    }

    private var partnerTimeDescription: String {
        let period: String
        let hour = partnerHour
        switch hour {
        case 6..<12: period = "Morning"
        case 12..<17: period = "Afternoon"
        case 17..<20: period = "Evening"
        case 20..<23: period = "Night"
        default: period = "Likely sleeping"
        }

        return "\(partnerTimeString) · \(period) in \(cityName)"
    }
}
