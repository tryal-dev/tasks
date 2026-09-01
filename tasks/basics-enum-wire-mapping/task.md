# Map Carrier Wire Codes to an Enum

Your app syncs shipments with a parcel carrier whose API reports each shipment's status as a bare integer code. The carrier adds new codes a few times a year, and partner apps map them onto your status enum with enumextension objects — so the mapper must discover the enum's values at run time instead of freezing today's list into the code. Every enum in AL can report its own declared values and names at run time; that reflection is what this task is about.

## Requirements

The starter already declares the enum below — keep it exactly as it is. The names and ordinals are graded (the ordinals ARE the carrier's wire codes), and `Extensible = true` is required because the grading tests extend the enum from their own app.

| Ordinal | Name |
|---|---|
| 0 | `Unknown` |
| 10 | `Registered` |
| 20 | `"In Transit"` |
| 30 | `Delivered` |

Declare exactly these four values and no others — the tests probe codes outside this list and expect them to be unrecognized.

Complete the **codeunit** named `"Carrier Status Mapper"` with four public procedures:

```al
procedure FromWire(WireCode: Integer): Enum "Carrier Status"
procedure FromWireStrict(WireCode: Integer): Enum "Carrier Status"
procedure ToWire(Status: Enum "Carrier Status"): Integer
procedure ToWireName(Status: Enum "Carrier Status"): Text
```

Rules:

1. `FromWire` returns the enum value whose ordinal equals `WireCode`. A code that matches no value returns `Unknown` — this procedure must never raise an error, whatever integer it receives.
2. `FromWireStrict` returns the same value for a recognized code, but an unrecognized code must raise an error with a message that contains the offending code (passing 999 produces a message mentioning `999`).
3. `ToWire` returns the value's ordinal.
4. `ToWireName` returns the value's declared name, exactly as written in the enum object (`In Transit`, capital T). The caption is not the name: captions get translated per language, while this string goes on the wire — a caption-based lookup is a bug here.
5. None of the four procedures may enumerate the values itself (a `case` statement, an `if` chain, a hardcoded list): the grading tests declare an enumextension adding a value your code has never seen — with whatever ordinal the extension ends up with and a caption that differs from its name — and expect all four procedures to handle it with no change to your code. The starter's `case` statement is the bug you are replacing, not a base to build on.

## What the tests check

The tests round-trip every declared value in both directions (`ToWire`/`ToWireName` and `FromWire`/`FromWireStrict`), probe several unrecognized codes — including a randomly generated one — expecting `Unknown` from `FromWire` and an error containing the code from `FromWireStrict`, compare `ToWireName` results against the declared names character for character, and compile an enumextension into the test app whose new value all four procedures must map unchanged. Its wire code is read back from the enum at run time, not written down, so it is exactly the value's ordinal, whatever ordinal the extension was assigned. The tests reference your objects by name, so keep the object names exactly as given; pick object IDs in 50100–50199 (the starter already does) and never reference another object by its literal ID.

## Learn More

- [Extensible enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums) — declaring enums, `Extensible`, and how enumextension objects add values.
- [Enum data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-data-type) — the run-time methods every enum value carries.
- [Enum.Ordinals() method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-ordinals--method) — the declared ordinals as a `List of [Integer]`, extension values included.
- [Enum.FromInteger(Integer) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-frominteger-method) — converting a valid ordinal back into an enum value.
