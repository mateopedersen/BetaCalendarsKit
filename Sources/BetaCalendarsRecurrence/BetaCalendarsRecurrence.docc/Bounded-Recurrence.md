# Bounded recurrence

Every rule expands only within an inclusive `CalendarRange`. Expansion returns an array and caps results at 10,000 by default; callers may choose a lower or higher cap. A range and a result cap make work explicit for command-line tools, services, and applications.

Supported rules include weekly weekdays, day intervals, monthly day numbers, nth or final weekdays, and annual month/day values.
