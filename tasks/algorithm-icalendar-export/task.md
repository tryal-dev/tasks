# The Feed the Calendar App Rejected

The facility team wants the meeting-room bookings from Business Central inside their calendar apps, so someone exported them as an `.ics` file — and one client showed the events fine, another silently dropped half of them, and a third refused the file outright. The iCalendar format (RFC 5545) is strict about things that are invisible in a text editor: line endings must be CRLF, no physical line may exceed 75 octets, and text values need their own escaping. You are building the export that every client accepts, byte for byte.

## Requirements

The starter ships a table named `Booking` (fields: `"No."` Code[20] — the primary key, `Description` Text[100], `Location` Text[100], `"Start Date"` Date, `"Start Time"` Time, `"End Date"` Date, `"End Time"` Time). Include it in your submission unchanged — the tests seed it and read your feed from it.

Create a **codeunit** named `"Booking ICS Export"` with one public procedure:

```al
procedure Export(StampDate: Date; StampTime: Time): Text
```

It returns the complete iCalendar feed for **all** `Booking` records, in ascending `"No."` order.

### Feed structure

The feed consists of these content lines, in exactly this order:

1. `BEGIN:VCALENDAR`
2. `VERSION:2.0`
3. `PRODID:-//TryAL//Bookings 1.0//EN`
4. For each booking, one `VEVENT` block: `BEGIN:VEVENT`, `UID:<No.>@tryal-bookings`, `DTSTAMP:<stamp>`, `DTSTART:<start>`, `DTEND:<end>`, `SUMMARY:<escaped Description>`, `LOCATION:<escaped Location>` — the LOCATION line is **omitted entirely** when `Location` is empty — and `END:VEVENT`.
5. `END:VCALENDAR`

An empty `Booking` table produces just lines 1–3 and 5.

### Date-time format

`DTSTAMP` is built from the `StampDate`/`StampTime` parameters (the same value on every event); `DTSTART` and `DTEND` come from the booking's start and end fields.

All values are already UTC — no time-zone conversion. Format them as `YYYYMMDDTHHMMSSZ` with every component zero-padded to fixed width: March 5, 2026 at 07:04:09 becomes `20260305T070409Z`. Note the padding — a feed that renders 7 o'clock as ` 70409` or `70409` fails.

### TEXT escaping

In the `SUMMARY` and `LOCATION` values (and only there), escape three characters: a backslash `\` becomes `\\`, a semicolon `;` becomes `\;`, a comma `,` becomes `\,`. Escaping must not cascade — the backslashes produced by an escape are never escaped again. A description of `Lunch; bring \ your, plans` becomes `SUMMARY:Lunch\; bring \\ your\, plans`.

### Line folding

After escaping, a content line longer than 75 characters is folded across several physical lines: the first physical line carries the first 75 characters, and each continuation line carries a single space followed by the next 74 characters, repeated until the line is spent — so every physical line is at most 75 characters, the leading space included. Fold by pure character count: it is fine for a fold to land in the middle of an escape pair like `\,`. All graded input is plain ASCII, so characters and octets are the same thing here.

### Line endings

Every physical line — the last one included — ends with CR immediately followed by LF (character codes 13 and 10). A feed with bare LF endings fails every byte-exact comparison.

You can rely on this about the graded data: booking numbers contain only letters, digits, and dashes; descriptions and locations never contain line breaks; times have whole seconds (no milliseconds).

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

### Example

Two bookings, with `DTSTAMP` parameters April 1, 2026 12:00:00 — note the folded `SUMMARY` of the second event. Every line break below is the two characters CR LF, and the second physical line of that folded `SUMMARY` starts with one space:

```text
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//TryAL//Bookings 1.0//EN
BEGIN:VEVENT
UID:BK-001@tryal-bookings
DTSTAMP:20260401T120000Z
DTSTART:20260410T090000Z
DTEND:20260410T103000Z
SUMMARY:Board meeting
LOCATION:Room 4
END:VEVENT
BEGIN:VEVENT
UID:BK-002@tryal-bookings
DTSTAMP:20260401T120000Z
DTSTART:20260411T140000Z
DTEND:20260411T150000Z
SUMMARY:Quarterly review with all the regional facility coordinators\, cate
 ring ordered\, projector booked
END:VEVENT
END:VCALENDAR
```

## What the tests check

Byte-exact comparisons of the whole feed for an empty table, a single plain booking, a booking without a location, the two-booking example above (folded second SUMMARY included), a summary that fills its content line to exactly 75 characters (one unfolded physical line, no continuation), a summary one character over that (75 characters plus a two-character continuation), and one randomized booking assembled independently by the tests — so hardcoding the examples fails. Targeted checks cover the rest: every line break is CRLF (bare LF fails), single-digit date and time components are zero-padded, backslash/semicolon/comma are escaped in SUMMARY and LOCATION, a 100-character summary folds into exactly 75 characters plus a space-led 34-character continuation, a summary of 100 commas expands after escaping to a 208-character content line that folds into exactly three physical lines, no physical line ever exceeds 75 characters, and events appear in ascending `"No."` order. All comparisons are exact, character for character.

## Learn More

- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — the slicing and replacing toolbox you will lean on for escaping and folding.
- [TextBuilder data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type) — building a long feed without re-allocating a Text on every append.
- [Char data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type) — the data type behind the single characters inside a Text.
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type) — what a Date value is and the methods available around it.
