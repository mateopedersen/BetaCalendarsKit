# Deterministic fixtures

`CalendarFixture.month(year:month:)` and `CalendarFixture.year(_:)` produce Codable models using explicit values. `deterministicJSON()` sorts object keys and writes no current timestamp, random identifier, host name, or machine path. Identical requests using the same encoder configuration produce identical bytes.
