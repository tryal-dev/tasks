# Two Filters That Compile and Lie

A colleague left a small reporting codeunit behind before moving on. It compiles, it runs without a single error, and both numbers it produces are wrong: `CountWithoutSalesperson` reports every customer in the company, and `CountInRange` reports 0 whatever range it is asked for. Nobody noticed for weeks because nothing ever crashed — each bug is a filter that looks right and quietly does something else.

Your job is to make the two numbers true.

## Requirements

The starter contains a **codeunit** named `"Customer Queries"` with two public procedures. Keep the codeunit name and both signatures exactly as they are:

```al
procedure CountWithoutSalesperson(): Integer
procedure CountInRange(FromNo: Code[20]; ToNo: Code[20]): Integer
```

Rules:

1. `CountWithoutSalesperson` returns how many `Customer` records have a blank `"Salesperson Code"`. A customer carrying any salesperson code must not be counted — the answer is never "every customer in the table".
2. `CountInRange` returns how many `Customer` records have a `"No."` from `FromNo` through `ToNo`, **both ends included**: a customer numbered exactly `FromNo` or exactly `ToNo` counts, the customers numbered just before `FromNo` or just after `ToNo` do not. When `FromNo` equals `ToNo`, the range is that single number.
3. `FromNo` and `ToNo` are plain customer numbers (letters, digits and hyphens only), and `FromNo` never sorts after `ToNo`.
4. Both procedures answer 0 when nothing matches, and neither may raise an error.

Each procedure is one filter away from correct: the fix belongs on the filtering line. Only the counts are graded — how you arrive at them is not.

Keep the object ID in the house range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests run in a real company that already contains customers, so `CountWithoutSalesperson` is graded as a difference: a test calls it, adds a mix of customers with and without a salesperson code, calls it again, and asserts that the count grew by **exactly** the number of customers added without a code — by a generated number of them in one test, and by zero in another where every customer added carries a code. `CountInRange` is graded with exact counts on customers created under a generated number prefix: five ascending numbers of which the middle three are asked for (both boundaries in, both neighbours out), a range whose `FromNo` equals `ToNo`, a generated number of customers inside a wider range, and a range that holds no customer at all, which must return 0. Fixing only one of the two procedures leaves the other's tests failing.

## Learn More

- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method) — the reference for the method `CountWithoutSalesperson` calls.
- [Record.SetRange Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setrange-method) — the reference for the method `CountInRange` calls.
- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters) — the filter expression syntax, including what `..` means.
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — the rules that govern how each of the two methods treats its arguments.
