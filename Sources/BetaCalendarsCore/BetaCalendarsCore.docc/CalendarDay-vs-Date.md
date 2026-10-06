# Civil days and instants

`Date` denotes an absolute instant on the timeline. A `CalendarDay` denotes a Gregorian year, month, and day without a time zone or clock time.

Use `CalendarDay` for grid positions, date ranges, and recurrence. Convert to an instant only when an API needs one, with `noon(in:)` or `startOfDay(in:)` and an explicit `CalendarContext`. A local date skipped by a political time-zone change may have no corresponding instant; the conversion then returns `nil`.

Day arithmetic is based on Gregorian civil ordinals, so adding one day is not equivalent to adding 86,400 seconds to an instant.
