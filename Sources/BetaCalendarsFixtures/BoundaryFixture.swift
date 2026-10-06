import BetaCalendarsCore
import Foundation

/// A Gregorian leap-year assertion for a boundary fixture matrix.
public struct LeapYearFixture: Codable, Hashable, Sendable {
    /// Gregorian year under test.
    public let year: Int
    /// Expected status in the standard Gregorian calendar.
    public let isLeapYear: Bool
}

/// Reusable deterministic boundary scenarios for calendar and date software.
public enum BoundaryFixture {
    /// Century and non-century leap-year cases required by Gregorian rules.
    public static let leapYears: [LeapYearFixture] = [
        LeapYearFixture(year: 1900, isLeapYear: false),
        LeapYearFixture(year: 2000, isLeapYear: true),
        LeapYearFixture(year: 2024, isLeapYear: true),
        LeapYearFixture(year: 2027, isLeapYear: false),
        LeapYearFixture(year: 2028, isLeapYear: true),
        LeapYearFixture(year: 2100, isLeapYear: false),
        LeapYearFixture(year: 2400, isLeapYear: true),
    ]

    /// Boundary reports around each ISO week-year transition in the given years.
    public static func isoWeekTransitions(years: [Int]) throws -> [BoundaryReport] {
        try years.map { year in
            let range = try CalendarRange(
                start: CalendarDay(year: year, month: 12, day: 27),
                end: CalendarDay(year: year + 1, month: 1, day: 5)
            )
            return try CalendarBoundaryAnalyzer.analyze(range)
        }
    }

    /// Daylight-saving gap/overlap fixtures for a named time zone and inclusive years.
    public static func daylightSaving(
        timeZoneIdentifier: String,
        years: ClosedRange<Int>
    ) throws -> [BoundaryReport] {
        guard let zone = TimeZone(identifier: timeZoneIdentifier) else { throw CalendarError.invalidDate }
        let context = CalendarContext(timeZone: zone)
        return try years.map { year in
            let range = try CalendarRange(
                start: CalendarDay(year: year, month: 1, day: 1),
                end: CalendarDay(year: year, month: 12, day: 31)
            )
            return try CalendarBoundaryAnalyzer.analyze(range, context: context)
        }
    }
}
