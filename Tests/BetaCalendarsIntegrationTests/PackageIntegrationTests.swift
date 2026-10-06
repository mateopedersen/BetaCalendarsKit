import BetaCalendarsCore
import BetaCalendarsFixtures
import BetaCalendarsRecurrence
import Testing

@Test func publicProductsComposeWithoutUIOrNetworking() throws {
    let grid = try MonthGrid(year: 2027, month: 1, layout: .fixedSixWeeks)
    let range = try CalendarRange(start: CalendarDay(year: 2027, month: 1, day: 1), end: CalendarDay(year: 2027, month: 1, day: 31))
    let mondays = try RecurrenceRule.weekly(weekday: .monday).occurrences(in: range)
    let fixture = try CalendarFixture.month(year: 2027, month: 1)
    #expect(grid.cells.count == 42)
    #expect(mondays.allSatisfy { $0.weekday == .monday })
    #expect(fixture.monthGrid?.cells.count == 42)
}
