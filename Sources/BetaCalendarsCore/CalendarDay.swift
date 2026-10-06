import Foundation

/// A Gregorian civil date, independent of any time zone or time of day.
///
/// `Date` is an absolute instant; `CalendarDay` is a date on a civil calendar.
/// Its arithmetic therefore remains stable across daylight-saving transitions.
public struct CalendarDay: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    /// Gregorian year in the range 1...9999.
    public let year: Int
    /// Gregorian month in the range 1...12.
    public let month: Int
    /// Day of the month.
    public let day: Int

    /// Creates and validates a Gregorian civil date.
    public init(year: Int, month: Int, day: Int) throws {
        guard (1...9999).contains(year), (1...12).contains(month), (1...Self.daysInMonth(year: year, month: month)).contains(day) else {
            throw CalendarError.invalidDate
        }
        self.year = year
        self.month = month
        self.day = day
    }

    /// ISO 8601 `yyyy-MM-dd` representation.
    public var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    /// Gregorian weekday calculated independently of time zone.
    public var weekday: Weekday {
        // Gregorian 0001-01-01 was a Monday (Foundation weekday number 2).
        Weekday(rawValue: (ordinal + 1) % 7 + 1)!
    }

    /// Gregorian day count since 1970-01-01, useful for deterministic offsets.
    public var ordinal: Int { Self.daysBeforeYear(year) + Self.daysBeforeMonth(year: year, month: month) + day - 1 }

    /// Converts an absolute instant to its Gregorian civil date in the given context.
    public init(date: Date, in context: CalendarContext) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.timeZone
        let values = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = values.year ?? 1
        self.month = values.month ?? 1
        self.day = values.day ?? 1
    }

    /// Returns a local noon instant, or `nil` when that civil date did not exist locally.
    public func noon(in context: CalendarContext) -> Date? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.timeZone
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = context.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let date = calendar.date(from: components) else { return nil }
        let roundTrip = calendar.dateComponents([.year, .month, .day], from: date)
        guard roundTrip.year == year, roundTrip.month == month, roundTrip.day == day else { return nil }
        return date
    }

    /// Returns the first instant in this local civil day, if the day existed.
    public func startOfDay(in context: CalendarContext) -> Date? {
        guard let noon = noon(in: context) else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = context.timeZone
        return calendar.startOfDay(for: noon)
    }

    /// Adds a signed number of Gregorian civil days without using local midnight arithmetic.
    public func adding(days offset: Int) throws -> CalendarDay {
        let target = ordinal.addingReportingOverflow(offset)
        guard !target.overflow else { throw CalendarError.invalidDate }
        return try Self.fromOrdinal(target.partialValue)
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    /// Number of days in a Gregorian month.
    public static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: 31
        case 4, 6, 9, 11: 30
        case 2: isLeapYear(year) ? 29 : 28
        default: 0
        }
    }

    /// Gregorian leap-year rule, including century exceptions.
    public static func isLeapYear(_ year: Int) -> Bool { year.isMultiple(of: 4) && (!year.isMultiple(of: 100) || year.isMultiple(of: 400)) }

    private static func daysBeforeYear(_ year: Int) -> Int {
        let prior = year - 1
        return prior * 365 + prior / 4 - prior / 100 + prior / 400
    }

    private static func daysBeforeMonth(year: Int, month: Int) -> Int {
        (1..<month).reduce(0) { $0 + daysInMonth(year: year, month: $1) }
    }

    private static func fromOrdinal(_ ordinal: Int) throws -> CalendarDay {
        guard ordinal >= 0, ordinal < daysBeforeYear(10_000) else { throw CalendarError.invalidDate }
        var low = 1
        var high = 10_000
        while low + 1 < high {
            let mid = (low + high) / 2
            if daysBeforeYear(mid) <= ordinal { low = mid } else { high = mid }
        }
        var remainder = ordinal - daysBeforeYear(low)
        var month = 1
        while remainder >= daysInMonth(year: low, month: month) {
            remainder -= daysInMonth(year: low, month: month)
            month += 1
        }
        return try CalendarDay(year: low, month: month, day: remainder + 1)
    }

    private enum CodingKeys: String, CodingKey { case year, month, day }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(year: container.decode(Int.self, forKey: .year), month: container.decode(Int.self, forKey: .month), day: container.decode(Int.self, forKey: .day))
    }
}
