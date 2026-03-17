import Foundation

struct CountdownComponents: Sendable {
    let days: Int
    let hours: Int
    let minutes: Int
    let isPast: Bool

    /// Compute countdown components from now to a reunion date.
    /// If the reunion date is in the past, `isPast` is true and all values are 0.
    static func from(now: Date, to reunionDate: Date) -> CountdownComponents {
        if reunionDate <= now {
            return CountdownComponents(days: 0, hours: 0, minutes: 0, isPast: true)
        }
        let components = Calendar.current.dateComponents(
            [.day, .hour, .minute],
            from: now,
            to: reunionDate
        )
        return CountdownComponents(
            days: max(0, components.day ?? 0),
            hours: max(0, components.hour ?? 0),
            minutes: max(0, components.minute ?? 0),
            isPast: false
        )
    }
}

enum CountdownTaglines {
    private static let lines = [
        "until I hold you again",
        "until we're together",
        "until I see your smile",
        "until our next hello",
        "until home feels like home",
        "until your arms around me",
        "until I hear your laugh",
    ]

    /// Deterministic tagline for a given date — both partners see the same line.
    static func tagline(for date: Date) -> String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        return lines[dayOfYear % lines.count]
    }
}
