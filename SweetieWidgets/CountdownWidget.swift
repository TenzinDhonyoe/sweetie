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
            let hours = max(0, components.hour ?? 0)

            VStack(spacing: 0) {
                Spacer()

                // Heart icon accent
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.rose.opacity(0.6))
                    .padding(.bottom, 6)

                // Big number
                Text("\(days)")
                    .font(.custom("PlayfairDisplay-Bold", size: 48))
                    .foregroundStyle(Color.ink)
                    .contentTransition(.numericText())

                Text("days")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.inkSoft)
                    .textCase(.uppercase)
                    .kerning(1.5)
                    .padding(.top, -4)

                Spacer()

                // Subtle bottom detail
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.rose.opacity(0.4))
                        .frame(width: 4, height: 4)
                    Text("\(hours)h left today")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color.inkFaint)
                }
                .padding(.bottom, 2)
            }
            .frame(maxWidth: .infinity)
        } else {
            noDateView
        }
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
            let components = Calendar.current.dateComponents(
                [.day, .hour, .minute],
                from: entry.date,
                to: reunionDate
            )
            let days = max(0, components.day ?? 0)
            let hours = max(0, components.hour ?? 0)
            let minutes = max(0, components.minute ?? 0)

            HStack(spacing: 0) {
                // Left: countdown
                VStack(spacing: 2) {
                    Spacer()

                    Text("\(days)")
                        .font(.custom("PlayfairDisplay-Bold", size: 56))
                        .foregroundStyle(Color.ink)
                        .contentTransition(.numericText())

                    Text("DAYS")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.inkSoft)
                        .kerning(2)

                    Spacer()

                    // Time chips
                    HStack(spacing: 6) {
                        timeChip(value: hours, unit: "h")
                        timeChip(value: minutes, unit: "m")
                    }
                    .padding(.bottom, 4)
                }
                .frame(maxWidth: .infinity)

                // Divider
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.roseLight.opacity(0.4))
                    .frame(width: 1)
                    .padding(.vertical, Spacing.lg)

                // Right: content
                VStack(spacing: Spacing.sm) {
                    Spacer()

                    if let photo = entry.latestPhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(Color.roseLight.opacity(0.5), lineWidth: 0.5)
                            )

                        if let photoMeta = SharedDataManager.shared.loadLatestPhoto() {
                            Text(photoMeta.senderName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.ink)

                            Text(photoMeta.timestamp, style: .relative)
                                .font(.system(size: 9))
                                .foregroundStyle(Color.inkFaint)
                        }
                    } else if let latestTap = entry.recentActivity.first(where: { $0.kind == .tap }) {
                        Text(latestTap.emoji ?? "💕")
                            .font(.system(size: 32))

                        Text(latestTap.senderName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.ink)

                        Text(latestTap.timestamp, style: .relative)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.inkFaint)
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.rose.opacity(0.4))

                        Text("until I hold\nyou again")
                            .font(.custom("PlayfairDisplay-Italic", size: 14))
                            .foregroundStyle(Color.inkSoft)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity)
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
}

// MARK: - Large Widget View

struct CountdownLargeView: View {
    let entry: CountdownEntry

    var body: some View {
        VStack(spacing: 0) {
            countdownSection
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

            VStack(spacing: 4) {
                Text("\(days)")
                    .font(.custom("PlayfairDisplay-Bold", size: 64))
                    .foregroundStyle(Color.ink)
                    .contentTransition(.numericText())

                Text("DAYS")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.inkSoft)
                    .kerning(3)

                HStack(spacing: 12) {
                    timeUnit(value: hours, label: "hours")
                    Text(":")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color.inkFaint)
                    timeUnit(value: minutes, label: "min")
                }
                .padding(.top, 8)
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.lg)
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
        VStack(alignment: .leading, spacing: 0) {
            // Divider line
            Rectangle()
                .fill(Color.ink.opacity(0.06))
                .frame(height: 1)
                .padding(.horizontal, Spacing.sm)

            // Header
            Text("RECENT")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.inkFaint)
                .kerning(1.5)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                .padding(.bottom, Spacing.sm)

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
        VStack(alignment: .leading, spacing: 2) {
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

                        if let photoMeta = SharedDataManager.shared.loadLatestPhoto() {
                            Text(photoMeta.timestamp, style: .relative)
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
            Group {
                switch item.kind {
                case .tap:
                    Text(item.emoji ?? "💕")
                        .font(.system(size: 16))
                case .photo:
                    Image(systemName: "photo.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.rose.opacity(0.6))
                case .note:
                    Text(item.emoji ?? "💌")
                        .font(.system(size: 16))
                }
            }
            .frame(width: 24, height: 24)

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
            return "\(item.senderName) sent a love note"
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
        }
        .configurationDisplayName("Sweetie Countdown")
        .description("Reunion countdown + recent activity")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
