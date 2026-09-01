# Unique, Except When Blank

Finance has had enough of paying the same purchase order twice. From now on, a customer's external document no. must appear at most once in the document register: one PO number, one document. The catch is that most documents arrive without a PO number at all, and a register full of blank external document nos. is completely normal — the rule is uniqueness with a hole in it, and the hole has to stay open no matter how many documents fall into it.

## Requirements

1. Create a **table** named `"Customer Document Register"` with these fields:
   - `"Customer No."` of type `Code[20]`
   - `"Document No."` of type `Code[20]`
   - `"External Document No."` of type `Code[35]`
   - `Description` of type `Text[100]`
2. The **primary key** is the pair `"Customer No.", "Document No."`, in that order.
3. **The rule:** within one `"Customer No."`, no two records may carry the same `"External Document No."` — unless it is blank. Blank is exempt: one customer may hold any number of records whose `"External Document No."` is `''`.
4. Customers are independent of each other: the same external document no. on two records of two different customers is perfectly fine.
5. A write that would break rule 3 must fail with an `Error`, and must leave the register exactly as it was. The tests write through `Insert(true)`, `Modify(true)` and `Rename` — all three of those paths have to be guarded.
6. The error message must contain the exact phrase `already used on document` — lower case, exactly as written — and the `"Document No."` of the record it **collides with**. The `"Document No."` of the record being written must not appear in the message at all: the tests assert that the colliding one is in there and the written one is not. `External document no. PO-4711 is already used on document SO-1042 for customer C00030.` satisfies all of that; naming the external document no. and the customer as well is good practice but not graded.
7. Every write that does **not** break rule 3 must go through untouched. In particular:
   - a second and a third record with a blank `"External Document No."` for the same customer;
   - two records of one customer carrying different non-blank external document nos.;
   - a record of another customer carrying an external document no. that the first customer already uses;
   - saving a record again with `Modify(true)` without touching its `"External Document No."` — a record must never collide with itself;
   - clearing a record's `"External Document No."` back to blank;
   - renaming a record to a new `"Document No."` within its own customer while it keeps its external document no. — again, a record must never collide with itself.
8. **The budget:** one `Insert(true)` of a new record must execute at most **10 SQL statements** and read at most **25 rows**, no matter how many documents the customer already has. Grading snapshots `SessionInformation.SqlStatementsExecuted` and `SessionInformation.SqlRowsRead` around a single insert while the customer already holds a couple of hundred documents — an implementation that pulls the customer's documents into AL to compare them one by one reads them all and fails.

Pick object IDs in the range **50100–50199** and reference other objects **by name, never by ID**.

## What the tests check

The grading tests write to your table directly — `Insert(true)`, `Modify(true)` and `Rename`, on customers created through the standard number series, so the graded customer numbers drift from run to run and nothing can be pattern-matched, and with generated external and internal document nos., drawn fresh for every run — and they check both directions of the rule. Legal writes must simply succeed: three blanks in a row for one customer, distinct external document nos. for one customer, the same external document no. on another customer, a `Modify(true)` that only changes `Description`, a clear back to blank, and a rename inside the same customer. Illegal writes must fail: a second record with the same non-blank external document no. for one customer, a `Modify(true)` that turns a record into a duplicate, and a `Rename` that moves a record onto a customer that already uses its external document no.; for the failures the tests read `GetLastErrorText` and require the phrase from rule 6 plus the conflicting record's `"Document No."`, and not the `"Document No."` of the record being written — only your own message is asserted, never the platform's — and they verify that the rejected record never made it into the register while the records that were already there are untouched. One test reads back the declared maximum lengths of the four fields, and one last test warms the caches with a throwaway insert, invalidates the server data cache (a repeated cached read costs zero SQL and would smuggle row-by-row work past the budget), and then measures the counters of rule 8 around a single insert for a customer holding roughly two hundred documents.

## Learn More

- [Table keys](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-keys) — primary keys, secondary keys and what a unique index does and does not promise.
- [Record.Rename Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method) — what renaming really does to a record, and when the change reaches the database.
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling) — raising an error that stops a write, and the guidelines for what to say in it.
- [AL database methods and performance on SQL Server](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/optimize-sql-al-database-methods-and-performance-on-server) — which record methods cost one row and which cost the whole set.
