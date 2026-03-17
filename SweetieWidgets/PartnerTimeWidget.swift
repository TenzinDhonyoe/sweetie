import WidgetKit
import SwiftUI

struct PartnerTimeEntry: TimelineEntry {
    let date: Date
    let partnerTimezone: String?
    let partnerName: String
}

struct PartnerTimeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PartnerTimeEntry {
        PartnerTimeEntry(date: .now, partnerTimezone: "Asia/Tokyo", partnerName: "Your love")
    }

    func getSnapshot(in context: Context, completion: @escaping (PartnerTimeEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PartnerTimeEntry>) -> Void) {
        // Update every minute to show live partner time
        var entries: [PartnerTimeEntry] = []
        let base = loadEntry()
        let now = Date()

        for minuteOffset in 0..<60 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: now) ?? now
            entries.append(PartnerTimeEntry(
                date: entryDate,
                partnerTimezone: base.partnerTimezone,
                partnerName: base.partnerName
            ))
        }

        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func loadEntry() -> PartnerTimeEntry {
        let manager = SharedDataManager.shared
        return PartnerTimeEntry(
            date: .now,
            partnerTimezone: manager.loadPartnerTimezone(),
            partnerName: manager.loadPartnerName()
        )
    }
}

// MARK: - Inline View (lock screen)

struct PartnerTimeInlineView: View {
    let entry: PartnerTimeEntry

    var body: some View {
        if let tzIdentifier = entry.partnerTimezone,
           let tz = TimeZone(identifier: tzIdentifier) {
            let formatter = {
                let f = DateFormatter()
                f.dateStyle = .none
                f.timeStyle = .short
                f.timeZone = tz
                return f
            }()
            let timeString = formatter.string(from: entry.date)

            // Show city name (last component of timezone identifier)
            let city = tzIdentifier.split(separator: "/").last.map(String.init) ?? tzIdentifier
            Text("\(Image(systemName: "heart.fill")) \(timeString) in \(city)")
        } else {
            Text("\(Image(systemName: "heart.fill")) Sweetie")
        }
    }
}

// MARK: - Widget Definition

struct PartnerTimeWidget: Widget {
    let kind = "PartnerTimeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PartnerTimeProvider()) { entry in
            PartnerTimeInlineView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Partner's Time")
        .description("See what time it is for your partner")
        .supportedFamilies([.accessoryInline])
    }
}
