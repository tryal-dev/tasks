# Ranges, Not If-Chains

The dispatch team's courier app has two small classification rules, and both misbehave. The shipping zone is worked out from the postcode the customer typed, and since the last release every parcel is quoted as Zone 3 — city-centre deliveries included. The monthly courier grade comes from an on-time score, and a courier whose score was keyed in as 101 was awarded an A. Both rules are "more than two choices" logic, which is exactly what AL's `case` statement is for: a value set can be a single value, a comma-separated list (`1, 2, 9`) or an inclusive range (`10..100`), and the `else` arm catches whatever no other arm matched.

The starter is the current code. Fix both rules.

## Requirements

Complete the **codeunit** `"Dispatch Rules"` with these two public procedures:

```al
procedure ShippingZone(PostCode: Code[10]): Integer
procedure Grade(Score: Integer): Text
```

Rules:

1. `ShippingZone` returns 1 for the city-centre outward codes `EC1`, `EC2`, `EC3`, `EC4`, `WC1` and `WC2`; 2 for the inner-ring codes `E1`, `N1`, `NW1`, `SE1`, `SW1` and `W1`; and 3 for **every other** postcode. Only these exact codes count: `EC5`, `SW19`, `E10`, `EC1A` and `EC10` are on neither list, so they are Zone 3 — do not match on a prefix, and do not write the zones as ranges (`EC1A` and `EC10` sort between `EC1` and `EC4` as text).
2. Postcodes are typed by hand, so `ec1`, `Ec1` and `EC1` are the same postcode and must land in the same zone. The parameter is a `Code[10]`, and a `Code` value is uppercased (and trimmed) the moment it is assigned, so the procedure never sees a lowercase letter. The starter still never returns 1 or 2, and the reason is documented behaviour, not a runtime bug: when the expression of a `case` statement is a `Code` variable, the value sets are **not** converted to `Code` — they are compared exactly as written, so a lowercase literal can never match an uppercased postcode.
3. `Grade` maps a score to a letter: 90 to 100 is `A`, 75 to 89 is `B`, 60 to 74 is `C`, 40 to 59 is `D` and 0 to 39 is `F`. Every band includes both of its ends: 89 is a `B`, 90 is an `A`.
4. A score outside every band — negative, or above 100 — returns the text `Invalid`. The starter's if-chain has no upper bound and no branch for such a score, which is why 101 grades as `A` and -5 as `F`.
5. Comparisons are exact: return exactly the single uppercase letter, or exactly `Invalid`.

Write each rule as one `case` statement: value lists for the zones, ranges for the grade bands, and an `else` arm in both. Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests call `ShippingZone` with each of the six Zone 1 codes and each of the six Zone 2 codes in uppercase, then with lowercase and mixed-case spellings (`ec1`, `sw1`, `Wc2`, `nW1`), and expect the exact zone number; the near misses `EC5`, `SW19`, `E10`, `EC1A` and `EC10`, an unlisted `BR1`, and a generated six-letter code must all return 3. `Grade` is checked at both ends of every band (0, 39, 40, 59, 60, 74, 75, 89, 90 and 100) plus a generated score inside each band, and with 101, -1 and generated scores above 100 and below 0, which must all return `Invalid`. Every comparison is exact.

## Learn More

- [AL control statements — case statements](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-control-statements#case-statements) — the syntax of value lists, ranges and `else`, and Example 10 showing why a `Code` expression never matches a lowercase value set.
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type) — what happens to a value the moment it is assigned to a `Code` variable or parameter.
- [Work with conditional statements](https://learn.microsoft.com/en-us/training/modules/al-statements/3-conditional) — the training module's walkthrough of `if-then-else` versus `case`, with the layout conventions for a `case` statement.
