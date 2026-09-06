# Two Gigabytes Is Too Many

The document archive shows every customer how much storage their attachments use and warns them as they approach their quota. This morning the biggest customers all hit the same wall: opening the storage meter crashes with an overflow error. Each of them has more than 2 GB archived.

The archive stores each attachment's size in a Decimal field, so the sizes reach the meter as a `List of [Decimal]` of whole byte counts. The meter adds them up in an `Integer` — and an AL `Integer` is a signed 32-bit number that stops at 2,147,483,647, one byte short of 2 GB. Going past it does not wrap around or lose precision: it is a runtime error. `BigInteger` is the 64-bit whole-number type, good to ±9,223,372,036,854,775,807, and it is the right type for byte counts.

The second bug is subtler. The quota is entered in whole gigabytes and converted to bytes by multiplying with 1,073,741,824. The result goes into a `BigInteger`, yet a quota of 2 GB crashes as well, because AL types an expression from the types of its operands, not from the type it is about to be assigned to: `Integer` times `Integer` is an `Integer`, and it overflows *inside* the expression before the wide result is ever reached. The width of the target never rescues an intermediate value — at least one operand has to be wide before the arithmetic happens. Assigning the operand to a `BigInteger` variable first does it; so does writing the constant with an `L` suffix (`1073741824L`), which tells the compiler the literal is a `BigInteger`.

## Requirements

Complete the **codeunit** `"Storage Meter"` from the starter, keeping these two public procedures:

```al
procedure TotalBytes(Sizes: List of [Decimal]): BigInteger
procedure QuotaBytes(Gigabytes: Integer): BigInteger
```

Rules:

1. `TotalBytes` returns the sum of every value in `Sizes` as an exact number of bytes. Every size is a whole, non-negative number of bytes; a single size can itself be larger than 2 GB, and the total can reach tens of gigabytes. Every byte counts — no rounding, no truncation. An empty list totals 0.
2. `QuotaBytes` returns `Gigabytes` × 1,073,741,824 — a gigabyte here is 1024 × 1024 × 1024 bytes, not 1,000,000,000. `Gigabytes` is never negative, and 0 gigabytes is 0 bytes. Quotas of 2 GB and far beyond must work.
3. Neither procedure may raise an error for the inputs above. A runtime overflow fails a test exactly like a wrong number does.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## What the tests check

The grading tests build `List of [Decimal]` values and compare your results exactly. `TotalBytes` is checked with three 1.5 GB files (1,610,612,736 bytes each, expecting exactly 4,831,838,208), a single 3 GB file (3,221,225,472), two sizes that add up to exactly 2,147,483,648 — one byte past the Integer limit — an empty list, a generated handful of small sizes, and a generated list of four to eight files between 600 MB and 1.9 GB whose total always passes 2 GB. `QuotaBytes` is checked for 1 GB (1,073,741,824), 2 GB (2,147,483,648), 0 GB, and a generated quota between 3 and 1,000 GB. When a call raises an error instead of returning, the test fails and reports that error's text.

## Learn More

- [Integer data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/integer/integer-data-type) — the exact range, and the note that going past it is a runtime error.
- [BigInteger data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/biginteger/biginteger-data-type) — the 64-bit range and the `L` suffix that makes a constant a BigInteger.
- [Arithmetic operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-arithmetic-operators) — the type-conversion table: Integer with Integer yields an Integer, marked "overflow might occur".
- [AL variables: assignment and type conversion](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables#assignment-and-type-conversion) — which numeric assignments are valid and which can overflow; a Decimal into a BigInteger is among the valid ones.
