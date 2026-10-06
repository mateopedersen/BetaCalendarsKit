import Foundation
import BetaCalendarsCore

/// A deterministic, serializable month or year fixture.
public struct CalendarFixture: Codable, Sendable {
    /// Schema revision for fixture consumers.
    public let schemaVersion: Int
    /// Human-readable fixture identity, independent of host paths or time.
    public let name: String
    /// Optional month grid for a month fixture.
    public let monthGrid: MonthGrid?
    /// Optional year grid for a year fixture.
    public let yearGrid: YearGrid?

    /// Creates a month fixture using explicit calendar options.
    public static func month(
        year: Int,
        month: Int,
        context: CalendarContext = CalendarContext(),
        layout: MonthLayout = .fixedSixWeeks,
        overflow: OverflowPolicy = .includeAdjacentMonths
    ) throws -> CalendarFixture {
        let grid = try MonthGrid(year: year, month: month, context: context, layout: layout, overflow: overflow)
        return CalendarFixture(schemaVersion: 1, name: "month-\(grid.month)", monthGrid: grid, yearGrid: nil)
    }

    /// Creates a year fixture with twelve stable, chronological months.
    public static func year(
        _ year: Int,
        context: CalendarContext = CalendarContext(),
        monthLayout: MonthLayout = .fixedSixWeeks
    ) throws -> CalendarFixture {
        let grid = try YearGrid(year: year, context: context, monthLayout: monthLayout)
        return CalendarFixture(schemaVersion: 1, name: "year-\(year)", monthGrid: nil, yearGrid: grid)
    }

    private init(schemaVersion: Int, name: String, monthGrid: MonthGrid?, yearGrid: YearGrid?) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.monthGrid = monthGrid
        self.yearGrid = yearGrid
    }

    /// Encodes the fixture with stable key order and no host-dependent metadata.
    public func deterministicJSON(prettyPrinted: Bool = true) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = prettyPrinted ? [.sortedKeys, .prettyPrinted, .withoutEscapingSlashes] : [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
