# Union of Two Filtered Sets

Marketing is launching a phone campaign, and the callers want one list built from two rules: every customer located in the campaign city, plus every key account — a customer whose credit limit reaches a threshold — wherever they live. Two easy filters, except the rules live on two different fields, the callers want a single list, and nobody may be called twice.

## Requirements

Create a **codeunit** named `"Campaign Call List"` with one public procedure:

```al
procedure BuildCallList(var Customer: Record Customer; CampaignCity: Text; VipCreditLimit: Decimal)
```

Rules:

1. The caller hands you a fresh `Customer` record variable (no filters, no special state) and afterwards reads the list by iterating that same variable with `FindSet`/`Next` — whatever view your procedure leaves on the record IS the call list.
2. The list contains every customer whose `City` equals `CampaignCity` — the whole value, exactly (a customer in `Northport` is not in the city `North`).
3. The list also contains every customer whose `"Credit Limit (LCY)"` is at or above `VipCreditLimit`, whatever their city — a credit limit exactly equal to the threshold qualifies.
4. Nobody is called twice: a customer matching both rules is visited exactly once when the caller iterates the list.
5. Nobody else is called: a customer matching neither rule must not appear in the list.
6. The procedure only shapes which records the caller sees — it must not insert, modify, rename or delete any customer.
7. The caller may iterate the list several times; every pass must visit the same customers.

## What the tests check

The grading tests seed customers with unique city-name markers and run-time-generated credit limits, call `BuildCallList` once, then iterate the record your procedure shaped, counting how often each seeded customer is visited: qualifying customers exactly once, non-qualifying decoys never. Expect a decoy city that merely starts with the campaign city's name, a credit limit one cent below the threshold next to one exactly at it, a customer matching both rules who must show up exactly once, and a customer matching neither rule who must both stay off the list and still exist in the database after the call — the tests also re-read every seeded customer afterwards and verify it still exists and is completely unchanged, field for field, so any write to a customer fails grading even if the value is later restored. The tests run in a real company with other customers present — that's fine; the assertions only look at the customers the tests seed.

## Learn More

- [Record.Mark Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-mark-method)
- [Record.MarkedOnly Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-markedonly-method)
- [Record.ClearMarks Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-clearmarks-method)
- [Record.Reset Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-reset-method)
- [Record.SetFilter Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
