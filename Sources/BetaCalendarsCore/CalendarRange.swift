/// A closed, inclusive range of Gregorian civil days.
public struct CalendarRange: Hashable, Codable, Sendable {
    /// First included civil day.
    public let start: CalendarDay
    /// Last included civil day.
    public let end: CalendarDay

    /// Creates an inclusive range and rejects reversed endpoints.
    public init(start: CalendarDay, end: CalendarDay) throws {
        guard start <= end else { throw CalendarError.invalidRange }
        self.start = start
        self.end = end
    }

    /// Number of civil days in the inclusive range.
    public var count: Int { end.ordinal - start.ordinal + 1 }

    /// Whether the range contains a day.
    public func contains(_ day: CalendarDay) -> Bool { start <= day && day <= end }

    private enum CodingKeys: String, CodingKey { case start, end }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            start: container.decode(CalendarDay.self, forKey: .start),
            end: container.decode(CalendarDay.self, forKey: .end))
    }
}

/// A Gregorian year and month in chronological order.
public struct MonthCoordinate: Hashable, Codable, Sendable, Comparable, CustomStringConvertible {
    /// Gregorian year.
    public let year: Int
    /// Gregorian month, 1...12.
    public let month: Int

    /// Creates a validated month coordinate.
    public init(year: Int, month: Int) throws {
        guard (1...9999).contains(year), (1...12).contains(month) else { throw CalendarError.invalidDate }
        self.year = year
        self.month = month
    }

    /// `yyyy-MM` representation.
    public var description: String { String(format: "%04d-%02d", year, month) }

    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.year, lhs.month) < (rhs.year, rhs.month) }

    /// The number of days in this month.
    public var dayCount: Int { CalendarDay.daysInMonth(year: year, month: month) }

    /// Adds or subtracts months while preserving the month coordinate.
    public func adding(months offset: Int) throws -> MonthCoordinate {
        let base = (year - 1) * 12 + month - 1
        let target = base.addingReportingOverflow(offset)
        guard !target.overflow, target.partialValue >= 0, target.partialValue < 9999 * 12 else {
            throw CalendarError.invalidDate
        }
        return try MonthCoordinate(year: target.partialValue / 12 + 1, month: target.partialValue % 12 + 1)
    }

    private enum CodingKeys: String, CodingKey { case year, month }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            year: container.decode(Int.self, forKey: .year), month: container.decode(Int.self, forKey: .month))
    }
}

/// A one-based, ISO-style week coordinate with its week-based year.
public struct WeekCoordinate: Hashable, Codable, Sendable {
    /// Week-based year, which may differ from the civil year near New Year.
    public let year: Int
    /// Week number in the week-based year.
    public let week: Int

    /// Creates a validated week coordinate.
    public init(year: Int, week: Int) throws {
        guard (1...9999).contains(year), (1...53).contains(week) else { throw CalendarError.invalidDate }
        self.year = year
        self.week = week
    }

    private enum CodingKeys: String, CodingKey { case year, week }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(year: container.decode(Int.self, forKey: .year), week: container.decode(Int.self, forKey: .week))
    }
}
