import BetaCalendarsCore
import BetaCalendarsFixtures
import Testing

@Test func fixtureBytesAreDeterministic() throws {
    let first = try CalendarFixture.month(year: 2027, month: 1)
    let second = try CalendarFixture.month(year: 2027, month: 1)
    #expect(try first.deterministicJSON() == second.deterministicJSON())
    #expect(first.name == "month-2027-01")
}

@Test func leapYearMatrixMatchesGregorianCenturyRules() {
    #expect(BoundaryFixture.leapYears.map(\.year) == [1900, 2000, 2024, 2027, 2028, 2100, 2400])
    #expect(BoundaryFixture.leapYears.map(\.isLeapYear) == [false, true, true, false, true, false, true])
}

@Test func yearFixtureContainsTwelveMonths() throws {
    let fixture = try CalendarFixture.year(2028)
    #expect(fixture.yearGrid?.months.count == 12)
    let bytes = try fixture.deterministicJSON()
    #expect(String(decoding: bytes, as: UTF8.self).contains("year-2028"))
}
