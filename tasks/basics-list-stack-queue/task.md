# A Stack and a Queue on One List

An import routine collects work items as it goes: sometimes it needs to undo the most recent step (last in, first out — a stack), sometimes it needs to process items in the order they arrived (first in, first out — a queue). Both can live on one `List of [Text]`: new values always go on the back, and the only difference between the stack and the queue is which end you take from.

Along the way you will meet the four facts every AL developer trips over with lists: they are **1-based**, `Get(Index)` **raises an error** for an index outside the list while `Get(Index, var Value)` quietly returns `false`, `RemoveAt(1)` **shifts every remaining element down** one position, and `Remove(Value)` deletes **only the first occurrence** of a value.

## Requirements

Create a **codeunit** named `"Work Stack"` that keeps all its values in a single global variable of type `List of [Text]` (the starter already declares it as `Items`) and exposes these public procedures:

```al
procedure Push(Value: Text)
procedure Pop(var Value: Text): Boolean
procedure Peek(): Text
procedure Enqueue(Value: Text)
procedure Dequeue(var Value: Text): Boolean
procedure Discard(Value: Text): Boolean
procedure Reverse()
procedure Count(): Integer
```

Rules:

1. `Push` and `Enqueue` both append `Value` at the **back** of the list — they are the same operation seen from two sides. Any text may be stored, including an empty text and values that are already stored (duplicates are kept, in order).
2. `Pop` removes the value at the **back** (the one added most recently), hands it out through `Value`, and returns `true`. When nothing is stored it returns `false` and must not raise an error; what `Value` holds after a failed `Pop` is not graded.
3. `Peek` returns the value at the back **without removing it**. When nothing is stored it returns an empty text and must not raise an error.
4. `Dequeue` removes the value at the **front** (the oldest one still stored), hands it out through `Value`, and returns `true`. When nothing is stored it returns `false` and must not raise an error.
5. `Discard` removes the **first occurrence** of `Value` counted from the front and returns `true`; every other occurrence stays where it is. When the value is not stored it returns `false` and must not raise an error.
6. `Reverse` reverses the order of the stored values in place: after a `Reverse`, `Pop` hands out the values in the order they were added, and `Dequeue` in the reverse order.
7. `Count` returns the number of values currently stored — `0` when nothing is stored.

Because `Pop` and `Dequeue` report emptiness through their Boolean result, an empty text is a perfectly valid stored value: popping a stored `''` returns `true`.

Remember that the front of the list is index 1 and the back is index `Count()` — so on an empty list the back is index 0, which is not a valid index. Also read a value **before** you remove it: once `RemoveAt(1)` has run, the value that used to sit at index 2 is at index 1.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests drive one `"Work Stack"` instance per test with generated values and compare the exact sequence handed out by repeated `Pop` or `Dequeue` calls against the expected order (joined with commas, so a wrong order or a lost value is visible in the failure message). They pop after interleaved pushes and pops, pop and dequeue duplicates and expect every copy in the right position, call `Pop`, `Peek`, `Dequeue` and `Discard` on an empty instance and expect `false` / an empty text with no error, push an empty text and expect `Pop` to return `true`, mix `Push` and `Enqueue` and expect them to land in the same list, check `Count` after adds and removals, expect `Discard` to remove exactly one occurrence, verify that `Reverse` followed by repeated `Pop` yields the values in the order they were added (and `Peek` shows the oldest one right after the `Reverse`), and push one more value after a `Reverse` expecting it to pop first, ahead of the reversed values — so `Reverse` has to reorder the stored values rather than just change which end `Pop` reads from.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the full method table, and the remark that lists are 1-based.
- [List.Get(Integer, var T) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-get-integer-t-method) — the overload that returns `false` instead of raising when the index is outside the list.
- [List.RemoveAt(Integer) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-removeat-method) — removing by index; everything behind the removed element moves down.
- [List.Remove(T) method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-remove-method) — removes only the first occurrence and tells you whether it found one.
