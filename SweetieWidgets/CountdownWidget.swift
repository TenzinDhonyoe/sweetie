import WidgetKit
import SwiftUI

struct CountdownEntry: TimelineEntry {
    let date: Date
    let reunionDate: Date?
    let recentActivity: [SharedActivityItem]
    let latestPhoto: UIImage?
    let latestPhotoMeta: SharedPhotoData?
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: .now,
            reunionDate: Calendar.current.date(byAdding: .day, value: 42, to: .now),
            recentActivity: [],
            latestPhoto: nil,
            latestPhotoMeta: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let entry = loadEntry()

        // Smart refresh: medium/large show hours+minutes, so update every minute.
        // Small only shows days, so update at midnight.
        switch context.family {
        case .systemMedium, .systemLarge:
            var entries: [CountdownEntry] = []
            let now = Date()
            for minuteOffset in 0..<60 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) ?? now
                entries.append(CountdownEntry(
                    date: entryDate,
                    reunionDate: entry.reunionDate,
                    recentActivity: entry.recentActivity,
                    latestPhoto: entry.latestPhoto,
                    latestPhotoMeta: entry.latestPhotoMeta
                ))
            }
            completion(Timeline(entries: entries, policy: .atEnd))

        default:
            // Small widget: refresh at midnight or in 1 hour, whichever is sooner
            let nextMidnight = Calendar.current.startOfDay(
                for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
            )
            let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
            let refreshDate = min(nextMidnight, nextHour)
            completion(Timeline(entries: [entry], policy: .after(refreshDate)))
        }
    }

    private func loadEntry() -> CountdownEntry {
        let manager = SharedDataManager.shared
        return CountdownEntry(
            date: .now,
            reunionDate: manager.loadReunionDate(),
            recentActivity: manager.loadRecentActivity(),
            latestPhoto: manager.loadLatestPhotoImage(),
            latestPhotoMeta: manager.loadLatestPhoto()
        )
    }
}

// MARK: - Small Widget View

struct CountdownSmallView: View {
    let entry: CountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)

            if countdown.isPast {
                togetherNowView
            } else {
                VStack(spacing: Spacing.xs) {
                    Spacer()

                    Text("\(countdown.days)")
                        .font(.custom("PlayfairDisplay-Bold", size: 34))
                        .foregroundStyle(Color.gold)

                    Text("days")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)

                    Text(CountdownTaglines.tagline(for: entry.date))
                        .font(.custom("PlayfairDisplay-Italic", size: 11))
                        .foregroundStyle(Color.inkSoft)

                    Spacer()

                    HStack {
                        Spacer()
                        Image("mascot-hug")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            noDateView
        }
    }

    private var togetherNowView: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()
            Image("mascot-hug")
                .resizable()
                .interpolation(.none)
                .frame(width: 36, height: 36)
            Text("Together\nright now")
                .font(.custom("PlayfairDisplay-Bold", size: 15))
                .foregroundStyle(Color.rose)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var noDateView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "heart.circle")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.5))

            Text("Set a date")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.inkSoft)

            Text("for your reunion")
                .font(.system(size: 10))
                .foregroundStyle(Color.inkFaint)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View

