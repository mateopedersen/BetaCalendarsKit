# BetaCalendarsKit

BetaCalendarsKit is a presentation-neutral Swift toolkit for civil Gregorian dates, deterministic month and year grids, bounded recurrence, temporal-boundary analysis, and reusable test fixtures. It does not draw views or make network requests.

## Why another calendar package?

Calendar UI frameworks solve rendering. BetaCalendarsKit handles the engineering beneath those views: civil dates that are not instants, explicit week conventions, repeatable grid structure, recurrence rules with visible missing-date policies, and diagnostics for calendar and time-zone boundaries.

## Products

- **BetaCalendarsCore** — `CalendarDay`, explicit `CalendarContext`, month/year grids, inclusive date ranges, and boundary analysis.
- **BetaCalendarsRecurrence** — finite recurrence expansion with weekly, monthly, annual, and interval rules.
- **BetaCalendarsFixtures** — stable Codable calendar and boundary fixtures for tests.
- **`betacal`** — a dependency-free command-line interface for grids, boundaries, recurrence, and fixtures.

## Requirements

- Swift 6.0 or newer
- macOS 13, iOS 16, tvOS 16, watchOS 9, or visionOS 1 for Apple platforms
- Foundation on Linux for core calculations

Grid generation currently uses the proleptic Gregorian calendar, with Gregorian and ISO 8601 week conventions. It does not depend on `Calendar.current`.

## Installation

Add the package and product to a SwiftPM manifest:

```swift
.package(
    url: "https://github.com/mateopedersen/BetaCalendarsKit.git",
    from: "1.0.0"
)
```

Then add `BetaCalendarsCore` to the target dependencies.

## Civil day and absolute instant

`Date` describes an instant. `CalendarDay` describes a Gregorian civil date without a time zone or time of day. Its date arithmetic uses integer civil-day offsets, so a daylight-saving transition cannot duplicate or skip a civil date.

```swift
import BetaCalendarsCore
import Foundation

let context = CalendarContext(
    identifier: .gregorian,
    timeZone: TimeZone(secondsFromGMT: 0)!,
    locale: Locale(identifier: "en_US_POSIX"),
    firstWeekday: .monday
)
let grid = try MonthGrid(
    year: 2027,
    month: 1,
    context: context,
    layout: .fixedSixWeeks,
    overflow: .includeAdjacentMonths
)
assert(grid.cells.count == 42)
```

`CalendarDay.noon(in:)` and `startOfDay(in:)` are explicit conversions. A civil date skipped entirely by a time-zone change returns `nil` when it cannot be represented as a local instant.

## Month and year grids

Month grids support compact or fixed six-week layouts, any weekday as the first column, and three overflow policies: include adjacent days, retain empty placeholders, or omit adjacent cells in compact mode. Each cell includes its row, column, weekday, weekend status, requested-month membership, and week metadata.

`YearGrid` builds January through December using the same conventions. The grid model is presentation-neutral and can be mapped into SwiftUI, UIKit, AppKit, server-rendered HTML, or another interface.

## Recurrence

Recurrence expansion always requires an inclusive `CalendarRange`; no infinite sequence is exposed. Rules include weekly days, monthly day numbers, ordinal or final weekdays, annual dates, and day intervals.

For a missing date such as the 31st in February, choose `.skip`, `.clampToLastDay`, or `.error`. Results are capped by default at 10,000 occurrences.

```swift
import BetaCalendarsCore
import BetaCalendarsRecurrence

let range = try CalendarRange(
    start: CalendarDay(year: 2027, month: 1, day: 1),
    end: CalendarDay(year: 2027, month: 12, day: 31)
)
let dates = try RecurrenceRule.nthWeekday(
    ordinal: 1,
    weekday: .monday,
    policy: .error
).occurrences(in: range)
```

These typed rules are not an RFC 5545 parser and do not claim iCalendar compatibility.

## Boundary analysis

`CalendarBoundaryAnalyzer` returns structured month changes, year changes, leap-day entry/exit, ISO week-year changes, and time-zone offset transitions. DST transitions are reported as gaps or overlaps with their local civil day and before/after offsets.

## Fixtures

`CalendarFixture` creates Codable month and year records. `BoundaryFixture` supplies Gregorian century cases, ISO week-year reports, and DST scenarios for named time zones. `deterministicJSON()` uses sorted object keys and excludes current time, random IDs, hostnames, and local paths.

## CLI

```sh
swift run betacal month 2027 1 --week-start monday
swift run betacal month 2027 1 --format json
swift run betacal year 2027
swift run betacal boundaries 2027 --format json
swift run betacal recurrence --from 2027-01-01 --through 2027-12-31 --weekday monday
swift run betacal fixture year 2027 --format json
```

The executable uses only the package's own products and Foundation.

## Concurrency and platform support

Public models are value types and `Sendable`. The package has no mutable global state, formatter cache, UI framework import, runtime dependency, telemetry, or network access. Core algorithms are Foundation-based and are built on macOS and Linux in CI. Platform compatibility on the Swift Package Index is reported only after its own builds complete.

## Documentation

DocC catalogs are included for Core, Recurrence, and Fixtures. The Swift Package Index configuration asks SPI to generate and host documentation for all three modules.

## Testing

```sh
swift package dump-package
swift build
swift test
```

The tests cover all seven week starts, all months from 1900 through 2100, Gregorian leap-century behavior, overflow policies, ISO week-year transitions, Oslo/New York daylight-saving changes, recurrence policies, and deterministic fixture encoding.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Calendar changes should preserve civil-date semantics and add deterministic tests for boundary cases.

## Security

See [SECURITY.md](SECURITY.md). All calculations run locally; the package performs no network access.

## License

MIT. See [LICENSE](LICENSE).

## Project

BetaCalendarsKit is maintained by [Beta Calendars](https://www.betacalendars.com/) as part of its developer tooling.
