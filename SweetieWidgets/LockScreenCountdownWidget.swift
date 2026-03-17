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
        let entry = LockScreenCountdownEntry(date: .now, reunionDate: reunionDate)

        // Lock screen countdown only shows days — refresh at midnight or in 1 hour
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        let refreshDate = min(nextMidnight, nextHour)

        completion(Timeline(entries: [entry], policy: .after(refreshDate)))
    }
}

// MARK: - Inline (single line above time)

struct LockScreenInlineView: View {
    let entry: LockScreenCountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)
            if countdown.isPast {
                Text("\(Image(systemName: "heart.fill")) Together right now")
            } else {
                Text("\(Image(systemName: "heart.fill")) \(countdown.days)d \(CountdownTaglines.tagline(for: entry.date))")
            }
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
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)

            ZStack {
                AccessoryWidgetBackground()

                if countdown.isPast {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                } else {
                    VStack(spacing: 1) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10))

                        Text("\(countdown.days)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))

                        Text("days")
                            .font(.system(size: 8))
                    }
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()

                VStack(spacing: 2) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))
                    Text("Sweetie")
                        .font(.system(size: 7, weight: .medium))
                        .textCase(.uppercase)
                        .kerning(0.5)
                }
            }
        }
    }
}

// MARK: - Rectangular (wider lock screen widget)

struct LockScreenRectangularView: View {
    let entry: LockScreenCountdownEntry

    var body: some View {
        if let reunionDate = entry.reunionDate {
            let countdown = CountdownComponents.from(now: entry.date, to: reunionDate)

            if countdown.isPast {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Together right now")
                            .font(.system(size: 12, weight: .medium))
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
                    VStack(spacing: 0) {
                        Text("\(countdown.days)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))

                        Text("days")
                            .font(.system(size: 9))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("until together")
                            .font(.system(size: 12, weight: .medium))

                        Text("\(countdown.hours)h \(countdown.minutes)m remaining")
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
            }
        } else {
            HStack(spacing: 10) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sweetie")
                        .font(.system(size: 13, weight: .medium))
                    Text("Set a reunion date")
                        .font(.system(size: 10))
                        .opacity(0.6)
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
                .widgetURL(URL(string: "sweetie://home"))
        }
        .configurationDisplayName("Together Countdown")
        .description("Days until you're together")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
