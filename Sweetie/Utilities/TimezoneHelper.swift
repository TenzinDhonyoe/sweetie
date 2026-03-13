import Foundation

enum TimezoneHelper {
    enum TimeOfDay: String {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"
        case sleeping = "Likely sleeping"
    }

    static func timeOfDay(in timezone: String) -> TimeOfDay {
        let hour = currentHour(in: timezone)
        switch hour {
        case 6..<12: return .morning
        case 12..<17: return .afternoon
        case 17..<20: return .evening
        case 20..<23: return .night
        default: return .sleeping
        }
    }

    static func currentHour(in timezone: String) -> Int {
        let tz = TimeZone(identifier: timezone) ?? .current
        let components = Calendar.current.dateComponents(in: tz, from: Date())
        return components.hour ?? 12
    }

    static func formattedTime(in timezone: String) -> String {
        let tz = TimeZone(identifier: timezone) ?? .current
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    static func emoji(for timeOfDay: TimeOfDay) -> String {
        switch timeOfDay {
        case .morning: "☀️"
        case .afternoon: "🌤️"
        case .evening: "🌅"
        case .night: "🌙"
        case .sleeping: "💤"
        }
    }

    static func overlapDescription(
        myTimezone: String,
        mySleep: (start: String, end: String),
        theirTimezone: String,
        theirSleep: (start: String, end: String)
    ) -> String {
        let myTz = TimeZone(identifier: myTimezone) ?? .current
        let theirTz = TimeZone(identifier: theirTimezone) ?? .current

        let myAwake = awakeHours(sleepStart: mySleep.start, sleepEnd: mySleep.end)
        let theirAwake = awakeHours(sleepStart: theirSleep.start, sleepEnd: theirSleep.end)

        let offsetDiff = (theirTz.secondsFromGMT() - myTz.secondsFromGMT()) / 3600
        let theirAwakeInMyTime = theirAwake.map { ($0 - offsetDiff + 24) % 24 }

        var overlapHours: [Int] = []
        for hour in myAwake {
            if theirAwakeInMyTime.contains(hour) {
                overlapHours.append(hour)
            }
        }

        guard !overlapHours.isEmpty else {
            return "No overlap today"
        }

        let sorted = overlapHours.sorted()
        let startHour = sorted.first!
        let endHour = (sorted.last! + 1) % 24

        let startFormatted = formatHour(startHour)
        let endFormatted = formatHour(endHour)

        return "\(overlapHours.count)h overlap (\(startFormatted) – \(endFormatted))"
    }

    private static func awakeHours(sleepStart: String, sleepEnd: String) -> [Int] {
        let startHour = parseTimeString(sleepStart)
        let endHour = parseTimeString(sleepEnd)

        var awake: [Int] = []
        var hour = endHour
        while hour != startHour {
            awake.append(hour)
            hour = (hour + 1) % 24
        }
        return awake
    }

    private static func parseTimeString(_ time: String) -> Int {
        let parts = time.split(separator: ":")
        return Int(parts.first ?? "0") ?? 0
    }

    private static func formatHour(_ hour: Int) -> String {
        let h = hour % 12
        let displayHour = h == 0 ? 12 : h
        let period = hour < 12 ? "AM" : "PM"
        return "\(displayHour) \(period)"
    }
}
