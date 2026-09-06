# 1.10 Is Newer Than 1.9

The partner connector refuses any API older than a minimum version, and last night it refused every partner running release `1.10.0` while happily accepting `1.9.5`. The gate is a single line of AL: `exit(Actual >= Minimum)` — a text comparison, which decides at the first differing character that `'1'` is smaller than `'9'` and stops reading. Versions are numbers separated by dots, not text, and AL has a data type for exactly that: `Version`. Your job is to make the gate compare versions as versions, accept the slightly messy strings partners actually send, and never crash on the garbage some of them send instead.

## Requirements

Create a **codeunit** named `"Version Compare"` with two public procedures:

```al
procedure Normalize(Input: Text): Text
procedure IsAtLeast(Actual: Text; Minimum: Text): Boolean
```

Rules:

1. A version is `Major.Minor`, `Major.Minor.Build` or `Major.Minor.Build.Revision` — two to four whole numbers separated by dots. Each part is a number, not text: `1.09` is major 1, minor 9.
2. The input may carry whitespace around it (spaces or tabs) and an optional leading `v` or `V` directly before the first digit, as in ` v1.10.0 `. Both are ignored.
3. `Normalize` returns the canonical four-part text `Major.Minor.Build.Revision`, with 0 written for every part the input did not supply and no leading zeros: `2.0` becomes `2.0.0.0`, `1.10.0` becomes `1.10.0.0`, `1.09.0` becomes `1.9.0.0`, and `27.1.23456.26323` stays as it is.
4. Malformed input — anything that is not a version, such as `1.9.5-beta`, `abc`, `1.2.3.4.5` (five parts) or an empty text — makes `Normalize` return an empty text. Never a runtime error.
5. `IsAtLeast` returns `true` when `Actual` is the same version as `Minimum` or a newer one, comparing the major part first, then minor, build and revision, each as a number. `1.10.0` is at least `1.9.5`; `2.0` is at least `2.0.0` (they are the same version); `2.0.0` is at least `1.99.99.99`; `1.9.5` is not at least `1.10.0`. Both arguments get the same clean-up as in rule 2.
6. When either argument is malformed, `IsAtLeast` returns `false` — the connector refuses what it cannot read. Never a runtime error.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## The Version type, and its two traps

`Version.Create(Text)` parses a version text; `Major()`, `Minor()`, `Build()` and `Revision()` read the four parts; `Version.Create(Integer, Integer, Integer, Integer)` builds a version from numbers; `ToText()` writes one back as text; and two `Version` values compare with the ordinary relational operators (`<`, `>=`, `=`). Two things about it are not obvious:

- **A part the input did not supply is not 0.** `Version.Create('2.0')` remembers that Build and Revision were never given: they read back as -1 (the .NET convention underneath), `ToText()` gives `2.0` again, and the value compares *below* `Version.Create('2.0.0')`. So parsing both sides and comparing them straight away still gets rule 5 wrong. Rebuild the version from its four parts, writing 0 for any part below zero, before you compare or print it — and never pass a negative number to `Create`, it is rejected.
- **`Version.Create(Text)` raises an error on malformed input; nothing returns `false`.** Wrap the parse in a procedure marked `[TryFunction]`: it cannot declare a return value of its own, so hand the parsed version out through a `var` parameter, and *use* its Boolean — `if TryParse(Input, Result) then`. Called as a bare statement, a try function is an ordinary call and the error escapes.

For the clean-up, `Text.Trim()` removes surrounding whitespace including tabs (`DelChr` with `' '` removes spaces only), and `Text.StartsWith` plus `CopyStr` take care of the `v`.

## What the tests check

The grading tests call `Normalize` with `2.0` (expecting `2.0.0.0`), a generated three-part version (expecting a `.0` appended) and a generated four-part version (expecting it unchanged), with `1.09.0` (expecting `1.9.0.0`), with `1.10.0` wrapped in spaces and a tab, and with `v1.10.0` and `V2.5` — all exact text comparisons. They then expect an empty text, and no error, for `1.9.5-beta`, `abc`, `1.2.3.4.5` and an empty text. `IsAtLeast` is called with `1.10.0` against `1.9.5` (expecting `true`) and the other way round (`false`), `2.0` against `2.0.0` (`true`), a generated four-part version against itself (`true`), against a minimum one revision higher (`false`) and one revision lower (`true`), a generated version with a non-zero revision against a minimum one build higher with revision 0 (`false` — the build is compared before the revision), `2.0.0` against `1.99.99.99` (`true`), and ` v1.10.0 ` against `V1.10` (`true`). Finally `1.9.5-beta` as the actual version and `latest` as the minimum must each return `false` — a runtime error raised by your code fails that test with the error text in the message.

## Learn More

- [Version data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/version/version-data-type) — the two `Create` overloads and the `Major`/`Minor`/`Build`/`Revision`/`ToText` methods.
- [Version.Create(Text) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/version/version-create-string-method) — the accepted format, and the fact that anything else throws.
- [Handling errors using try methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods) — how a `[TryFunction]` catches an error, and why its return value must be used.
- [Text.Trim() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method) — removes leading and trailing whitespace of every kind.
