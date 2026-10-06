# Contributing

Thanks for helping improve BetaCalendarsKit.

## Development

Use Swift 6.0 or newer and run:

```sh
swift package dump-package
swift build
swift test
swift format lint --strict --recursive Sources Tests Package.swift
```

Calendar tests must use explicit time zones and week conventions. Avoid `Calendar.current`, current-time assumptions, random values, host-specific paths, network calls, and unbounded recurrence sequences.

## Changes

Keep `CalendarDay` as a civil value, separate from absolute `Date` instants. Document public APIs, add deterministic tests for boundary cases, and update DocC guides when behavior changes. Recurrence changes must specify behavior for dates that do not exist in a month or year.

## Pull requests

Please explain the behavior change and include tests. Do not claim RFC 5545 compatibility or platform support that has not been implemented and built.
