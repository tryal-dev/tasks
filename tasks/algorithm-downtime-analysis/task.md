# The Maintenance Window

The shop-floor terminal keeps one shared event log for the production line: work centers take turns on the line, and the terminal writes a line when a work center begins its shift and every time it stops or comes back up. The maintenance team wants two numbers per work center — how many minutes it was down in total, and which minute of the day it is down most often, so the preventive-maintenance visit can be scheduled exactly then. There is one catch: the export tool scrambled the order of the log lines.

## Requirements

Create a **codeunit** named `"Downtime Analyzer"` with two public procedures:

```al
procedure TotalDowntimeMinutes(LogLines: List of [Text]; WorkCenterNo: Code[20]): Integer
procedure MostFrequentDownMinute(LogLines: List of [Text]; WorkCenterNo: Code[20]): Integer
```

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

### The log format

Every line has the exact shape `[YYYY-MM-DD HH:MM] <event>` — a zero-padded timestamp on a 24-hour clock (no seconds) in square brackets, one space, then one of three events:

- `<code> begins shift` — the named work center takes over the line, for example `[2027-04-12 06:00] GRINDER begins shift`. Every later `stopped` and `running` event belongs to it, until another work center begins its shift.
- `stopped` — the work center currently on shift went down at that minute.
- `running` — the work center currently on shift came back up at that minute.

The list arrives **in no particular order** — never assume it is chronological. "Later", "next", and "currently on shift" above always mean by timestamp, not by list position.

You may rely on these guarantees about every log the tests feed you: timestamps are unique across the whole log; work center codes are 1–20 characters of capital letters, digits, and dashes (never spaces); the chronologically first line is always a `begins shift`; a `running` only ever appears as the event right after a `stopped`; and every stop lasts at least 1 minute and less than 24 hours.

### What to compute

A stop starts at a `stopped` timestamp S and ends at the chronologically next `running` timestamp R. It contributes the whole minutes between S and R to the total, and the work center counts as down for every minute of day from S inclusive to R exclusive — a stop from `23:50` to `00:10` spans midnight, lasts 20 minutes, and covers the minutes `23:50`–`23:59` and `00:00`–`00:09`.

- `TotalDowntimeMinutes` returns the summed duration in minutes of all stops belonging to the given work center.
- `MostFrequentDownMinute` returns the minute of day — 0 for `00:00` up to 1439 for `23:59` — covered by the most stops of the given work center, each stop counting at most once per minute. When several minutes tie for the highest count, return the smallest minute of day.
- A work center with no recorded stops — including one that never appears in the log, and the empty log — has a total of 0, and `MostFrequentDownMinute` returns -1 for it.

### The broken log

When the chronologically next event after a `stopped` is not a `running` — another `stopped` follows, some work center begins a shift, or the log simply ends — the log is broken: both procedures must then raise an error with a message that contains the exact phrase `no matching running event`. This check applies to the whole log, no matter which work center the caller asked about.

## What the tests check

Fixed logs — always handed over in scrambled order — cover: a single stop, several stops summed, bare `stopped`/`running` lines attributed to the work center of the most recent shift start, a midnight-spanning stop (both its 20-minute total and its wrapped minute-of-day coverage), the most frequent minute across three shifts with a decoy work center in the same log, a tie resolved to the earliest minute, one stop ending and another starting at the same minute of day (the end minute is excluded, so no minute reaches a count of two), and the 0 / -1 answers for work centers without downtime — including a work center that never appears in the log and the entirely empty log, for both procedures. Three broken logs — a `stopped` as the last event, a `stopped` cut off by the next shift (queried for a different work center), and two `stopped` in a row — must each raise an error containing `no matching running event`. Finally, two randomized logs are graded against an independently computed sum of durations and an independent minute-by-minute tally, so hardcoding the fixed examples fails.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the log arrives as a `List of [Text]`; its methods for reading, inserting, and iterating are all here.
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type) — substring and comparison methods for pulling the timestamp and event apart.
- [System.Evaluate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method) — turns the digit groups of a timestamp into numbers.
- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type) — date construction and arithmetic, useful once a stop crosses into the next day.
