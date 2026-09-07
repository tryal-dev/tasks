# The Filter That Stayed

The sales manager's role center shows three cues fed by the `"Order Counter"` codeunit: the open orders of the customer being looked at, the orders of a handful of key accounts, and the total number of orders. Each tile is right on its own. But drill into one customer and the **All orders** tile collapses to a handful; refresh the key-accounts tile a few times and its number keeps growing. The page keeps a single `"Order Counter"` instance and calls the procedures in whatever order the user clicks — and all three procedures were written against one shared record variable.

## Requirements

The starter contains a **codeunit** named `"Order Counter"` with three public procedures:

```al
procedure CountOpenOrders(CustomerNo: Code[20]): Integer
procedure CountOrdersForCustomers(CustomerNos: List of [Code[20]]): Integer
procedure CountAllOrders(): Integer
```

Each of them returns the right number when it is the first call on a fresh instance. Fix the codeunit so that every call is independent of the calls before it, keeping the object name and the three signatures exactly as they are.

Rules:

1. `CountOpenOrders` returns the number of `Sales Header` records whose `"Document Type"` is `Order`, whose `"Sell-to Customer No."` equals `CustomerNo`, and whose `Status` is `Open`. Orders in any other status and documents of any other type (quotes, invoices, ...) do not count.
2. `CountOrdersForCustomers` returns the number of `Sales Header` records whose `"Document Type"` is `Order` and whose `"Sell-to Customer No."` is one of the numbers in `CustomerNos`, whatever their `Status`. Each order counts once. The list is never empty.
3. `CountAllOrders` returns the number of `Sales Header` records whose `"Document Type"` is `Order` — every customer, every status.
4. The caller keeps a single `"Order Counter"` instance and calls the three procedures in any order, any number of times. Every call returns exactly the number defined above for its own arguments: nothing an earlier call on the same instance did may narrow, widen, or otherwise change a later result.

Pick your object ID in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests create fresh customers with the standard test library and give them sales orders in mixed statuses (`Open`, `Released`, `Pending Approval`) plus a sales quote as a decoy, so a customer's counts are exactly the orders the test seeded for it. Three tests call one procedure once on a fresh instance: the open orders of a customer (a run-time-generated number of them, next to a released order, a quote and another customer's order), the orders of two listed customers next to a third that is not listed, and the total of all orders. The other tests use one instance for two calls and check the second: `CountAllOrders` after `CountOpenOrders`, `CountOpenOrders` after `CountAllOrders`, `CountOpenOrders` for a second customer after a first, `CountOrdersForCustomers` after `CountOpenOrders` (its released orders must still count), `CountAllOrders` and `CountOpenOrders` after `CountOrdersForCustomers`, and `CountOrdersForCustomers` twice with two different lists. The tests run in a shared company that already contains sales orders, so the expected value of `CountAllOrders` is computed independently from the database in each test rather than hardcoded. Every comparison is exact, and a failure shows both the expected and the actual count.

## Learn More

- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods) — what a `SetRange` does to the filter already on that field, and what it leaves alone.
- [AL variables](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables) — a global variable belongs to every method of the object; a local one to a single call.
- [Record.Mark method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-mark-method) — marks belong to one record variable and survive every filter change.
- [Record.MarkedOnly method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method) — the special filter that makes the marked records the record's whole view.
