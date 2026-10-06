# Time zones and temporal boundaries

Grid structure is computed from civil Gregorian values. The time zone in `CalendarContext` is used for explicit instant conversion and time-zone transition reporting, not to define month arithmetic.

`CalendarBoundaryAnalyzer` can report year and month changes, leap-day entry and exit, ISO week-year changes, and offset transitions in a named zone. A spring-forward transition is a gap; a fall-back transition is an overlap. Reports contain values and offsets instead of formatted prose.
