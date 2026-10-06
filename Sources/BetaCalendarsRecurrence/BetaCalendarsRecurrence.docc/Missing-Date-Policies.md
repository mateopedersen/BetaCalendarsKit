# Missing-date policies

Monthly and annual dates can be absent, such as day 31 in February or February 29 in a common year. Select an explicit `MissingDatePolicy`:

- `.skip` leaves out that occurrence.
- `.clampToLastDay` uses the last valid date or weekday occurrence in the period.
- `.error` throws `CalendarError.missingRecurrenceDate` when the absent date is encountered.

There is no implicit default that silently changes the requested day.
