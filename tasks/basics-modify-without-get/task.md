# Change the Phone, Keep the Customer

The customer portal lets people change their own phone number, and the integration behind it calls one procedure: `UpdatePhone`. Support has three tickets from this morning, all the same shape: after a phone change, the customer card shows the new number — and a blank name, a blank address, no e-mail, no posting groups. The customer is still there, but every field except the key and the phone is gone.

The starter shows why. It assigns the customer number and the phone into a fresh record variable and calls `Modify` without ever reading the row. `Modify` does not merge: it writes the variable's fields over the stored row, and a variable that was never loaded is blank everywhere you did not assign. The row exists, so `Modify` succeeds without a word, and the compiler and the code analyzers are just as silent — the code is perfectly legal AL. That is why nobody noticed until the tickets arrived.

Two facts fix it. First, `Get` loads the row with that primary key into the variable, so after it the variable carries every stored value; change one field and `Modify` writes the row back with that one change. Second, `Get`, `Modify` and friends have two faces: used as a statement they raise an error when they fail, used as an expression (`if not Customer.Get(...) then`) they return `false` and leave the decision to you. Either face is fine here — what is not fine is a missing customer being ignored.

## Requirements

Create a **codeunit** named `"Customer Phone Update"` with one public procedure:

```al
procedure UpdatePhone(CustomerNo: Code[20]; Phone: Text[30])
```

Rules:

1. The customer whose `"No."` equals `CustomerNo` ends up with `Phone` in its `"Phone No."` field, exactly as passed.
2. Every other field of that customer keeps its stored value — name, address, e-mail, posting groups, all of them. The only exceptions are the `"Last Date Modified"` and `"Last Modified Date Time"` stamps that the `Customer` table maintains in its own `OnModify` trigger; the tests skip those, so running the table triggers (`Modify(true)`, `Validate`) or not is your choice.
3. Other customers are untouched.
4. If no customer with `CustomerNo` exists, the procedure raises an error whose text contains `CustomerNo` and the phrase `does not exist` (exactly those words, lowercase). The platform's own message from a failed `Get` already qualifies; so does your own `Error` call. Returning silently, or creating the customer, is wrong.
5. The tests pass phone numbers made of digits, spaces, `+` and `-` only, so assigning `"Phone No."` directly and validating it are both accepted.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests create a customer through the standard test library, give it a generated name, address, e-mail and phone number, call `UpdatePhone` and read the customer back from the database: the phone must equal the value passed, and name, address and e-mail must be exactly what they were before. A stronger test snapshots every stored field of the customer before the call and compares all of them afterwards — only `"Phone No."` may differ (the two last-modified stamps and the system audit fields are skipped) — and its failure message names the first field that changed together with both values. Another test creates two customers, updates one, and expects the other's phone untouched. The error test calls `UpdatePhone` with a customer number that does not exist and expects an error containing that number and `does not exist`; a call that returns normally fails it. The unchanged starter stores the phone but fails both keep-everything tests, because its `Modify` writes the blank variable over the row.

## Learn More

- [Record.Get([Any,...]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method) — loads the row with that primary key into the variable; note the optional Boolean return.
- [Record.Modify([Boolean]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method) — writes the variable over the stored row; `RunTrigger` decides whether `OnModify` runs.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — the write methods side by side, including the rule that an unhandled `false` becomes a runtime error.
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods) — the `if Get then … else …` pattern for handling a missing record yourself.
