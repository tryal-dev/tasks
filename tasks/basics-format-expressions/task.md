# Five Faces of One Date

Every printed document your extension produces carries the same posting date in several places: an ISO date in the header, a spelled-out date in the letter body, the weekday next to it, an ISO week key on the picking slip, a clock time on the audit line and a compact stamp inside the PDF file name. The first version used the one-argument `Format(Value)` everywhere, and every server rendered the stamp differently: `2/3/2026` in Chicago, `03-02-2026` in Copenhagen. The three-argument form `Format(Value, 0, FormatString)` fixes that: you compose the output yourself from named fields such as `<Year4>`, `<Month,2>`, `<Day>`, `<Month Text>`, `<Weekday Text>`, `<Week>`, `<Week Year4>`, `<Hours24>` and `<Minutes>`, and every character outside the angle brackets is copied literally.

## Requirements

Create a **codeunit** named `"Document Stamp"` with six public procedures:

```al
procedure IsoDate(Value: Date): Text
procedure PrintedDate(Value: Date): Text
procedure WeekdayName(Value: Date): Text
procedure IsoWeekKey(Value: Date): Text
procedure ClockTime(Value: Time): Text
procedure FileStamp(Value: Date): Text
```

For 3 February 2026 at 09:05:30 the six faces are `2026-02-03`, `3. February 2026`, `Tuesday`, `2026-W06`, `09:05` and `20260203`.

Rules:

1. `IsoDate` renders the four-digit year, a dash, the two-digit month, a dash and the two-digit day. Single-digit months and days are zero-padded: `2026-02-03`, never `2026-2-3`.
2. `PrintedDate` renders the day **without** padding, a full stop, one space, the month's full name, one space and the four-digit year: `3. February 2026`. The month name comes from the session language; the tests run in English (US), so it is `February`, not `Feb` and not `02`.
3. `WeekdayName` renders the full weekday name in the session language: `Tuesday` for 3 February 2026, `Monday` for 29 December 2025.
4. `IsoWeekKey` renders the ISO 8601 week-numbering year, a dash, a capital `W` and the two-digit week: `2026-W06`. ISO weeks run Monday to Sunday and week 1 is the week that contains 4 January, so around New Year the week year differs from the calendar year: 29 December 2025 and 31 December 2024 both belong to week 1 of the following year (`2026-W01` and `2025-W01`), while 1 January 2027 still belongs to `2026-W53`. The platform knows the ISO week; `<Week>` and `<Week Year4>` are the fields that expose it, and `<Year4>` is the wrong year for this face.
5. `ClockTime` renders the 24-hour clock with two-digit hours, a colon and two-digit minutes, and drops the seconds: 9:05:30 becomes `09:05`, 21:07:00 becomes `21:07`. Note the two dead ends: `<Hours12>` turns 21:07 into `09:07`, and a width alone may fill the hour with a space rather than a zero, so ` 9:05` is a possible wrong output. The `<Filler Character,0>` attribute placed right after a field sets its fill character.
6. `FileStamp` renders the four-digit year, two-digit month and two-digit day with no separators at all: `20260203`.
7. A blank date (`0D`) yields an empty string from every date face, and a blank time (`0T`) yields an empty string from `ClockTime`. Never an error. The date faces get this for free — the composed `Format` of `0D` is already empty — but the composed `Format` of `0T` renders `00:00`, so `ClockTime` has to treat the blank time itself.
8. The one-argument `Format(Value)` is the bug you are fixing: its output follows the regional settings of the session. `IsoDate`, `IsoWeekKey`, `ClockTime` and `FileStamp` must produce the same text whatever language the session runs in.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

Every test switches the session to English (US), language ID 1033, before calling your codeunit and compares the returned text character for character, including the padding, the full stop, the single spaces and the capital `W`. Four tests switch to Danish (1030) instead and expect the four faces named in rule 8 to be unchanged there: `IsoDate` of 3 February 2026 is `2026-02-03`, `IsoWeekKey` of 29 December 2025 is `2026-W01`, `ClockTime` of 21:07:00 is `21:07` and `FileStamp` of 3 February 2026 is `20260203`. The fixed dates are 3 February 2026 (a single-digit day and month in week 6), 29 December 2025, 31 December 2024 and 1 January 2027 with the week keys stated in rule 4; each face is also run on a generated date between 2020 and 2029 whose expected text the tests build from the date's day, month, year, weekday and ISO week, so a constant or a table of the examples fails. `ClockTime` is checked on 09:05:30, on 21:07:00 and on a generated time with non-zero seconds that must not appear in the output. Six tests pass `0D` or `0T` and expect an empty string.

## Learn More

- [Formatting values, dates, and time](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property) — the full list of Date and Time field names, the field-width syntax and the `Filler Character` attribute.
- [Format(Any, Integer, Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method) — the three-argument form and its `<Month Text> <Day>` example.
- [Date2DWY method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dwy-method) — how the platform assigns a week and a week year to a date around New Year.
- [GlobalLanguage method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-globallanguage-method) — the session language the month and weekday names follow, and what the tests switch.
