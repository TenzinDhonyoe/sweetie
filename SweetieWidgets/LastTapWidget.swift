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
            VStack(spacing: Spacing.sm) {
                Spacer()

                Text(tap.emoji)
                    .font(.system(size: 32))

                Text("\(tap.senderName) sent \u{1F495}")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.inkSoft)
                    .lineLimit(1)

                Text(tap.timestamp, style: .relative)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.inkFaint)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        } else {
            emptyState
        }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.sm) {
            Image("mascot-wave")
                .resizable()
                .interpolation(.none)
                .frame(width: 32, height: 32)
            Text("No taps yet")
                .font(.system(size: 11))
                .foregroundStyle(Color.inkSoft)
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
                    LinearGradient(
                        colors: [Color.cream, Color.rosePale],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .configurationDisplayName("Sweetie Taps")
        .description("Last tap from your partner")
        .supportedFamilies([.systemSmall])
    }
}
