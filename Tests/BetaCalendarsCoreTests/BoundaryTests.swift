import BetaCalendarsCore
import Foundation
import Testing

@Test func analyzerFindsYearMonthLeapAndISOWeekYearBoundaries() throws {
    let range = try CalendarRange(start: CalendarDay(year: 2024, month: 12, day: 28), end: CalendarDay(year: 2025, month: 1, day: 5))
    let report = try CalendarBoundaryAnalyzer.analyze(range)
    #expect(report.boundaries.contains { $0.kind == .yearChange && $0.before.description == "2024-12-31" })
    #expect(report.boundaries.contains { $0.kind == .monthChange && $0.after.description == "2025-01-01" })
    #expect(report.boundaries.contains { $0.kind == .isoWeekYearChange })

    let leapRange = try CalendarRange(start: CalendarDay(year: 2024, month: 2, day: 28), end: CalendarDay(year: 2024, month: 3, day: 1))
    let leap = try CalendarBoundaryAnalyzer.analyze(leapRange)
    #expect(leap.boundaries.contains { $0.kind == .leapDayEntry })
    #expect(leap.boundaries.contains { $0.kind == .leapDayExit })
}

@Test func analyzerDetectsDaylightSavingGapAndOverlap() throws {
    let range = try CalendarRange(start: CalendarDay(year: 2024, month: 1, day: 1), end: CalendarDay(year: 2024, month: 12, day: 31))
    for identifier in ["Europe/Oslo", "America/New_York"] {
        let context = CalendarContext(timeZone: TimeZone(identifier: identifier)!)
        let changes = try CalendarBoundaryAnalyzer.analyze(range, context: context).timeZoneTransitions
        #expect(changes.count == 2)
        #expect(changes.map(\.change).contains(.gap))
        #expect(changes.map(\.change).contains(.overlap))
    }
}

@Test func calendarValuesRoundTripThroughCodable() throws {
    let day = try CalendarDay(year: 2028, month: 2, day: 29)
    let data = try JSONEncoder().encode(day)
    #expect(try JSONDecoder().decode(CalendarDay.self, from: data) == day)
    let grid = try MonthGrid(year: 2027, month: 1, layout: .fixedSixWeeks)
    let gridData = try JSONEncoder().encode(grid)
    #expect(try JSONDecoder().decode(MonthGrid.self, from: gridData) == grid)
}
