import WidgetKit
import SwiftUI

struct LockScreenCountdownEntry: TimelineEntry {
    let date: Date
    let reunionDate: Date?
}

struct LockScreenCountdownProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenCountdownEntry {
        LockScreenCountdownEntry(
            date: .now,
            reunionDate: Calendar.current.date(byAdding: .day, value: 42, to: .now)
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (LockScreenCountdownEntry) -> Void) {
        let reunionDate = SharedDataManager.shared.loadReunionDate()
        completion(LockScreenCountdownEntry(date: .now, reunionDate: reunionDate))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenCountdownEntry>) -> Void) {
        let reunionDate = SharedDataManager.shared.loadReunionDate()
        var entries: [LockScreenCountdownEntry] = []
        let now = Date()

        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now)!
            entries.append(LockScreenCountdownEntry(date: entryDate, reunionDate: reunionDate))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Inline (single line above time)

struct LockScreenInlineView: View {
    let entry: LockScreenCountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let days = max(0, Calendar.current.dateComponents([.day], from: entry.date, to: reunionDate).day ?? 0)
            Text("\(Image(systemName: "heart.fill")) \(days)d until together")
        } else {
            Text("\(Image(systemName: "heart.fill")) Sweetie")
        }
    }
}

// MARK: - Circular (small round widget)

struct LockScreenCircularView: View {
    let entry: LockScreenCountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let days = max(0, Calendar.current.dateComponents([.day], from: entry.date, to: reunionDate).day ?? 0)

            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 1) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))

                    Text("\(days)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))

                    Text("days")
                        .font(.system(size: 8))
                        .textCase(.uppercase)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()

                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
            }
        }
    }
}

// MARK: - Rectangular (wider lock screen widget)

struct LockScreenRectangularView: View {
    let entry: LockScreenCountdownEntry

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

            HStack(spacing: 8) {
                VStack(spacing: 0) {
                    Text("\(days)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))

                    Text("days")
                        .font(.system(size: 9))
                        .textCase(.uppercase)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("until together")
                        .font(.system(size: 12, weight: .medium))

                    Text("\(hours)h \(minutes)m remaining")
                        .font(.system(size: 10))
                        .opacity(0.7)

                    HStack(spacing: 2) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 8))
                        Text("Sweetie")
                            .font(.system(size: 9))
                    }
                    .opacity(0.5)
                }
            }
        } else {
            HStack(spacing: 8) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sweetie")
                        .font(.system(size: 12, weight: .medium))
                    Text("Set a reunion date")
                        .font(.system(size: 10))
                        .opacity(0.7)
                }
            }
        }
    }
}

// MARK: - Widget Entry View

struct LockScreenCountdownEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: LockScreenCountdownEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            LockScreenInlineView(entry: entry)
        case .accessoryCircular:
            LockScreenCircularView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularView(entry: entry)
        default:
            LockScreenCircularView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

struct LockScreenCountdownWidget: Widget {
    let kind = "LockScreenCountdownWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LockScreenCountdownProvider()) { entry in
            LockScreenCountdownEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Together Countdown")
        .description("Days until you're together")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
