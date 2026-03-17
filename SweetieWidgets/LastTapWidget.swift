import WidgetKit
import SwiftUI

struct LastTapEntry: TimelineEntry {
    let date: Date
    let tapData: SharedTapData?
    let partnerName: String
}

struct LastTapProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastTapEntry {
        LastTapEntry(date: .now, tapData: nil, partnerName: "Your love")
    }

    func getSnapshot(in context: Context, completion: @escaping (LastTapEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastTapEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> LastTapEntry {
        let manager = SharedDataManager.shared
        return LastTapEntry(
            date: .now,
            tapData: manager.loadLastTap(),
            partnerName: manager.loadPartnerName()
        )
    }
}

// MARK: - Small Widget View

struct LastTapSmallView: View {
    let entry: LastTapEntry

    var body: some View {
        if let tap = entry.tapData {
            VStack(spacing: 6) {
                Spacer()

                // Emoji with subtle ring
                Text(tap.emoji)
                    .font(.system(size: 38))
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.rose.opacity(0.08))
                    )

                Text("\(tap.senderName) sent 💕")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(1)

                    Text(tap.timestamp, style: .relative)
                        .font(.system(size: 10))
                        .foregroundStyle(Color.inkFaint)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "hand.tap")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(Color.rose.opacity(0.4))

            VStack(spacing: 3) {
                Text("No taps yet")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.inkSoft)
                Text("Tap to say hi")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.inkFaint)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget View

struct LastTapMediumView: View {
    let entry: LastTapEntry

    var body: some View {
        if let tap = entry.tapData {
            HStack {
                VStack(spacing: Spacing.sm) {
                    Text(tap.emoji)
                        .font(.system(size: 44))

                    Text(tap.senderName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.ink)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: Spacing.xs) {
                    Spacer()

                    Text("sent a tap")
                        .font(.custom("PlayfairDisplay-Italic", size: 15))
                        .foregroundStyle(Color.inkSoft)

                    Text(tap.timestamp, style: .relative)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.inkFaint)

                    Spacer()

                    HStack {
                        Spacer()
                        Image("mascot-wave")
                            .resizable()
                            .interpolation(.none)
                            .frame(width: 24, height: 24)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        } else {
            HStack(spacing: Spacing.lg) {
                Image("mascot-wave")
                    .resizable()
                    .interpolation(.none)
                    .frame(width: 40, height: 40)
                VStack(spacing: Spacing.xs) {
                    Text("No taps yet")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.inkSoft)
                    Text("Open Sweetie to send one")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.inkFaint)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Widget Entry View

struct LastTapWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LastTapEntry

    var body: some View {
        switch family {
        case .systemMedium:
            LastTapMediumView(entry: entry)
        default:
            LastTapSmallView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct LastTapWidget: Widget {
    let kind = "LastTapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastTapProvider()) { entry in
            LastTapWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.cream
                }
                .widgetURL(URL(string: "sweetie://heart"))
        }
        .configurationDisplayName("Love Taps")
        .description("See when your partner is thinking of you")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
