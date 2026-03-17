import WidgetKit
import SwiftUI

struct LatestPhotoEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let senderName: String?
    let caption: String?
    let photoTimestamp: Date?
}

struct LatestPhotoProvider: TimelineProvider {
    func placeholder(in context: Context) -> LatestPhotoEntry {
        LatestPhotoEntry(
            date: .now,
            image: nil,
            senderName: "Love",
            caption: "Missing you",
            photoTimestamp: .now
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LatestPhotoEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LatestPhotoEntry>) -> Void) {
        let entry = loadEntry()
        // Refresh in 1 hour; app-triggered reloads handle real-time updates
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> LatestPhotoEntry {
        let manager = SharedDataManager.shared
        let metadata = manager.loadLatestPhoto()
        let image = manager.loadLatestPhotoImage()

        return LatestPhotoEntry(
            date: .now,
            image: image,
            senderName: metadata?.senderName,
            caption: metadata?.caption,
            photoTimestamp: metadata?.timestamp
        )
    }
}

// MARK: - Small Widget View

struct LatestPhotoSmallView: View {
    let entry: LatestPhotoEntry

    var body: some View {
        if let image = entry.image {
            ZStack(alignment: .bottom) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                // Glass-style overlay bar
                HStack(spacing: Spacing.xs) {
                    Text(entry.senderName ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.ink)

                    Spacer()

                    if let timestamp = entry.photoTimestamp {
                        Text(timestamp, style: .relative)
                            .font(.system(size: 9))
                            .foregroundStyle(Color.inkFaint)
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(.ultraThinMaterial)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image("mascot-peek")
                .resizable()
                .interpolation(.none)
                .frame(width: 40, height: 40)
            Text("No moments yet")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View

struct LatestPhotoMediumView: View {
    let entry: LatestPhotoEntry

    var body: some View {
        if let image = entry.image {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    // Left 60%: photo
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 0.6, height: geo.size.height)
                        .clipped()

                    // Right 40%: details
                    VStack(spacing: Spacing.sm) {
                        Spacer()

                        if let caption = entry.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.custom("PlayfairDisplay-Italic", size: 13))
                                .foregroundStyle(Color.ink)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                        }

                        if let timestamp = entry.photoTimestamp {
                            Text(timestamp, style: .relative)
                                .font(.system(size: 11))
                                .foregroundStyle(Color.inkFaint)
                        }

                        Image(systemName: "heart.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.rose)

                        Spacer()
                    }
                    .padding(.horizontal, Spacing.sm)
                    .frame(width: geo.size.width * 0.4, height: geo.size.height)
                    .background(Color.cream)
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.lg) {
            Image("mascot-peek")
                .resizable()
                .interpolation(.none)
                .frame(width: 40, height: 40)
            VStack(spacing: Spacing.xs) {
                Text("Send your first photo")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
                Text("Open Sweetie to get started")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Entry View

struct LatestPhotoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LatestPhotoEntry

    var body: some View {
        switch family {
        case .systemMedium:
            LatestPhotoMediumView(entry: entry)
        default:
            LatestPhotoSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct LatestPhotoWidget: Widget {
    let kind = "LatestPhotoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LatestPhotoProvider()) { entry in
            LatestPhotoWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.cream, Color.blush],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .widgetURL(URL(string: "sweetie://home"))
        }
        .configurationDisplayName("Moments")
        .description("Your partner's latest photo, always close")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