struct CountdownMediumView: View {
    let entry: CountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)

            if countdown.isPast {
                togetherNowMediumView
            } else {
                HStack {
                    VStack(spacing: Spacing.xs) {
                        Text("\(countdown.days)")
                            .font(.custom("PlayfairDisplay-Bold", size: 44))
                            .foregroundStyle(Color.gold)

                        Text("days \u{2022} \(countdown.hours)h \(countdown.minutes)m")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSoft)
                    }
                    .frame(maxWidth: .infinity)

                    rightSideContent
                }
            }
        } else {
            mediumEmptyState
        }
    }

    private func timeChip(value: Int, unit: String) -> some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.ink)
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color.inkFaint)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.ink.opacity(0.04))
        )
    }

    private var mediumEmptyState: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: "heart.circle")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.5))

            VStack(alignment: .leading, spacing: 4) {
                Text("Set a reunion date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.ink)
                Text("Open Sweetie to start counting down")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var togetherNowMediumView: some View {
        HStack {
            VStack(spacing: Spacing.sm) {
                Image("mascot-hug")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 48, height: 48)
                Text("Together right now")
                    .font(.custom("PlayfairDisplay-Bold", size: 17))
                    .foregroundStyle(Color.rose)
            }
            .frame(maxWidth: .infinity)

            rightSideContent
        }
    }

    @ViewBuilder
    private var rightSideContent: some View {
        VStack(spacing: Spacing.sm) {
            Spacer()

            if let photo = entry.latestPhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                if let meta = entry.latestPhotoMeta {
                    Text(meta.senderName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.ink)

                    Text(meta.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkFaint)
                }
            } else if let latestTap = entry.recentActivity.first(where: { $0.kind == .tap }) {
                Text(latestTap.emoji ?? "💕")
                    .font(.system(size: 36))

                Text(latestTap.senderName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.ink)

                Text(latestTap.timestamp, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
            } else {
                Text(CountdownTaglines.tagline(for: entry.date))
                    .font(.custom("PlayfairDisplay-Italic", size: 15))
                    .foregroundStyle(Color.inkSoft)
                    .multilineTextAlignment(.center)

                Image("mascot-hug")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 32, height: 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Large Widget View

struct CountdownLargeView: View {
    let entry: CountdownEntry

    var body: some View {
        VStack(spacing: 0) {
            countdownSection
                .padding(.bottom, Spacing.md)

            Rectangle()
                .fill(Color.roseLight.opacity(0.5))
                .frame(height: 1)
                .padding(.horizontal, Spacing.sm)

            activitySection
        }
    }

    @ViewBuilder
    private var countdownSection: some View {
        if let reunionDate = entry.reunionDate {
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)

            if countdown.isPast {
                HStack {
                    VStack(spacing: Spacing.sm) {
                        Image("mascot-hug")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 48, height: 48)
                        Text("Together right now")
                            .font(.custom("PlayfairDisplay-Bold", size: 17))
                            .foregroundStyle(Color.rose)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, Spacing.sm)
            } else {
                HStack {
                    VStack(spacing: Spacing.xs) {
                        Text("\(countdown.days)")
                            .font(.custom("PlayfairDisplay-Bold", size: 52))
                            .foregroundStyle(Color.gold)

                        Text("days \u{2022} \(countdown.hours)h \(countdown.minutes)m")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.inkSoft)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: Spacing.sm) {
                        Text(CountdownTaglines.tagline(for: entry.date))
                            .font(.custom("PlayfairDisplay-Italic", size: 15))
                            .foregroundStyle(Color.inkSoft)
                            .multilineTextAlignment(.center)

                        Image("mascot-hug")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 36, height: 36)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, Spacing.sm)
            }
        } else {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "heart.circle")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.rose.opacity(0.5))
                Text("Set a reunion date")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
            }
            .padding(.vertical, Spacing.xl)
        }
    }

    private func timeUnit(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.inkFaint)
                .textCase(.uppercase)
                .kerning(0.5)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Recent")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkFaint)
                Spacer()
            }
            .padding(.top, Spacing.md)

            if entry.recentActivity.isEmpty && entry.latestPhoto == nil {
                emptyActivity
            } else {
                activityList
            }

            Spacer(minLength: 0)
        }
    }

    private var emptyActivity: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "hand.tap")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.5))

            Text("Send a tap or photo to see it here")
                .font(.system(size: 12))
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activityList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let photo = entry.latestPhoto {
                HStack(spacing: Spacing.sm) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New moment")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.ink)

                        if let meta = entry.latestPhotoMeta {
                            Text(meta.timestamp, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.inkFaint)
                        }
                    }

                    Spacer()

                    Image(systemName: "camera.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.rose.opacity(0.6))
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
            }

            ForEach(Array(entry.recentActivity.prefix(entry.latestPhoto != nil ? 3 : 4).enumerated()), id: \.offset) { _, item in
                activityRow(item)
            }
        }
    }

    private func activityRow(_ item: SharedActivityItem) -> some View {
        HStack(spacing: Spacing.sm) {
            switch item.kind {
            case .tap:
                Text(item.emoji ?? "💕")
                    .font(.system(size: 18))
                    .frame(width: 28, height: 28)
            case .photo:
                Image(systemName: "photo.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.rose)
                    .frame(width: 28, height: 28)
            case .note:
                Text("💌")
                    .font(.system(size: 18))
                    .frame(width: 28, height: 28)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(activityLabel(item))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(item.timestamp, style: .relative)
                    .font(.system(size: 9))
                    .foregroundStyle(Color.inkFaint)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, Spacing.lg)
    }

    private func activityLabel(_ item: SharedActivityItem) -> String {
        switch item.kind {
        case .tap:
            return "\(item.senderName) sent a tap"
        case .photo:
            if let caption = item.caption, !caption.isEmpty {
                return "\(item.senderName): \(caption)"
            }
            return "\(item.senderName) sent a photo"
        case .note:
            if let caption = item.caption, !caption.isEmpty {
                return "\(item.senderName): \(caption)"
            }
            return "\(item.senderName) sent a note"
        }
    }
}

// MARK: - Widget Entry View

struct CountdownWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: CountdownEntry

    var body: some View {
        switch family {
        case .systemLarge:
            CountdownLargeView(entry: entry)
        case .systemMedium:
            CountdownMediumView(entry: entry)
        default:
            CountdownSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct CountdownWidget: Widget {
    let kind = "CountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountdownProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.cream
                }
                .widgetURL(URL(string: "sweetie://home"))
        }
        .configurationDisplayName("Together Countdown")
        .description("Counting every moment until you're together")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
