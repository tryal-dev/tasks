# Write Back a Record You Read Earlier

Two of the most asked-about Business Central runtime errors share one cause: "Another user has modified the record…" and its harsher cousin "Unable to change an earlier version of the … record. This is a programming error." both fire when code calls `Modify` on a record instance it read a while ago, after the row has changed underneath it. And the versions that never crash are often worse — they write the old copy's fields back over the row and silently erase what the other user just changed, the classic lost update. Your job is a small resolution service that does neither.

## The object you get

The starter ships one finished data object. Do not rename it or its fields — the grading tests bind to every name below character for character.

- Table `"Support Ticket"` — primary key `"Ticket No."` (Code[20]); fields `Description` (Text[100]), `Priority` (Integer), `Resolved` (Boolean), `"Resolution Note"` (Text[100]).

## Requirements

Implement the procedure in the codeunit `"Ticket Resolution Service"`:

```al
procedure ResolveTicket(StaleTicket: Record "Support Ticket"; ResolutionNote: Text[100]): Boolean
```

`StaleTicket` is a copy of the ticket that the caller read at some earlier point. By the time your service runs, another user may have changed any field of the row — or deleted it entirely. The copy's `"Ticket No."` is the only thing you can rely on.

Rules:

1. On success the ticket's row in the database ends up with `Resolved` = `true` and `"Resolution Note"` = `ResolutionNote`, saved, and the procedure returns `true`.
2. `Resolved` and `"Resolution Note"` are the only fields the service owns. Every other field must keep the value that is in the database *right now* — even where the copy in `StaleTicket` still carries an older value. A change another user made after the copy was read must still be on the row after your service returns.
3. The call must never fail with a runtime error just because the copy is out of date — neither "Another user has modified the record…" nor "Unable to change an earlier version of the Support Ticket record. This is a programming error." may reach the caller.
4. The vanished outcome: when no ticket with the copy's `"Ticket No."` exists anymore, return `false`, write nothing, and do not recreate the row from the copy.
5. The service runs inside the caller's transaction: raise no `Message`, `Confirm` or other dialog, and never call `Commit` — the grading run rolls everything back, and a `Commit` fails it.
6. Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

One test resolves an untouched ticket and verifies the `true` return, both service fields landing, and `Description` and `Priority` staying exactly as seeded. The stale tests read a copy, then change `Priority` (one test) or `Description` (another) through a second record instance, and only then hand the old copy to the service: they assert the call succeeds without a runtime error, that `Resolved` and the exact `"Resolution Note"` are on the row, and that the concurrently changed field still holds the other user's value — a service that writes the copy's fields back fails here even though it never crashed. The last test deletes the ticket after the copy was read and asserts the service returns `false` and leaves the row deleted. Seeded descriptions, priorities and notes are generated fresh on every run, so hardcoded values won't survive.

## Learn More

- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — how AL writes records, and what `Modify` promises about the row it targets.
- [Record.Modify([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method) — the method at the center of this task, including its optional Boolean return.
- [RecordRef.Modify([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-modify-method) — the remarks document both concurrency errors word for word and why the platform refuses to write an earlier version.
