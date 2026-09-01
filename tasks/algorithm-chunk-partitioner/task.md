# Balanced Chunks

A nightly job has thousands of document numbers to process, and you are fanning the work out to N background sessions. Each session takes one slice of the queue — and the slices must cover everything, keep the original order, and be as even as possible, so no session sits idle while another grinds through a double share. Today you build the slicer.

## Requirements

Create a **codeunit** named `"Chunk Partitioner"` with one public procedure:

```al
procedure Split(Items: List of [Text]; ChunkCount: Integer): List of [List of [Text]]
```

What the returned list of chunks must guarantee — all of it is graded:

1. It contains exactly `ChunkCount` chunks — always, even when there are fewer items than chunks.
2. Order is preserved: reading the chunks first to last, item by item, reproduces `Items` exactly — every item appears exactly once, nothing is dropped, nothing is invented.
3. The chunks are balanced: any two chunk sizes differ by at most one. With C items and N chunks, every chunk holds either the whole-number quotient of C ÷ N or that quotient plus one.
4. The extra items go to the front: exactly the first (C mod N) chunks hold the larger size. 7 items in 3 chunks split 3-2-2 — never 2-2-3 or 2-3-2.
5. Fewer items than chunks is not an error: 2 items into 5 chunks split 1-1-0-0-0, and an empty `Items` yields `ChunkCount` empty chunks. (This already follows from rules 1–4; it is spelled out so the trailing empty chunks are no surprise.)
6. If `ChunkCount` is zero or negative, `Split` must raise an error with a message that contains `Chunk count must be greater than zero` — the tests match that text as a substring, so note the exact wording.

Use object IDs from the range 50100–50199, and reference other objects by name, never by numeric ID.

## What the tests check

The tests call `Split` on fixed cases with exact expected content — 7 items into 3 chunks, 6 into 3, 4 into 1, 2 into 5, and an empty list into 4 — verifying chunk count, every chunk size, and every item position. Both invalid chunk counts (0 and negative) must raise the promised error. One more test runs a randomized item list with a randomized chunk count and re-checks all the guarantees, so hardcoding the fixed examples fails.

## Learn More

- [List data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type) — the collection you receive and return; the Remarks on reference-type behavior are worth a careful read for this task.
- [AL operators](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators) — the arithmetic and comparison operators available for working out the sizes.
- [Dialog.Error method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-error-string-joker-method) — raising the required validation error.
- [AL simple statements](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-simple-statements) — loops, conditions, and how `AssertError` tests grade the error case.
