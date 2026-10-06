import Foundation

/// Row count policy for a month grid.
public enum MonthLayout: String, Codable, Sendable {
    /// Use the smallest complete number of weeks, four through six.
    case compact
    /// Always use six rows and 42 weekday positions.
    case fixedSixWeeks
}

/// How cells outside the requested month are represented.
public enum OverflowPolicy: String, Codable, Sendable {
    /// Include the adjacent Gregorian day value.
    case includeAdjacentMonths
    /// Keep the cell position but set its day to `nil`.
    case placeholder
    /// Omit adjacent cells in compact layouts. Fixed six-week layouts retain placeholder positions.
    case omit
}

/// One weekday position in a month grid.
public struct CalendarCell: Hashable, Codable, Sendable {
    /// Day value, or `nil` for an adjacent-month placeholder.
    public let day: CalendarDay?
    /// Zero-based row in the visual grid.
    public let row: Int
    /// Zero-based weekday column.
    public let column: Int
    /// Weekday represented by this position.
    public let weekday: Weekday
    /// Whether this position belongs to the requested month.
    public let isInRequestedMonth: Bool
    /// Whether the day is Saturday or Sunday.
    public let isWeekend: Bool
    /// Week number under the configured first-week rules.
    public let weekOfYear: Int
    /// Week-based year under the configured first-week rules.
    public let weekBasedYear: Int
}

/// A deterministic month grid for a Gregorian civil month.
public struct MonthGrid: Hashable, Codable, Sendable {
    /// Month represented by this grid.
    public let month: MonthCoordinate
    /// Display row policy.
    public let layout: MonthLayout
    /// Adjacent-month behavior.
    public let overflow: OverflowPolicy
    /// First weekday column.
    public let firstWeekday: Weekday
    /// Cells in row-major order.
    public let cells: [CalendarCell]

    /// Builds a grid without converting civil days through local midnight.
    public init(
        year: Int,
        month: Int,
        context: CalendarContext = CalendarContext(),
        layout: MonthLayout = .compact,
        overflow: OverflowPolicy = .includeAdjacentMonths
    ) throws {
        guard context.supportsGregorianGrids else { throw CalendarError.unsupportedCalendar }
        let coordinate = try MonthCoordinate(year: year, month: month)
        let first = try CalendarDay(year: year, month: month, day: 1)
        let days = coordinate.dayCount
        let leading = (first.weekday.rawValue - context.firstWeekday.rawValue + 7) % 7
        let naturalCount = ((leading + days + 6) / 7) * 7
        let cellCount = layout == .fixedSixWeeks ? 42 : naturalCount
        var generated: [CalendarCell] = []
        generated.reserveCapacity(cellCount)

        var weekCalendar = context.calendar
        weekCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        for index in 0..<cellCount {
            let dayOffset = index - leading
            let inMonth = (0..<days).contains(dayOffset)
            if overflow == .omit, layout == .compact, !inMonth { continue }
            let representedDay = try first.adding(days: dayOffset)
            let weekday = Weekday(rawValue: ((context.firstWeekday.rawValue - 1 + index % 7) % 7) + 1)!
            let date = Self.utcNoon(for: representedDay)
            let components = weekCalendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
            let includesDate = inMonth || overflow == .includeAdjacentMonths
            generated.append(
                CalendarCell(
                    day: includesDate ? representedDay : nil,
                    row: index / 7,
                    column: index % 7,
                    weekday: weekday,
                    isInRequestedMonth: inMonth,
                    isWeekend: weekday.isWeekend,
                    weekOfYear: components.weekOfYear ?? 0,
                    weekBasedYear: components.yearForWeekOfYear ?? representedDay.year
                ))
        }

        self.month = coordinate
        self.layout = layout
        self.overflow = overflow
        self.firstWeekday = context.firstWeekday
        self.cells = generated
    }

    /// Number of rows represented by this grid.
    public var rowCount: Int { layout == .fixedSixWeeks ? 6 : (cells.map(\.row).max().map { $0 + 1 } ?? 0) }

    /// Row-major groups, preserving omitted-cell coordinates in each cell.
    public var weeks: [[CalendarCell]] {
        guard rowCount > 0 else { return [] }
        return (0..<rowCount).map { row in cells.filter { $0.row == row } }
    }

    /// Exactly the requested month's Gregorian days, in order.
    public var inMonthDays: [CalendarDay] { cells.compactMap { $0.isInRequestedMonth ? $0.day : nil } }

    private static func utcNoon(for day: CalendarDay) -> Date {
        CalendarDay.utcNoon(day)
    }
}

/// Twelve chronologically ordered month grids for a Gregorian year.
public struct YearGrid: Hashable, Codable, Sendable {
    /// Gregorian year.
    public let year: Int
    /// Month grids from January through December.
    public let months: [MonthGrid]

    /// Builds all twelve month grids with shared layout and week conventions.
    public init(
        year: Int,
        context: CalendarContext = CalendarContext(),
        monthLayout: MonthLayout = .compact,
        overflow: OverflowPolicy = .includeAdjacentMonths
    ) throws {
        guard (1...9999).contains(year) else { throw CalendarError.invalidDate }
        self.year = year
        self.months = try (1...12).map {
            try MonthGrid(year: year, month: $0, context: context, layout: monthLayout, overflow: overflow)
        }
    }
}
