# Five Switches in One Integer

Customer notification preferences live in a single Integer field: five yes/no switches packed into one number, each switch worth a different power of two. The portal writes the field, the reporting team reads it, and last week a "turn on Post for everyone" fix ran twice and silently turned Email + Post (9) into Email + Urgent first (17) — it just added 8 again. AL has no bitwise operators (`and`, `or` and `xor` accept only Booleans), so the arithmetic operators `div` and `mod` have to do the bit work.

## Requirements

Create a **codeunit** named `"Notification Flags"` with four public procedures:

```al
procedure HasFlag(Value: Integer; Bit: Integer): Boolean
procedure SetFlag(Value: Integer; Bit: Integer): Integer
procedure ClearFlag(Value: Integer; Bit: Integer): Integer
procedure Channels(Value: Integer): List of [Text]
```

The five flags:

| Flag | Meaning |
|---|---|
| `1` | Email |
| `2` | SMS |
| `4` | Portal |
| `8` | Post |
| `16` | Urgent first — reverses the channel order |

Rules:

1. A preference `Value` is the sum of its set flags, so every number from 0 to 31 is exactly one combination: 9 is Email + Post, 26 is SMS + Post + Urgent first. `Bit` is always one of the five flag values `1`, `2`, `4`, `8`, `16` — the tests never pass anything else.
2. `HasFlag` returns `true` when the flag `Bit` is part of `Value`: `HasFlag(9, 8)` is `true`, `HasFlag(9, 2)` is `false`.
3. `SetFlag` returns `Value` with the flag `Bit` set. When the flag is already set the value comes back **unchanged** — `SetFlag(9, 8)` is 9, not 17. `SetFlag(9, 2)` is 11.
4. `ClearFlag` returns `Value` with the flag `Bit` cleared. When the flag is not set the value comes back **unchanged** — `ClearFlag(9, 2)` is 9, not 7. `ClearFlag(9, 8)` is 1.
5. `Channels` returns the names of the set channel flags — exactly the texts `Email`, `SMS`, `Portal` and `Post`, mind the spelling and the case — in ascending flag order: Email, SMS, Portal, Post. When the Urgent first flag (`16`) is also set, the order is reversed: Post, Portal, SMS, Email. Urgent first itself is never in the list. A value with no channel flag set (0, or 16 alone) returns an empty list.
6. All four procedures refuse a `Value` outside 0..31 with an error whose message contains the words `between 0 and 31`.

The trick: because every flag is a power of two, integer division of `Value` by `Bit` drops every smaller flag and shifts the flag you are asking about into the ones position, and every larger flag lands in the even part of that quotient. So whether the quotient is odd or even tells you whether the flag is set — `div` gets you the quotient and `mod` its parity. `Power(2, n)` gives you the n-th flag if you prefer to loop over positions rather than over the values (it returns a Decimal, so assign it to an Integer first). Adding or subtracting `Bit` unconditionally is the bug from the story above: it double-counts a flag that is already there and borrows from other flags when it is not.

Pick object IDs in the range 50100–50199, and reference other objects **by name**, never by ID.

## Examples

| `Value` | Set flags | `Channels(Value)` |
|---|---|---|
| 9 | Email, Post | `Email`, `Post` |
| 26 | SMS, Post, Urgent first | `Post`, `SMS` |
| 15 | Email, SMS, Portal, Post | `Email`, `SMS`, `Portal`, `Post` |
| 31 | all five | `Post`, `Portal`, `SMS`, `Email` |
| 16 | Urgent first only | (empty) |
| 0 | none | (empty) |

## What the tests check

The grading tests call the four procedures with fixed and generated values and compare the results **exactly**. `HasFlag` is asked for all five flags of 9, of 0 and of 31, and for every flag of a generated value between 1 and 30. `SetFlag` and `ClearFlag` are checked on 9 with a flag that is missing and with one that is already there — the naive "add 8" must not turn 9 into 17, and the naive "subtract 2" must not turn 9 into 7 — and on a generated value with a generated flag, where only that one flag may change. `Channels` is checked on 9, 26, 15, 31, 0, 16 and a generated value: the count, the names and the order must all match. The number of elements is asserted on its own, and a failure shows both lists as comma-separated text with every element quoted (`'Email', 'Post'`), so an empty text that slipped into the list shows up as `''` instead of disappearing. Four tests pass an out-of-range value (32, -1, 64, -5) to each procedure in turn and expect an error containing `between 0 and 31`; every in-range value, 0 and 31 included, must go through without one.

## Learn More

- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — the operand and result types of `div` and `mod`, the two operators that stay in whole numbers.
- [Boolean (logical) operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-boolean-operators) — `and`, `or` and `xor` take Boolean arguments only; there is no bitwise variant to reach for.
- [System.Power method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-power-method) — 2 to the n-th power if you loop over flag positions; note that it returns a Decimal.
- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — `Add` appends, `Insert` places an element at a 1-based index, `Count` tells you how many you collected.
