# Two Moments in One Validation

The warehouse prints pick labels straight off the sales line, always in upper case, and the sales desk keeps swapping the item on a line until the customer is happy. After every swap two things must be true: the line carries a pick label for the item that is on it now, and it still remembers the description of the item it just replaced, so support can reconstruct what the clerk did.

Validating `"No."` on a sales line is not a quiet moment. Table 37 runs its own validation code in the middle of yours: it pulls the new item's values onto the line — the description among them — and resets line fields on the way, yours included. What your code sees, and whether what it writes survives, depends entirely on where in that sequence it runs. This is the task behind the oldest complaint in extension development: "my value gets overwritten by the base app".

## Requirements

1. Create a **table extension** for the `"Sales Line"` table with a field named `"Pick Label"` of type `Text[100]` and a field named `"Previous Description"` of type `Text[100]`.
2. Every time `"No."` is **validated** on a sales line, both fields must be up to date by the time that validation returns:
   - `"Pick Label"` — the line's `Description` as the finished validation left it, converted to upper case, character for character.
   - `"Previous Description"` — the `Description` the line carried immediately before that same validation started (blank if it carried none).
3. That holds for every validation of `"No."`, including a second one performed before the line is saved: the two fields always describe the change that just happened, never the state stored in the database.
4. Nothing else may touch either field. Validating another field on the line, or assigning `"No."` directly (`SalesLine."No." := ...`) without validating, must leave both fields exactly as they were.
5. Do not modify base objects — extend them from the outside. Object names are yours to choose; only the two field names are graded.

Pick all object and field IDs in the range **50100–50199**, and reference other objects **by name, never by ID**. No page extensions are needed — grading reads and writes the fields in code. Captions are good practice but not graded.

## What the tests check

The tests build real sales orders with the standard libraries, using items whose descriptions are **generated lowercase text**, so a label that just copies the description — or a hardcoded one — fails. Putting an item on a new line must stamp `"Pick Label"` with that description in upper case and leave `"Previous Description"` blank, since that line replaced nothing; re-validating `"No."` to a second item must restamp the label, and must leave `"Previous Description"` holding the first item's description, read back from the database after the line is saved. One test re-validates `"No."` twice without saving in between and asserts `"Previous Description"` holds the description the line carried a moment earlier, not the one on disk. Two further tests assert that validating an unrelated field on the line, and assigning `"No."` without validating, leave both fields untouched. A last test checks that both fields are declared as `Text` with a maximum length of exactly 100. Except where a test says otherwise, the fields are read straight off the record in memory right after the validation, so the values must be there when it returns — there is no separate save step to fix them up in.

## Learn More

- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — adding fields to `Sales Line`, and reaching the fields that are already there.
- [Record.Validate method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-validate-method) — what `Validate` actually runs, and how that differs from a plain assignment.
- [Triggers overview](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/devenv-triggers) — where trigger code can live on a table, on a field, and in an extension of either.
- [System-defined variables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-defined-variables) — `Rec`, `xRec` and `CurrFieldNo`, and what "the record before the changes" really means.
