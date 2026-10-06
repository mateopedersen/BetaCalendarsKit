import BetaCalendarsCore

/// Explicit policy for a recurrence date that does not exist in a month or year.
public enum MissingDatePolicy: String, Codable, Sendable {
    /// Do not produce an occurrence for the missing date.
    case skip
    /// Use the final valid day or matching weekday occurrence in that period.
    case clampToLastDay
    /// Throw `CalendarError.missingRecurrenceDate`.
    case error
}

/// A typed recurrence rule with finite, caller-supplied expansion bounds.
public enum RecurrenceRule: Hashable, Codable, Sendable {
    /// A weekday in every `interval`th calendar week from the range's starting week.
    case weekly(weekday: Weekday, interval: Int = 1)
    /// A day number in every month, with explicit missing-day handling.
    case monthlyDay(day: Int, policy: MissingDatePolicy)
    /// The ordinal occurrence of a weekday in each month (ordinal 1...5).
    case nthWeekday(ordinal: Int, weekday: Weekday, policy: MissingDatePolicy)
    /// The final occurrence of a weekday in each month.
    case lastWeekday(weekday: Weekday)
    /// A month/day in every Gregorian year, with explicit leap-day handling.
    case annual(month: Int, day: Int, policy: MissingDatePolicy)
    /// Every `interval` days from the range start.
    case everyDays(interval: Int)

    /// Expands this rule inside an inclusive range, never returning an unbounded sequence.
    ///
    /// The default result limit protects callers from unexpectedly large ranges.
    public func occurrences(
        in range: CalendarRange,
        context: CalendarContext = CalendarContext(),
        maximumOccurrences: Int = 10_000
    ) throws -> [CalendarDay] {
        guard context.supportsGregorianGrids else { throw CalendarError.unsupportedCalendar }
        guard maximumOccurrences >= 0 else { throw CalendarError.occurrenceLimitExceeded }
        switch self {
        case .weekly(_, let interval), .everyDays(let interval):
            guard interval > 0 else { throw CalendarError.invalidDate }
        case .monthlyDay(let day, _):
            guard (1...31).contains(day) else { throw CalendarError.invalidDate }
        case .nthWeekday(let ordinal, _, _):
            guard (1...5).contains(ordinal) else { throw CalendarError.invalidDate }
        case .annual(let month, let day, _):
            guard (1...12).contains(month), (1...31).contains(day) else { throw CalendarError.invalidDate }
        case .lastWeekday:
            break
        }

        var result: [CalendarDay] = []
        result.reserveCapacity(min(maximumOccurrences, 256))
        for offset in 0..<range.count {
            let current = try range.start.adding(days: offset)
            if try matches(current, range: range, context: context) {
                guard result.count < maximumOccurrences else { throw CalendarError.occurrenceLimitExceeded }
                result.append(current)
            }
        }
        return result
    }

    private func matches(_ day: CalendarDay, range: CalendarRange, context: CalendarContext) throws -> Bool {
        switch self {
        case .weekly(let weekday, let interval):
            guard day.weekday == weekday else { return false }
            let weekStart = day.ordinal - ((day.weekday.rawValue - context.firstWeekday.rawValue + 7) % 7)
            let rangeWeekStart =
                range.start.ordinal - ((range.start.weekday.rawValue - context.firstWeekday.rawValue + 7) % 7)
            return ((weekStart - rangeWeekStart) / 7).isMultiple(of: interval)
        case .everyDays(let interval):
            return ((day.ordinal - range.start.ordinal) % interval) == 0
        case .monthlyDay(let target, let policy):
            let monthLength = CalendarDay.daysInMonth(year: day.year, month: day.month)
            let actual = try Self.resolve(target, maximum: monthLength, policy: policy)
            return day.day == actual
        case .nthWeekday(let ordinal, let weekday, let policy):
            let first = try CalendarDay(year: day.year, month: day.month, day: 1)
            let firstOffset = (weekday.rawValue - first.weekday.rawValue + 7) % 7
            let requested = 1 + firstOffset + (ordinal - 1) * 7
            let maximum = CalendarDay.daysInMonth(year: day.year, month: day.month)
            let actual: Int
            if requested <= maximum {
                actual = requested
            } else {
                switch policy {
                case .skip: return false
                case .clampToLastDay: actual = requested - 7
                case .error: throw CalendarError.missingRecurrenceDate
                }
            }
            return day.day == actual
        case .lastWeekday(let weekday):
            let maximum = CalendarDay.daysInMonth(year: day.year, month: day.month)
            let final = try CalendarDay(year: day.year, month: day.month, day: maximum)
            return day.weekday == weekday && day.day == maximum - ((final.weekday.rawValue - weekday.rawValue + 7) % 7)
        case .annual(let month, let target, let policy):
            guard day.month == month else { return false }
            let actual = try Self.resolve(
                target, maximum: CalendarDay.daysInMonth(year: day.year, month: month), policy: policy)
            return day.day == actual
        }
    }

    private static func resolve(_ requested: Int, maximum: Int, policy: MissingDatePolicy) throws -> Int {
        guard requested > maximum else { return requested }
        switch policy {
        case .skip: return 0
        case .clampToLastDay: return maximum
        case .error: throw CalendarError.missingRecurrenceDate
        }
    }
}
