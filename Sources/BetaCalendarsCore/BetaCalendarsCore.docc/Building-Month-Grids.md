# Building month grids

Create a `MonthGrid` with a Gregorian year and month, an explicit `CalendarContext`, a row layout, and an overflow policy.

```swift
let grid = try MonthGrid(
    year: 2027,
    month: 1,
    context: CalendarContext(firstWeekday: .monday),
    layout: .fixedSixWeeks,
    overflow: .placeholder
)
assert(grid.cells.count == 42)
```

Cells are row-major and preserve their row and weekday column. A compact grid uses four to six rows. A fixed grid always has six rows and 42 positions. The `.omit` policy removes adjacent dates from compact grids; fixed grids retain empty positions so their shape remains invariant.
