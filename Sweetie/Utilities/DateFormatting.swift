import Foundation

enum DateFormatting {
    private static nonisolated(unsafe) let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static nonisolated(unsafe) let iso8601NoFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// DateFormatter fallback for `+00:00` offset format that ISO8601DateFormatter
    /// sometimes fails to parse (PostgREST returns this format for timestamptz).
    private static let offsetFallback: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssxxx"
        return formatter
    }()

    private static let offsetFallbackFractional: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSxxx"
        return formatter
    }()

    /// Parse any ISO 8601 date string PostgREST might return.
    /// Handles: `Z` suffix, `+00:00` offset, with/without fractional seconds.
    static func parse(_ dateString: String) -> Date? {
        iso8601.date(from: dateString)
            ?? iso8601NoFraction.date(from: dateString)
            ?? offsetFallbackFractional.date(from: dateString)
            ?? offsetFallback.date(from: dateString)
    }

    static func iso8601String(from date: Date) -> String {
        iso8601.string(from: date)
    }

    static func relativeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    static func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    static func shortTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
