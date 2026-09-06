# The Relation That Overflows

Your team shipped a small `"Customer Note"` table: one row per note, each pointing at a customer. It sailed through every test database — until the first production user added a note for customer `CUST-2024-000123` and got *"The length of the string is 16, but it must be less than or equal to 10 characters."* The demo company numbers its customers `10000`, `20000`, `30000` — five characters that fit anywhere, which is exactly why nobody noticed.

The root cause is a single declaration: `"Customer No."` is a `Code[10]`, while the key it relates to, `Customer."No."`, is a `Code[20]`. `TableRelation = Customer` wires the lookup and the validation, but it does not carry the length along — the compiler accepts the mismatch without a word (LinterCop's rule LC0076 exists to catch it), and the overflow only shows up at run time, on the first customer whose number is long enough. The analyzers do see it: CodeCop underlines the `Validate` call in the starter with AA0139, *Do not assign a text to a target with smaller size* — the warning points at the symptom, and the cause is one line further up the dependency chain, in the table.

The starter reproduces the bug. Fix it.

## Requirements

The starter contains both objects, complete apart from the bug. Keep their names and signatures:

A **table** named `"Customer Note"`:

| Field | Type | Notes |
|---|---|---|
| `"Entry No."` | `Integer` | primary key, assigned by the platform (`AutoIncrement`) |
| `"Customer No."` | `Code` — related to `Customer` | the field to fix |
| `Note` | `Text[250]` | |

A **codeunit** named `"Customer Note Mgt."` with a public procedure:

```al
procedure AddNote(CustomerNo: Code[20]; NoteText: Text[250])
```

Rules:

1. `"Customer No."` is declared as a `Code` field whose length **equals the length of `Customer."No."`** — exactly that length, not a different one. A shorter field overflows on long customer numbers; a longer one accepts numbers the relation can never resolve. LC0076 flags both directions.
2. The field keeps its table relation to `Customer`, and `AddNote` keeps validating the number against it: a number that no customer carries is refused by the relation check itself — the error text contains `cannot be found in the related table`.
3. Every `AddNote` call inserts exactly one `"Customer Note"` row, with the customer number and the note text stored **exactly as passed** — nothing shortened, up to the full 250 characters of note. A customer can carry any number of notes.
4. Fix the declaration, not the caller: shortening the number inside `AddNote` would make the note point at a customer that does not exist, and the tests read the stored number back.

Pick object IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. Captions are good practice but not graded.

## What the tests check

The grading tests create a customer whose number is exactly 20 characters long (a generated `TRYAL-…` value), call `AddNote` for it, and read the row back by its generated note text: the stored `"Customer No."` must equal the full 20-character number, and `Customer.Get` with that stored value must find the customer again — on the starter both tests die with the string-overflow error above. A third test reads the field's declaration through a `FieldRef` and expects type `Code` with a length of exactly `MaxStrLen(Customer."No.")`, so `Text[20]`, `Code[30]` or a still-narrow field all fail there. The remaining tests guard the parts that must survive the fix: the field must still relate to the `Customer` table, `AddNote` with a number no customer carries must fail with the relation's own `cannot be found in the related table` error, a note for an ordinary short-numbered customer is stored as given, a generated 250-character note round-trips in full, and two calls for the same customer leave two rows.

## Learn More

- [TableRelation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property) — what the relation does (lookup and validation) and what it does not do (nothing about lengths).
- [Setting relationships between tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-set-relationships-between-tables) — relations always target a primary-key field, so the field on your side must be able to hold every value of that key.
- [Code data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/code/code-data-type) — the length is part of the declaration, and a value that does not fit is an error, not a truncation.
- [AL variables: assignment and type conversion](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables#assignment-and-type-conversion) — the table that says "valid but overflow might occur" for every Text-to-Code and Code-to-Code assignment.
