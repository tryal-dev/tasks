# References That Survive Rename

Your app lets users bookmark customers, and the bookmark table your predecessor built stores the customer's `"No."` — the primary key. Last week a consultant renamed a handful of customers to a new numbering scheme, and every bookmark pointing at them silently broke: a stored copy of a primary key is just text, and `Rename` does not update it. Every record in Business Central carries a second identity that survives renames: the `SystemId`, an immutable GUID the platform assigns on insert. Your job is to move the bookmarks onto it — and to migrate the legacy rows already in the table.

## Requirements

The starter contains the legacy `"Customer Bookmark"` table (fields `"Entry No."`, the Integer primary key, and `"Customer No."`, `Code[20]`) and a codeunit `"Customer Bookmarks"` that still resolves bookmarks through the stored number.

1. Add a field named `"Customer SystemId"` of type `Guid` to the `"Customer Bookmark"` table. Keep `"Customer No."` exactly as it is — a plain snapshot with **no table relation**. The tests assert that it goes stale after a rename; that staleness is the point of the exercise.
2. Finish the codeunit `"Customer Bookmarks"` with these four public procedures:

```al
procedure AddBookmark(CustomerNo: Code[20]): Integer
procedure ResolveCustomer(EntryNo: Integer; var Customer: Record Customer): Boolean
procedure ImportBookmark(BookmarkId: Guid; CustomerNo: Code[20]): Integer
procedure MigrateLegacyBookmarks(): Integer
```

Rules:

- `AddBookmark` creates a bookmark storing both the customer's `SystemId` (in `"Customer SystemId"`) and its number (in `"Customer No."`), and returns the new row's `"Entry No."`. Tests always pass the number of an existing customer.
- `ResolveCustomer` finds the bookmark with `EntryNo` and resolves the customer through the stored `"Customer SystemId"` — `GetBySystemId` is the tool. It returns `false` when no bookmark has that entry number or the customer no longer exists, and never raises an error in those cases. Resolution must keep working after the customer is renamed, and the record it returns then carries the customer's **new** number.
- `ImportBookmark` is for syncing bookmarks in from another environment: it behaves like `AddBookmark`, except that the inserted bookmark row's **own** `SystemId` must be exactly the caller-supplied `BookmarkId` — `Insert` has a two-boolean overload whose second argument tells the platform to keep a pre-assigned id instead of generating one. Importing the same `BookmarkId` twice must fail: let the platform's duplicate-id error surface (`SystemId` is a unique index, so the text starts with `There is already a record in table`).
- `MigrateLegacyBookmarks` upgrades rows created before your change: a legacy row has an empty (null-GUID) `"Customer SystemId"`. For each such row, find the customer by the stored `"Customer No."`, fill `"Customer SystemId"` with that customer's `SystemId`, and return how many rows you migrated. A legacy row whose stored number matches no customer stays untouched and is not counted. Rows that already carry an id are never touched — even when their stored number is stale or has been taken over by a different customer since.

The tests fabricate legacy rows by inserting into `"Customer Bookmark"` directly with an empty `"Customer SystemId"`, so rows your code never created will exist — the entry numbers they use may be far above the ones `AddBookmark` handed out.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests add a bookmark and read the stored `SystemId` and number straight from your table; resolve a bookmark before and after `Rename` on the customer and expect the new number back while the stored `"Customer No."` still shows the old one; expect `false` for a deleted customer and for an unknown entry number; import a bookmark with a caller-supplied GUID and fetch the row back via `GetBySystemId` on your table; expect the second import of the same GUID to fail with the platform's `There is already a record in table …` unique-index error; and run the migration against a mix of legacy rows — one resolvable (counted and filled with the right customer's id), one pointing at a vanished customer (left empty, not counted), and one already-migrated row whose stale number now belongs to a different customer (which migration must not repoint). One test renames a customer after migrating and expects the migrated bookmark to resolve to the new number.

## Learn More

- [System fields](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-system-fields) — what the `SystemId` is, why it never changes, and how the platform assigns it.
- [Record.GetBySystemId(Guid) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-getbysystemid-method) — retrieving a record by its `SystemId`, with the Boolean return you need for the not-found case.
- [Record.Insert(Boolean, Boolean) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-boolean-boolean-method) — the overload that keeps a `SystemId` you assigned yourself.
- [Record.Rename method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method) — what a primary-key rename does and does not update.
