# Twelve Buckets

The sales team wants a small chart on the customer card: one bar per month for a chosen year, the four quarter totals underneath, and a legend that lists only the months that actually had sales. Behind that chart sits the plainest data structure AL has: a fixed-size **array**. An `array[12] of Decimal` is twelve numbered slots, and the numbering runs from **1 to 12** — there is no slot 0 and no slot 13, and touching either is a runtime error. That makes the month number a natural index: `Date2DMY` with `2` as its second argument turns any date into a number from 1 to 12.

An array parameter declared `var` arrives holding whatever the caller left in it, so a procedure that fills one has to reset it first. `Clear` empties an array in one call, `ArrayLen` tells you how many slots it has, and `CompressArray` moves every empty text in an `array of Text` to the end. This task uses all three. Moving values between slots of one array is a plain loop over the slot numbers — `CopyArray` copies a run of slots into a *second* array that must be exactly as long as the run, and a plain `:=` between two arrays does not compile.

## Requirements

Create a **codeunit** named `"Monthly Buckets"` with five public procedures:

```al
procedure MonthlySales(CustomerNo: Code[20]; Year: Integer; var Buckets: array[12] of Decimal)
procedure AddToMonth(var Buckets: array[12] of Decimal; Month: Integer; Amount: Decimal)
procedure QuarterTotals(Buckets: array[12] of Decimal; var Quarters: array[4] of Decimal)
procedure ShiftWindow(var Buckets: array[12] of Decimal; NewMonthTotal: Decimal)
procedure NonEmptyMonthLabels(Buckets: array[12] of Decimal; var Labels: array[12] of Text): Integer
```

Rules:

1. `MonthlySales` fills `Buckets[1]` to `Buckets[12]` with the customer's sales per calendar month of `Year`: for every `Cust. Ledger Entry` whose `"Customer No."` is `CustomerNo` and whose `"Posting Date"` falls in `Year`, add its `"Sales (LCY)"` to the bucket of the posting month — January is slot 1, December is slot 12. Entries of other customers and entries posted in any other year — including 31 December of the year before and 1 January of the year after — are ignored. A month without entries ends up at exactly 0.
2. Every array a procedure fills is fully overwritten: whatever `Buckets` (in `MonthlySales`), `Quarters` or `Labels` held before the call is gone after it. A caller that reuses one array for several calls must never see the previous call's numbers or labels.
3. `AddToMonth` adds `Amount` to `Buckets[Month]`, on top of what that bucket already holds, and leaves the other eleven buckets alone. A `Month` outside 1 to 12 must raise an error with a message that contains `must be between 1 and 12` — never clamp it and never silently ignore it. Using `AddToMonth` inside `MonthlySales` is a good idea, but not graded.
4. `QuarterTotals` folds the twelve months into four quarters: `Quarters[1]` is the sum of months 1 to 3, `Quarters[2]` of months 4 to 6, `Quarters[3]` of months 7 to 9 and `Quarters[4]` of months 10 to 12.
5. `ShiftWindow` treats `Buckets` as a rolling twelve-month window and moves it forward by one month: the oldest month in slot 1 drops off, every other slot moves one position towards the front (slot 2 becomes slot 1, slot 3 becomes slot 2, and so on up to slot 12 becoming slot 11), and `NewMonthTotal` becomes the new slot 12. Mind the direction of the loop: copying slot 2 into slot 1 before slot 3 into slot 2 keeps every value; the other way round overwrites them.
6. `NonEmptyMonthLabels` builds the legend. A month is non-empty when its bucket is **not exactly 0** — a negative month of credit memos counts too. Each non-empty month is labelled with its English three-letter abbreviation: `Jan`, `Feb`, `Mar`, `Apr`, `May`, `Jun`, `Jul`, `Aug`, `Sep`, `Oct`, `Nov`, `Dec`. The labels sit in `Labels` in calendar order, packed from slot 1 with no gap between them, and every slot after the last label is an empty string. The procedure returns the number of labels — 0 for a year without sales, with all twelve slots empty.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## Example

A customer with sales of 1200 in February, a credit memo of -300 in July and sales of 800 in November of the requested year:

```text
Buckets   [1] 0   [2] 1200   [3] 0   [4] 0   [5] 0   [6] 0   [7] -300   [8] 0   [9] 0   [10] 0   [11] 800   [12] 0
Quarters  [1] 1200   [2] 0   [3] -300   [4] 800
Labels    [1] Feb   [2] Jul   [3] Nov   [4] to [12] empty        returns 3
```

`ShiftWindow(Buckets, 500)` on those buckets leaves 1200 in slot 1, -300 in slot 6, 800 in slot 10 and 500 in slot 12, with every other slot at 0.

## What the tests check

The grading tests seed customer ledger entries directly with generated amounts, a generated year and posting dates on 1 January, 31 December and a random mid-year month, call `MonthlySales`, and compare **all twelve buckets** — the months with entries against their exact sums, every other month against 0. Separate tests post entries on 31 December of the previous year and on 1 January of the following year, and for another customer in the same month, and expect them ignored. Other tests pre-fill the output array with leftover values before calling `MonthlySales`, `QuarterTotals` and `NonEmptyMonthLabels` and expect the leftovers gone. `AddToMonth` is called with month 1, with a random month on a pre-filled array (that bucket must grow by the amount, the other eleven must not change), and with months 0 and 13, which must fail with the promised message and leave every bucket untouched. `QuarterTotals` is checked against twelve generated values; `ShiftWindow` against twelve generated values and a generated new month, every slot compared; `NonEmptyMonthLabels` against buckets in February, July and November, a negative month, a pre-filled label array, a year of zeros, and a year with sales in all twelve months (every abbreviation from `Jan` to `Dec` in calendar order) — labels are compared character for character, the empty trailing slots and the returned count included.

## Learn More

- [Array methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-array-methods) — declaring an array, and why its indices run from 1 to N.
- [System.CopyArray method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-copyarray-method) — copying a run of slots into a second array of exactly that length; read its second example before reaching for it to shift slots.
- [System.CompressArray method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-compressarray-method) — moving empty texts to the end of an array so a printed list has no holes.
- [System.Date2DMY method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-date2dmy-method) — pulling the day, month or year out of a date.
