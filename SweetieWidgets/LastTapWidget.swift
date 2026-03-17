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
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LastTapEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadEntry() -> LastTapEntry {
        let manager = SharedDataManager.shared
        let tapData = manager.loadLastTap()
        let partnerName = manager.loadPartnerName()
        return LastTapEntry(date: .now, tapData: tapData, partnerName: partnerName)
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

                VStack(spacing: 3) {
                    Text(tap.senderName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ink)

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

// MARK: - Widget Definition

struct LastTapWidget: Widget {
    let kind = "LastTapWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LastTapProvider()) { entry in
            LastTapSmallView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.cream
                }
        }
        .configurationDisplayName("Sweetie Taps")
        .description("Last tap from your partner")
        .supportedFamilies([.systemSmall])
    }
}
