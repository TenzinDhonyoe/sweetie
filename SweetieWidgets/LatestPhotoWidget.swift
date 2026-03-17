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
                // Full bleed photo
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)

                // Bottom gradient overlay for readability
                LinearGradient(
                    colors: [.clear, Color.ink.opacity(0.5)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 60)

                // Info bar
                HStack(spacing: Spacing.xs) {
                    if let name = entry.senderName {
                        Text(name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    if let timestamp = entry.photoTimestamp {
                        Text(timestamp, style: .relative)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.bottom, Spacing.sm)
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "camera")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.4))

            VStack(spacing: 3) {
                Text("No moments yet")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
                Text("Share a photo")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
            }
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
                    // Left: photo fills
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width * 0.55, height: geo.size.height)
                        .clipped()

                    // Right: details
                    VStack(spacing: 0) {
                        Spacer()

                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.rose.opacity(0.5))
                            .padding(.bottom, 8)

                        if let caption = entry.caption, !caption.isEmpty {
                            Text(caption)
                                .font(.custom("PlayfairDisplay-Italic", size: 13))
                                .foregroundStyle(Color.ink)
                                .multilineTextAlignment(.center)
                                .lineLimit(3)
                                .padding(.horizontal, Spacing.sm)
                        }

                        VStack(spacing: 3) {
                            if let name = entry.senderName {
                                Text(name)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(Color.ink)
                            }

                            if let timestamp = entry.photoTimestamp {
                                Text(timestamp, style: .relative)
                                    .font(.system(size: 10))
                                    .foregroundStyle(Color.inkFaint)
                            }
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .frame(width: geo.size.width * 0.45, height: geo.size.height)
                }
            }
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        HStack(spacing: Spacing.lg) {
            Image(systemName: "camera")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.4))

            VStack(alignment: .leading, spacing: 4) {
                Text("Share a moment")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.ink)
                Text("Open Sweetie to send a photo")
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
                    Color.cream
                }
                .widgetURL(URL(string: "sweetie://home"))
        }
        .configurationDisplayName("Moments")
        .description("Your partner's latest photo, always close")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
