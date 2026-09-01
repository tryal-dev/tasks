# Time Zones and Unix Timestamps

Your Business Central server stores every `DateTime` as UTC, but the world around it does not: the booking API you integrate with speaks Unix timestamps, and the support team wants appointment times shown on the customer's own wall clock — daylight saving included. Hand-rolling time zone rules is a famous way to ship bugs; the System Application already knows them all. Codeunit `"Time Zone"` (`GetTimezoneOffset`, `IsDaylightSavingTime`) answers offset and daylight saving questions for any Windows time zone ID, and codeunit `"Unix Timestamp"` (`CreateTimestampSeconds`, `EvaluateTimestamp`) converts between `DateTime` and Unix seconds. Your job is a small toolkit that puts them to work.

## Requirements

Create a **codeunit** named `"Time Zone Toolkit"` with five public procedures:

```al
procedure GetOffsetText(AtDateTime: DateTime; TimeZoneId: Text): Text
procedure IsDaylightSaving(AtDateTime: DateTime; TimeZoneId: Text): Boolean
procedure ToLocalTime(UtcDateTime: DateTime; TimeZoneId: Text): DateTime
procedure ToUnixSeconds(FromDateTime: DateTime): BigInteger
procedure FromUnixSeconds(UnixSeconds: BigInteger): DateTime
```

Rules:

1. Every `TimeZoneId` you receive is a valid Windows time zone ID such as `W. Europe Standard Time` or `India Standard Time`, and every `DateTime` you receive is a UTC instant with zero milliseconds.
2. `GetOffsetText` returns the zone's offset from UTC at that instant, formatted exactly as a sign, two-digit hours, a colon, and two-digit minutes: `+01:00`, `+05:30`, `-05:00` — and `+00:00` for UTC itself. The sign is always present, and both parts are always two digits.
3. The offset must respect daylight saving time: the same zone can produce different texts for a January instant and a July instant.
4. `IsDaylightSaving` returns whether the instant falls inside the zone's daylight saving period; a zone that never observes daylight saving returns `false` for every instant — don't guess from the month; ask the platform.
5. `ToLocalTime` returns the wall-clock datetime of that UTC instant in the target zone: the input shifted by the zone's offset at that instant.
6. `ToUnixSeconds` returns the Unix timestamp of the datetime in whole seconds — seconds elapsed since 1970-01-01T00:00:00Z.
7. `FromUnixSeconds` is the reverse: the UTC `DateTime` for a Unix seconds value. A datetime sent through `ToUnixSeconds` and back must come out unchanged.

One trap worth naming: the grading server does not run in UTC. `CreateDateTime`, `DT2Date` and `DT2Time` work in the session's time zone, so any epoch arithmetic built on them — an epoch of `CreateDateTime(DMY2Date(1, 1, 1970), 0T)`, say — is off by the local offset, and by a different amount in summer than in winter. That is what the System Application codeunits are for. If you ever need a UTC instant by hand, `Format(DateTime, 0, 9)` renders one as ISO 8601 with a trailing `Z`, and `Evaluate(DateTime, '2025-01-15T12:00:00Z', 9)` reads one back.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The time zone tests use a generated January 2025 instant and a generated July 2025 instant — any day, a whole hour, zero milliseconds — against `W. Europe Standard Time` (a daylight saving zone), expecting `+01:00`/`false` in January and `+02:00`/`true` in July, plus `India Standard Time` (`+05:30`, never daylight saving), `SA Pacific Standard Time` (`-05:00`), and `UTC` (`+00:00`). `ToLocalTime` must return exactly the input shifted by the zone's offset at that instant: one hour (January) or two hours (July) for `W. Europe Standard Time`, five and a half hours for `India Standard Time`. The Unix tests check the known values 1736942400 (2025-01-15T12:00:00Z) and 1752580800 (2025-07-15T12:00:00Z) in both directions, check that two generated datetimes N days apart differ by exactly N × 86400 seconds, and round-trip a generated whole-second datetime. Offset text comparisons are exact — note the sign, the zero-padding, and the colon.

## Learn More

- [Time Zone codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.datetime.time-zone) — the offset and daylight saving API this task is built on.
- [Unix Timestamp codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.datetime.unix-timestamp) — DateTime ↔ Unix seconds without manual epoch math.
- [Duration data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type) — what `GetTimezoneOffset` returns: a 64-bit number of milliseconds you can do arithmetic with.
- [About dates in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-about-dates) — why the server stores UTC and what that means for your code.
