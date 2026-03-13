import WidgetKit
import SwiftUI

struct CountdownEntry: TimelineEntry {
    let date: Date
    let reunionDate: Date?
    let recentActivity: [SharedActivityItem]
    let latestPhoto: UIImage?
}

struct CountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(
            date: .now,
            reunionDate: Calendar.current.date(byAdding: .day, value: 42, to: .now),
            recentActivity: [],
            latestPhoto: nil
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        let manager = SharedDataManager.shared
        completion(CountdownEntry(
            date: .now,
            reunionDate: manager.loadReunionDate(),
            recentActivity: manager.loadRecentActivity(),
            latestPhoto: manager.loadLatestPhotoImage()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let manager = SharedDataManager.shared
        let reunionDate = manager.loadReunionDate()
        let activity = manager.loadRecentActivity()
        let photo = manager.loadLatestPhotoImage()
        var entries: [CountdownEntry] = []
        let now = Date()

        // Generate an entry every minute for the next hour
        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) ?? .now
            entries.append(CountdownEntry(
                date: entryDate,
                reunionDate: reunionDate,
                recentActivity: activity,
                latestPhoto: photo
            ))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Small Widget View

struct CountdownSmallView: View {
    let entry: CountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let components = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: entry.date,
                to: reunionDate
            )
            let days = max(0, components.day ?? 0)

            VStack(spacing: Spacing.xs) {
                Spacer()

                Text("\(days)")
                    .font(.custom("PlayfairDisplay-Bold", size: 34))
                    .foregroundStyle(Color.gold)

                Text("days")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)

                Text("until I hold you again")
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
        } else {
            noDateView
        }
    }

    private var noDateView: some View {
        VStack(spacing: Spacing.sm) {
            Image("mascot-hug")
                .resizable()
                .interpolation(.none)
                .frame(width: 32, height: 32)
            Text("Set a reunion date")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSoft)
        }
    }
}

// MARK: - Medium Widget View

struct CountdownMediumView: View {
    let entry: CountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let components = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: entry.date,
                to: reunionDate
            )
            let days = max(0, components.day ?? 0)
            let hours = max(0, components.hour ?? 0)
            let minutes = max(0, components.minute ?? 0)

            HStack {
                // Left side: countdown numbers
                VStack(spacing: Spacing.xs) {
                    Text("\(days)")
                        .font(.custom("PlayfairDisplay-Bold", size: 44))
                        .foregroundStyle(Color.gold)

                    Text("days \u{2022} \(hours)h \(minutes)m")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSoft)
                }
                .frame(maxWidth: .infinity)

                // Right side: photo > tap > romantic text
                VStack(spacing: Spacing.sm) {
                    Spacer()

                    if let photo = entry.latestPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        if let photoMeta = SharedDataManager.shared.loadLatestPhoto() {
                            Text(photoMeta.senderName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.ink)

                            Text(photoMeta.timestamp, style: .relative)
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
                        Text("until I hold\nyou again")
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
        } else {
            HStack {
                Image("mascot-hug")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 32, height: 32)
                Text("Set a reunion date in Sweetie")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSoft)
            }
        }
    }
}

// MARK: - Large Widget View

struct CountdownLargeView: View {
    let entry: CountdownEntry

    var body: some View {
        VStack(spacing: 0) {
            // Top section: countdown
            countdownSection
                .padding(.bottom, Spacing.md)

            // Divider
            Rectangle()
                .fill(Color.roseLight.opacity(0.5))
                .frame(height: 1)
                .padding(.horizontal, Spacing.sm)

            // Bottom section: recent activity
            activitySection
        }
    }

    @ViewBuilder
    private var countdownSection: some View {
        if let reunionDate = entry.reunionDate {
            let components = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: entry.date,
                to: reunionDate
            )
            let days = max(0, components.day ?? 0)
            let hours = max(0, components.hour ?? 0)
            let minutes = max(0, components.minute ?? 0)

            HStack {
                VStack(spacing: Spacing.xs) {
                    Text("\(days)")
                        .font(.custom("PlayfairDisplay-Bold", size: 52))
                        .foregroundStyle(Color.gold)

                    Text("days \u{2022} \(hours)h \(minutes)m")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.inkSoft)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.sm) {
                    Text("until I hold you again")
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
        } else {
            HStack {
                Image("mascot-hug")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 36, height: 36)
                Text("Set a reunion date in Sweetie")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.inkSoft)
            }
            .padding(.top, Spacing.lg)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Recent")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.inkFaint)
                    .textCase(.uppercase)
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
            Image("mascot-wave")
                .resizable()
                .interpolation(.none)
                .frame(width: 28, height: 28)

            Text("Send a tap or photo to see it here")
                .font(.system(size: 13))
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var activityList: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Show latest photo thumbnail if available
            if let photo = entry.latestPhoto {
                HStack(spacing: Spacing.sm) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 36, height: 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("New moment")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.ink)

                        if let photoMeta = SharedDataManager.shared.loadLatestPhoto() {
                            Text(photoMeta.timestamp, style: .relative)
                                .font(.system(size: 10))
                                .foregroundStyle(Color.inkFaint)
                        }
                    }

                    Spacer()

                    Image(systemName: "camera.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.rose)
                }
                .padding(Spacing.sm)
                .background(Color.cream.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Show recent taps
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
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(activityLabel(item))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .lineLimit(1)

                Text(item.timestamp, style: .relative)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .padding(.horizontal, Spacing.sm)
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
                    LinearGradient(
                        colors: [Color.cream, Color.blush],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Sweetie Countdown")
        .description("Reunion countdown + recent activity")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
