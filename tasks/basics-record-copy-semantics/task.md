# Snapshot or Shared View?

A pricing simulation builds its working data in a temporary `"Name/Value Buffer"` record. The audit trail wants a **snapshot** — the rows exactly as they were at one moment, frozen forever. A live monitor wants a **shared view** — a second variable onto the very same data set, following every later change. A teammate implemented both with the same one-liner, `Copy` with `ShareTable = true`, and now the "snapshot" keeps changing after it was taken. Your job is to give each consumer what it actually asked for.

`Record.Copy` is the whole lesson here, and it has two very different modes. With `ShareTable = true` (both records must be temporary) the target does not receive data at all — it becomes a second handle on the **same** in-memory table, so every later insert, modify, or delete shows through both variables. Without `ShareTable`, `Copy` transfers only the current row's field values plus filters — it never duplicates a temporary data set, so it cannot produce a multi-row snapshot on its own: the target's own data set stays empty. A real snapshot has to be built row by row.

## Requirements

Create a **codeunit** named `"Buffer Copy Service"` with two public procedures:

```al
procedure TakeSnapshot(var Source: Record "Name/Value Buffer" temporary; var Snapshot: Record "Name/Value Buffer" temporary)
procedure AttachSharedView(var Source: Record "Name/Value Buffer" temporary; var SharedView: Record "Name/Value Buffer" temporary)
```

Rules:

1. `TakeSnapshot` fills `Snapshot` with its own independent copy of every row currently in `Source` — same `ID`, `Name`, and `Value` on each row.
2. After `TakeSnapshot` returns, the snapshot is frozen: rows inserted into, modified in, or deleted from `Source` must not change what `Snapshot` holds.
3. Taking a snapshot only reads — every row of `Source` is still there afterwards, unchanged. (Moving `Source`'s current position while reading is fine; the tests only look at the rows.)
4. `AttachSharedView` makes `SharedView` a view onto `Source`'s own data set: a row inserted into or modified in `Source` afterwards is visible through `SharedView`, and a change written through `SharedView` is visible in `Source` — same data, two variables.
5. `Source` arrives without filters, and `Snapshot` / `SharedView` arrive empty — you don't need to clear or unfilter anything.
6. Everything is temporary; neither procedure writes to the database.

Pick object IDs in the range 50100–50199, and reference other objects by name, never by ID.

## What the tests check

The grading tests seed a temporary `"Name/Value Buffer"` with generated values, call one of your procedures, then mutate the source (insert, modify, delete) and check both directions: the snapshot must still hold exactly the rows and values from the moment it was taken, and the shared view must follow the source — including a write made through the view showing up in the source. A snapshot taken with `ShareTable = true` fails the frozen-in-time tests; a snapshot taken with a plain `Copy` fails the very first test, because it holds no rows.

## Learn More

- [Record.Copy(Record [, Boolean]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method) — what `Copy` transfers with and without `ShareTable`, and why `ShareTable` demands two temporary records.
- [Temporary tables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables) — how a temporary record variable holds an in-memory data set of its own.
- [Record.FindSet([Boolean]) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method) — the standard way to walk every row of a record set.
- [Insert, Modify, ModifyAll, Delete, DeleteAll, and Truncate methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-insert-modify-modifyall-delete-and-deleteall-methods) — the write methods; on a temporary record they touch only the in-memory copy.
