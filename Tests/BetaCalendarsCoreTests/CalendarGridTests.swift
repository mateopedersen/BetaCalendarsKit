import BetaCalendarsCore
import Foundation
import Testing

@Test func fixedSixWeekGridHasFortyTwoCellsForEveryWeekStart() throws {
    for weekday in Weekday.allCases {
        let grid = try MonthGrid(
            year: 2027,
            month: 1,
            context: CalendarContext(firstWeekday: weekday),
            layout: .fixedSixWeeks
        )
        #expect(grid.cells.count == 42)
        #expect(grid.weeks.count == 6)
        #expect(grid.inMonthDays.count == 31)
        #expect(Set(grid.inMonthDays).count == 31)
    }
}

@Test func compactAndOverflowPoliciesPreserveCivilCoordinates() throws {
    let compact = try MonthGrid(year: 2027, month: 1, context: CalendarContext(firstWeekday: .monday))
    #expect((4...6).contains(compact.rowCount))
    #expect(compact.inMonthDays.first == CalendarDay(year: 2027, month: 1, day: 1))

    let placeholders = try MonthGrid(year: 2027, month: 1, overflow: .placeholder)
    #expect(placeholders.cells.count == 42)
    #expect(placeholders.cells.contains { !$0.isInRequestedMonth && $0.day == nil })

    let omitted = try MonthGrid(year: 2027, month: 1, overflow: .omit)
    #expect(omitted.cells.count == 31)
    #expect(omitted.cells.contains { $0.column != 0 })
}

@Test func gregorianLeapRulesAndMonthArithmeticAreExact() throws {
    #expect(!CalendarDay.isLeapYear(1900))
    #expect(CalendarDay.isLeapYear(2000))
    #expect(!CalendarDay.isLeapYear(2100))
    #expect(CalendarDay.isLeapYear(2400))
    #expect(try CalendarDay(year: 2024, month: 2, day: 29).adding(days: 1) == CalendarDay(year: 2024, month: 3, day: 1))
    #expect(try MonthCoordinate(year: 2026, month: 12).adding(months: 1) == MonthCoordinate(year: 2027, month: 1))
}

@Test func yearGridHasTwelveStableMonths() throws {
    let grid = try YearGrid(year: 2028, monthLayout: .fixedSixWeeks)
    #expect(grid.months.count == 12)
    #expect(grid.months.map(\.month.month) == Array(1...12))
    #expect(grid.months[1].inMonthDays.count == 29)
}

@Test func everyGregorianMonthFrom1900Through2100SatisfiesGridInvariants() throws {
    for year in 1900...2100 {
        for month in 1...12 {
            let grid = try MonthGrid(year: year, month: month, context: CalendarContext(firstWeekday: .sunday), layout: .fixedSixWeeks)
            let expectedCount = CalendarDay.daysInMonth(year: year, month: month)
            #expect(grid.cells.count == 42)
            #expect(grid.inMonthDays.count == expectedCount)
            #expect(Set(grid.inMonthDays).count == expectedCount)
            #expect(grid.inMonthDays.first?.day == 1)
            #expect(grid.inMonthDays.last?.day == expectedCount)
            #expect(grid.cells.allSatisfy { (0..<6).contains($0.row) && (0..<7).contains($0.column) })
            let included = grid.cells.compactMap(\.day)
            for pair in zip(included, included.dropFirst()) { #expect(try pair.0.adding(days: 1) == pair.1) }
        }
    }
}

@Test func localDayConversionDoesNotUseMidnightForItsCivilIdentity() throws {
    let zone = TimeZone(identifier: "America/New_York")!
    let context = CalendarContext(timeZone: zone)
    let springDay = try CalendarDay(year: 2024, month: 3, day: 10)
    let fallDay = try CalendarDay(year: 2024, month: 11, day: 3)
    #expect(springDay.noon(in: context) != nil)
    #expect(fallDay.noon(in: context) != nil)
    #expect(springDay.startOfDay(in: context) != nil)

    let springNext = try CalendarDay(year: 2024, month: 3, day: 11)
    let fallNext = try CalendarDay(year: 2024, month: 11, day: 4)
    let springDuration = springNext.startOfDay(in: context)!.timeIntervalSince(springDay.startOfDay(in: context)!)
    let fallDuration = fallNext.startOfDay(in: context)!.timeIntervalSince(fallDay.startOfDay(in: context)!)
    #expect(springDuration == 23 * 60 * 60)
    #expect(fallDuration == 25 * 60 * 60)
}

@Test func politicallySkippedCivilDayHasNoLocalInstantButRemainsAValue() throws {
    let context = CalendarContext(timeZone: TimeZone(identifier: "Pacific/Apia")!)
    let skipped = try CalendarDay(year: 2011, month: 12, day: 30)
    #expect(skipped.description == "2011-12-30")
    #expect(skipped.noon(in: context) == nil)
}

@Test func invalidCivilDatesAndReversedRangesAreRejected() throws {
    #expect(throws: CalendarError.self) { try CalendarDay(year: 1900, month: 2, day: 29) }
    let start = try CalendarDay(year: 2027, month: 1, day: 2)
    let end = try CalendarDay(year: 2027, month: 1, day: 1)
    #expect(throws: CalendarError.self) { try CalendarRange(start: start, end: end) }
}

@Test func unsupportedCalendarIdentifiersFailClearly() throws {
    let context = CalendarContext(identifier: .hebrew)
    #expect(throws: CalendarError.self) { try MonthGrid(year: 2027, month: 1, context: context) }
}
