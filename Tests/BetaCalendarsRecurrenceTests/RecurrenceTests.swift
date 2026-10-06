import BetaCalendarsCore
import BetaCalendarsRecurrence
import Testing

@Test func weeklyRuleIsBoundedAndRespectsWeekStart() throws {
    let range = try CalendarRange(
        start: CalendarDay(year: 2027, month: 1, day: 1), end: CalendarDay(year: 2027, month: 1, day: 31))
    let dates = try RecurrenceRule.weekly(weekday: .monday, interval: 2).occurrences(in: range)
    #expect(dates.allSatisfy { $0.weekday == .monday })
    #expect(dates.count == 2 || dates.count == 3)
    #expect(throws: CalendarError.self) {
        try RecurrenceRule.everyDays(interval: 1).occurrences(in: range, maximumOccurrences: 5)
    }
}

@Test func monthlyDayPoliciesAreExplicit() throws {
    let range = try CalendarRange(
        start: CalendarDay(year: 2027, month: 1, day: 1), end: CalendarDay(year: 2027, month: 3, day: 31))
    let skipped = try RecurrenceRule.monthlyDay(day: 31, policy: .skip).occurrences(in: range)
    #expect(skipped.map(\.description) == ["2027-01-31", "2027-03-31"])
    let clamped = try RecurrenceRule.monthlyDay(day: 31, policy: .clampToLastDay).occurrences(in: range)
    #expect(clamped.map(\.description) == ["2027-01-31", "2027-02-28", "2027-03-31"])
    #expect(throws: CalendarError.self) {
        try RecurrenceRule.monthlyDay(day: 31, policy: .error).occurrences(in: range)
    }
}

@Test func nthLastWeekdayAndAnnualLeapDayRulesWork() throws {
    let quarter = try CalendarRange(
        start: CalendarDay(year: 2027, month: 1, day: 1), end: CalendarDay(year: 2027, month: 3, day: 31))
    let firstMondays = try RecurrenceRule.nthWeekday(ordinal: 1, weekday: .monday, policy: .error).occurrences(
        in: quarter)
    #expect(firstMondays.count == 3)
    #expect(firstMondays.allSatisfy { $0.weekday == .monday && $0.day <= 7 })
    let lastFridays = try RecurrenceRule.lastWeekday(weekday: .friday).occurrences(in: quarter)
    #expect(lastFridays.count == 3)
    #expect(lastFridays.allSatisfy { $0.weekday == .friday })

    let years = try CalendarRange(
        start: CalendarDay(year: 2023, month: 1, day: 1), end: CalendarDay(year: 2025, month: 12, day: 31))
    let leapDays = try RecurrenceRule.annual(month: 2, day: 29, policy: .skip).occurrences(in: years)
    #expect(leapDays.map(\.description) == ["2024-02-29"])
}
