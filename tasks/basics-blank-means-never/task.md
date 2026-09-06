# The Certificate That Expired Before It Existed

Your company ships hazardous goods only to customers who hold a valid handling certificate, so each customer carries the date the certificate runs out. Compliance asked for two small helpers: a check that tells whether a customer's certificate has expired as of a given date, and, for any list of customers, the date on which the first certificate in that list runs out, so renewal reminders go out in time.

Not every customer needs a certificate. Those customers leave the expiry blank, and a blank expiry means **never expires**. The first version of the code, the one in your starter, gets both helpers wrong in the same way: every customer without a certificate is reported as expired, and the earliest expiry of any list containing such a customer comes back blank. The reason is a single sentence in the documentation of the Date type: the undefined date `0D` is considered to be **before all other dates**. A blank certificate expired before it ever existed.

## Requirements

1. Create a **table extension** that extends the `Customer` table.
2. Add a field named `"Certificate Expiry"` of type `Date`. The starter already declares it; keep the name exactly.
3. Create a **codeunit** named `"Customer Certificates"` with two public procedures:

```al
procedure IsExpired(var Customer: Record Customer; AsOf: Date): Boolean
procedure EarliestExpiry(var Customer: Record Customer): Date
```

Rules:

1. `IsExpired` looks at the single customer record it is given and returns `true` when that customer's `"Certificate Expiry"` is a real date **strictly before** `AsOf`. A certificate is valid through its expiry date: an expiry equal to `AsOf` is not expired, and neither is a later one. `AsOf` is always a real date.
2. A blank `"Certificate Expiry"` (`0D`) means the certificate never expires, so `IsExpired` returns `false` for it whatever `AsOf` is.
3. `EarliestExpiry` works on the set of customers the caller has already filtered: it considers every customer inside the filters on the record it is given and no customer outside them. It returns the earliest `"Certificate Expiry"` among the customers in that set that have one. Blank expiries are skipped; they are never the minimum.
4. `EarliestExpiry` returns `0D` only when no customer in the set has a real expiry, because every one of them is blank or the set is empty.
5. `EarliestExpiry` leaves the caller's filters as it found them. After the call the record must still show the same customers, blank ones included. If you want to filter on the expiry field yourself, do it on a copy of the record, not on the record you were given.

Mind the blank date. `0D` is smaller than every real date, so comparing it with `<` calls it expired, a running minimum that lets it in never returns anything else, and sorting the set by `"Certificate Expiry"` puts the blank customers first. Decide the blank case before you compare.

## What the tests check

The grading tests insert customers whose `"No."` starts with `TRYAL-CE`, set `"Certificate Expiry"` directly, and call your procedures with explicit dates; nothing depends on today's date or the work date. For `IsExpired` they check a certificate that expired the day before `AsOf` (expired), one that expired a random number of days earlier (expired), one expiring exactly on `AsOf` (not expired), one expiring a random number of days later (not expired), and a blank expiry checked against a random `AsOf` (not expired). For `EarliestExpiry` they filter the record on `"No."` to a marked group of customers and expect: the smallest of four random real dates that are not inserted in date order; the earliest real date when blank customers sit before, between and after the dated ones; `0D` when every customer in the group is blank; `0D` when the filter matches no customer at all; the earliest date inside the filter even though a customer outside it expires earlier; and, after the call, the caller's record still counting every customer of the group with no filter left on `"Certificate Expiry"`.

Pick object IDs in the range 50100–50199 and reference other objects by name, never by ID.

## Learn More

- [Date data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type) — the one sentence behind the whole bug: the undefined date is considered to be before all other dates.
- [Record.FindSet method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-findset-boolean-method) — loop over the filtered set with `repeat … until Next() = 0`.
- [Record.Copy method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method) — take a private copy of a record, filters included, when you want to filter without touching the caller's record.
- [Table extension object](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object) — the object that adds the field to `Customer`.
