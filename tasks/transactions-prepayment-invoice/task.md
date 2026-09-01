# Take the Deposit First

Nobody starts a bespoke build without money on the table. Business Central calls that money a prepayment: you tell the sales order what share of it is a deposit, invoice that share on its own, and when the goods finally ship the deposit comes off the final bill automatically. Doing it from the Sales Order page is three clicks. Doing it from code — and getting the deposit to land on the right account, on the right lines, and off the right invoice — is this task.

Write one codeunit named `"Sales Deposit Manager"`. The grading tests bind to these four signatures character for character, so copy them exactly:

```al
procedure SetDeposit(var SalesHeader: Record "Sales Header"; DepositPct: Decimal; CompressLines: Boolean)
procedure PostDeposit(var SalesHeader: Record "Sales Header"): Code[20]
procedure PostFinalInvoice(var SalesHeader: Record "Sales Header"): Code[20]
procedure RemoveLine(var SalesLine: Record "Sales Line")
```

Pick an object id in the range 50100–50199, and reference every other object by name, never by id.

## What the tests hand you

The tests own the fixture; your code never creates master data. Before each call they build a customer, a G/L account to sell, a general posting setup whose `"Sales Prepayments Account"` is a real G/L account, and a sales document of type `Order` with one or two `G/L Account` lines whose line amounts are whole hundreds. Nothing on the order is prepaid yet: `"Prepayment %"` is zero and the lines' prepayment fields are empty.

## Requirements

1. `SetDeposit` puts `DepositPct` on the order **and on each of its lines**: afterwards every line's `"Prepayment %"` is `DepositPct`, and its `"Prepmt. Line Amount"` is that percentage of the line amount, rounded to the cent. It also records `CompressLines` in the order's `"Compress Prepayment"` field. All of it must reach the database — the tests re-read the order and its lines from the database, not from the record variable they passed in.
2. `PostDeposit` posts the order's prepayment invoice and returns the number of the posted prepayment invoice. The posted document must be a real prepayment invoice raised against this order (`"Prepayment Invoice"` set, `"Prepayment Order No."` pointing back at the order), its amount must land on the general posting setup's `"Sales Prepayments Account"` as a credit for the deposit excluding VAT, and every order line must come back carrying its own share of the deposit in `"Prepmt. Amt. Inv."`. The order itself survives — this is an invoice for part of it, not the end of it.
3. `PostFinalInvoice` ships and invoices the whole order in one go and returns the number of the posted sales invoice. The customer ledger entry behind that invoice must charge the order total including VAT **minus** the deposit already invoiced, to the cent.
4. `RemoveLine` takes a line off the order. A line whose deposit has already been invoiced may not be removed: the attempt must fail with an error that names the field `Prepmt. Amt. Inv.`, and the line must still be on the order afterwards. A line with nothing invoiced on it is simply removed, leaving the rest of the order alone.
5. Neither posting routine may commit. Most grading tests run inside a single transaction that is rolled back at the end, so a commit performed by your code — or by the platform code your code calls — fails them outright with a commit-not-allowed error.

Two things the tests take care of, so don't build them yourself: posting a deposit moves the order into the `Pending Prepayment` status, and the tests reopen the order themselves before they try to remove a line.

## What the tests check

Eleven tests walk the round trip: a generated deposit percentage reaching the header and both lines with the right `"Prepmt. Line Amount"` on each; `CompressLines = false` landing in `"Compress Prepayment"`; `PostDeposit` returning a posted document flagged as a prepayment invoice for this order; the sales prepayments account credited with exactly the deposit excluding VAT; `"Prepmt. Amt. Inv."` on each line equal to that line's share; the final invoice's customer ledger entry equal to the order total including VAT less the deposit. Three compression cases: two lines sharing the prepayment account and the dimensions collapse into one prepayment line carrying both deposits, the same two split in two once each carries a different dimension value, and without compression every order line always gets its own prepayment line. Two removal cases: a prepaid line refused with an error naming `Prepmt. Amt. Inv.` and still on the order afterwards, and a line with nothing invoiced on it gone while its neighbour is untouched. Amounts are compared exactly, except the final invoice total, which is allowed one cent of rounding.

## Learn More

- [Invoicing prepayments](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-invoice-prepayments) — the round trip in business terms, including why a prepaid line cannot just be deleted.
- [Set up prepayments](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-set-up-prepayments) — where the sales prepayments account and the prepayment number series live, and how a percentage set on the header relates to the lines.
- [Create prepayment invoices](https://learn.microsoft.com/en-us/dynamics365/business-central/finance-how-to-create-prepayment-invoices) — spells out exactly when Compress Prepayment merges lines and when it does not.
- [Walkthrough: Set up and invoicing sales prepayments](https://learn.microsoft.com/en-us/dynamics365/business-central/walkthrough-setting-up-and-invoicing-sales-prepayments) — the same flow clicked through end to end, deposit first and final invoice last.
