import Foundation

/// A structured kind of calendar boundary.
public enum BoundaryKind: String, Codable, Sendable {
    /// The adjacent civil days have different months.
    case monthChange
    /// The adjacent civil days have different years.
    case yearChange
    /// The second day is February 29.
    case leapDayEntry
    /// The first day is February 29.
    case leapDayExit
    /// The ISO week-based year changes between the adjacent days.
    case isoWeekYearChange
}

/// A transition between two consecutive Gregorian civil days.
public struct CalendarBoundary: Hashable, Codable, Sendable {
    /// Day before the transition.
    public let before: CalendarDay
    /// Day after the transition.
    public let after: CalendarDay
    /// Boundary category.
    public let kind: BoundaryKind
}

/// Daylight-saving transition direction.
public enum DaylightSavingChange: String, Codable, Sendable {
    /// Clocks moved forward and a local-time interval did not occur.
    case gap
    /// Clocks moved backward and a local-time interval occurred twice.
    case overlap
}

/// A real time-zone offset change, represented as an instant and local civil day.
public struct TimeZoneTransition: Hashable, Codable, Sendable {
    /// Transition instant.
    public let instant: Date
    /// Civil day in the supplied time zone.
    public let localDay: CalendarDay
    /// Whether clocks moved forward or backward.
    public let change: DaylightSavingChange
    /// Offset before the transition, in seconds from GMT.
    public let offsetBefore: Int
    /// Offset after the transition, in seconds from GMT.
    public let offsetAfter: Int
}

/// Complete, machine-readable results for a bounded boundary scan.
public struct BoundaryReport: Hashable, Codable, Sendable {
    /// Civil month/year/leap-day/ISO week-year changes.
    public let boundaries: [CalendarBoundary]
    /// Time-zone daylight-saving changes that fall inside the range.
    public let timeZoneTransitions: [TimeZoneTransition]
}

/// Scans a finite civil-day range for calendar and time-zone boundaries.
public enum CalendarBoundaryAnalyzer {
    /// Analyzes adjacent-day semantics and, when present, daylight-saving transitions.
    public static func analyze(_ range: CalendarRange, context: CalendarContext = CalendarContext()) throws
        -> BoundaryReport
    {
        var boundaries: [CalendarBoundary] = []
        let iso = Calendar(identifier: .iso8601)
        var previous = range.start
        if range.count > 1 {
            for offset in 1..<range.count {
                let current = try range.start.adding(days: offset)
                if previous.year != current.year {
                    boundaries.append(CalendarBoundary(before: previous, after: current, kind: .yearChange))
                }
                if previous.month != current.month {
                    boundaries.append(CalendarBoundary(before: previous, after: current, kind: .monthChange))
                }
                if current.month == 2 && current.day == 29 {
                    boundaries.append(CalendarBoundary(before: previous, after: current, kind: .leapDayEntry))
                }
                if previous.month == 2 && previous.day == 29 {
                    boundaries.append(CalendarBoundary(before: previous, after: current, kind: .leapDayExit))
                }
                let beforeWeekYear = iso.component(.yearForWeekOfYear, from: Self.utcNoon(previous))
                let currentWeekYear = iso.component(.yearForWeekOfYear, from: Self.utcNoon(current))
                if beforeWeekYear != currentWeekYear {
                    boundaries.append(CalendarBoundary(before: previous, after: current, kind: .isoWeekYearChange))
                }
                previous = current
            }
        }

        let transitions = Self.transitions(in: range, context: context)
        return BoundaryReport(boundaries: boundaries, timeZoneTransitions: transitions)
    }

    private static func transitions(in range: CalendarRange, context: CalendarContext) -> [TimeZoneTransition] {
        guard let first = range.start.startOfDay(in: context) else { return [] }
        let dayAfterEnd = try? range.end.adding(days: 1)
        let end = dayAfterEnd?.noon(in: context) ?? CalendarDay.utcNoon(range.end).addingTimeInterval(86_400)
        var cursor = first.addingTimeInterval(-1)
        var result: [TimeZoneTransition] = []
        while let transition = context.timeZone.nextDaylightSavingTimeTransition(after: cursor), transition < end {
            let before = context.timeZone.secondsFromGMT(for: transition.addingTimeInterval(-1))
            let after = context.timeZone.secondsFromGMT(for: transition)
            if before != after {
                result.append(
                    TimeZoneTransition(
                        instant: transition,
                        localDay: CalendarDay(date: transition, in: context),
                        change: after > before ? .gap : .overlap,
                        offsetBefore: before,
                        offsetAfter: after
                    ))
            }
            cursor = transition.addingTimeInterval(1)
        }
        return result
    }

    private static func utcNoon(_ day: CalendarDay) -> Date { CalendarDay.utcNoon(day) }
}

extension CalendarDay {
    /// UTC noon is a stable Foundation anchor for civil-day calendar metadata.
    static func utcNoon(_ day: CalendarDay) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        let utc = TimeZone(secondsFromGMT: 0)!
        calendar.timeZone = utc
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = utc
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = 12
        return calendar.date(from: components)!
    }
}
