import BetaCalendarsCore
import BetaCalendarsFixtures
import BetaCalendarsRecurrence
import Foundation

@main
enum BetaCalCLI {
    static func main() {
        do {
            try run(Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(Data("betacal: \(error)\n\(usage)\n".utf8))
            Foundation.exit(EXIT_FAILURE)
        }
    }

    private static let usage =
        "Usage: betacal month YEAR MONTH [--week-start DAY] [--format text|json] | year YEAR [--format text|json] | boundaries YEAR [--format text|json] | recurrence --from YYYY-MM-DD --through YYYY-MM-DD --weekday DAY [--format text|json] | fixture year YEAR [--format text|json]"

    private static func run(_ args: [String]) throws {
        guard let command = args.first else { throw CLIError.usage }
        switch command {
        case "month":
            guard args.count >= 3, let year = Int(args[1]), let month = Int(args[2]) else { throw CLIError.usage }
            let weekday = try parsedWeekday(args)
            let format = try parsedFormat(args)
            let grid = try MonthGrid(
                year: year, month: month, context: CalendarContext(firstWeekday: weekday), layout: .fixedSixWeeks)
            if format == .json { try emitJSON(grid) } else { printMonth(grid) }
        case "year":
            guard args.count >= 2, let year = Int(args[1]) else { throw CLIError.usage }
            let grid = try YearGrid(year: year, monthLayout: .fixedSixWeeks)
            if try parsedFormat(args) == .json {
                try emitJSON(grid)
            } else {
                for month in grid.months {
                    printMonth(month)
                    print()
                }
            }
        case "boundaries":
            guard args.count >= 2, let year = Int(args[1]), (1...9999).contains(year) else { throw CLIError.usage }
            let endYear = min(year, 9999)
            let range = try CalendarRange(
                start: CalendarDay(year: year, month: 1, day: 1), end: CalendarDay(year: endYear, month: 12, day: 31))
            let report = try CalendarBoundaryAnalyzer.analyze(range)
            if try parsedFormat(args) == .json {
                try emitJSON(report)
            } else {
                for boundary in report.boundaries {
                    print("\(boundary.kind.rawValue): \(boundary.before) → \(boundary.after)")
                }
                if report.boundaries.isEmpty { print("No boundaries found.") }
            }
        case "recurrence":
            let from = try parseDay(requiredOption("--from", in: args))
            let through = try parseDay(requiredOption("--through", in: args))
            guard let weekday = Weekday(name: try requiredOption("--weekday", in: args)) else { throw CLIError.usage }
            let range = try CalendarRange(start: from, end: through)
            let dates = try RecurrenceRule.weekly(weekday: weekday).occurrences(in: range)
            if try parsedFormat(args) == .json {
                try emitJSON(dates)
            } else {
                for date in dates {
                    print(date.description)
                }
            }
        case "fixture":
            guard args.count >= 3, args[1] == "year", let year = Int(args[2]) else { throw CLIError.usage }
            let fixture = try CalendarFixture.year(year)
            if try parsedFormat(args) == .json {
                FileHandle.standardOutput.write(try fixture.deterministicJSON())
                print()
            } else {
                print(fixture.name)
            }
        default:
            throw CLIError.usage
        }
    }

    private static func printMonth(_ grid: MonthGrid) {
        print("\(grid.month)")
        let headers = (0..<7).map { offset in
            Weekday(rawValue: ((grid.firstWeekday.rawValue - 1 + offset) % 7) + 1)!.description.prefix(2).capitalized
        }
        print(headers.joined(separator: " "))
        for row in grid.weeks {
            print(
                row.map { cell in
                    guard let day = cell.day else { return "  " }
                    return String(format: "%2d", day.day)
                }.joined(separator: " "))
        }
    }

    private static func emitJSON<T: Encodable>(_ value: T) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        FileHandle.standardOutput.write(try encoder.encode(value))
        print()
    }

    private static func optionValue(_ name: String, in args: [String]) -> String? {
        guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }

    private static func parsedWeekday(_ args: [String]) throws -> Weekday {
        guard let value = optionValue("--week-start", in: args) else { return .monday }
        guard let weekday = Weekday(name: value) else { throw CLIError.usage }
        return weekday
    }

    private static func parsedFormat(_ args: [String]) throws -> OutputFormat {
        guard let value = optionValue("--format", in: args) else { return .text }
        guard let format = OutputFormat(rawValue: value) else { throw CLIError.usage }
        return format
    }

    private static func requiredOption(_ name: String, in args: [String]) throws -> String {
        guard let value = optionValue(name, in: args) else { throw CLIError.usage }
        return value
    }

    private static func parseDay(_ value: String) throws -> CalendarDay {
        let pieces = value.split(separator: "-").compactMap { Int($0) }
        guard pieces.count == 3 else { throw CLIError.usage }
        return try CalendarDay(year: pieces[0], month: pieces[1], day: pieces[2])
    }

    private enum CLIError: Error { case usage }
    private enum OutputFormat: String { case text, json }
}
