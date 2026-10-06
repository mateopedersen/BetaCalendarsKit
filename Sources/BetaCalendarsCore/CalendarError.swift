/// Errors produced while validating or calculating calendar values.
public enum CalendarError: Error, Equatable, Sendable {
    /// A civil date or month is outside the supported Gregorian range.
    case invalidDate
    /// A range ends before it starts.
    case invalidRange
    /// A Foundation calendar other than Gregorian or ISO 8601 was supplied.
    case unsupportedCalendar
    /// A civil date cannot be represented as a local instant in the requested time zone.
    case nonexistentLocalDate
    /// A recurrence requested a date absent from a calendar month or year.
    case missingRecurrenceDate
    /// A bounded recurrence would exceed its requested output cap.
    case occurrenceLimitExceeded
}
