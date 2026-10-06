import Foundation

/// Explicit locale, time-zone, and week conventions for calendar operations.
///
/// Calendar calculations never consult `Calendar.current`. The current 1.0 release
/// supports Gregorian and ISO 8601 identifiers for grid generation.
public struct CalendarContext: Sendable {
    /// The Foundation calendar system. Grid generation supports `.gregorian` and `.iso8601`.
    public let identifier: Calendar.Identifier
    /// Time zone used only when converting a civil day to an instant or analyzing transitions.
    public let timeZone: TimeZone
    /// Locale used by callers when formatting labels; the core does not format dates.
    public let locale: Locale
    /// First column in a week grid.
    public let firstWeekday: Weekday
    /// Minimum number of days required in the first week of a year, clamped to 1...7.
    public let minimumDaysInFirstWeek: Int

    /// Creates a fully explicit calendar context.
    public init(
        identifier: Calendar.Identifier = .gregorian,
        timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!,
        locale: Locale = Locale(identifier: "en_US_POSIX"),
        firstWeekday: Weekday = .monday,
        minimumDaysInFirstWeek: Int = 4
    ) {
        self.identifier = identifier
        self.timeZone = timeZone
        self.locale = locale
        self.firstWeekday = firstWeekday
        self.minimumDaysInFirstWeek = min(max(minimumDaysInFirstWeek, 1), 7)
    }

    /// A new Foundation calendar configured with this context's values.
    public var calendar: Calendar {
        var result = Calendar(identifier: identifier)
        result.timeZone = timeZone
        result.locale = locale
        result.firstWeekday = firstWeekday.rawValue
        result.minimumDaysInFirstWeek = minimumDaysInFirstWeek
        return result
    }

    /// Whether this context can be used with Gregorian civil-day grids.
    public var supportsGregorianGrids: Bool { identifier == .gregorian || identifier == .iso8601 }
}
