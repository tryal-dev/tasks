# Value the Batch Before You Post It

The warehouse fills an item journal batch all day, and before posting it the controller wants to know what the batch is worth per item at today's list price. The preview used to be instant; now that batches span dozens of lines it drags, and the DBA's trace shows why: the same tiny SELECT against the Item table fired over and over — once per line, mostly asking about the same handful of items.

Your job: same numbers, a handful of statements.

## Requirements

Create a **codeunit** named `"Batch Valuation"` with one public procedure:

```al
procedure ValueByItem(TemplateName: Code[10]; BatchName: Code[10]): Dictionary of [Code[20], Decimal]
```

Rules:

1. Consider every `Item Journal Line` whose `"Journal Template Name"` equals `TemplateName` **and** whose `"Journal Batch Name"` equals `BatchName`. Both fields must match — the tests plant a line under another template carrying the very same batch name, and it must stay out.
2. The dictionary holds one key per distinct `"Item No."` on those lines — each **exactly once**, and only items that appear on at least one matching line. An item that exists in the Item table but sits on no matching line must not appear.
3. Each value is the sum, over that item's matching lines, of the line's `Quantity` multiplied by the item's current `"Unit Price"` from the `Item` card. No rounding is applied. Negative quantities reduce the value.
4. The price comes from the item card at call time. Lines carry a `"Unit Amount"` of their own — stamped when the line was entered, possibly stale — and the tests deliberately seed lines whose stamp disagrees with the card. The stamp must be ignored.
5. Every `"Item No."` on a matching line exists as an `Item` record; you do not need to handle missing items.
6. An item whose current `"Unit Price"` is 0 still appears — with a value of exactly 0.
7. A call that matches no lines returns an empty dictionary. The procedure never raises an error.
8. **The statement budget:** one call must execute **at most 6 SQL statements**, no matter how many lines the batch holds or how many distinct items they touch. Grading measures `SessionInformation.SqlStatementsExecuted` around a single call on a batch with a dozen-plus distinct items and several lines each: one round trip per line spends dozens of statements, and even one per **distinct** item spends 13+ — both fail. The prices must arrive in bulk.

## What the tests check

The grading tests seed items and journal lines marked `TRYAL-*`; prices, quantities and the number of items are generated fresh every run, so hardcoded answers fail. Decoys are planted: a line whose stamped `"Unit Amount"` disagrees with the item card, a line in another batch of the same template, a line under another template with the same batch name, and an item master record with no lines. A zero-price item must come back as exactly 0, and an empty batch as an empty dictionary. The tests assert **exact dictionary contents** — keys, counts and values. One test calls the procedure twice on the same codeunit instance and raises the item's `"Unit Price"` between the calls: the second call must return the new price, so any price or result remembered across calls fails (rule 4 is graded, not decorative). The budget test warms the caches with one throwaway call, then clears the codeunit variable, so the graded call runs on a cold instance and state kept between calls cannot subsidize the budget. It also invalidates the server's data cache — a repeated call served from cache memory costs zero SQL, so cached reads can't smuggle the chatter past the budget — and then snapshots the `SessionInformation` counter around a second call. The tests run in a real company with existing data, so your result must be driven purely by the two name filters and the rules above.

## Learn More

- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [Get, Find, and Next methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-find-and-next-methods)
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server)
- [Performance articles for developers](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/performance/performance-developer)
