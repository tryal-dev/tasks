# Deduplicate, Keep the Order

Your extension builds the CC line for order confirmations by gluing together addresses from several sources — the customer's contact card, the salesperson, a notification setup table. Nobody checks for overlaps, so the same address sneaks in two or three times, sometimes with different casing or stray spaces, and customers get triplicate emails. You are writing the cleaner every send now goes through.

## Requirements

Create a **codeunit** named `"Recipient Deduplicator"` with one public procedure:

```al
procedure Dedupe(Recipients: Text): Text
```

`Recipients` is a list of email addresses separated by semicolons (`;`). Entries may carry leading or trailing spaces, and the list may contain empty entries — nothing between two semicolons, or only spaces.

The returned text must follow these rules — all of them are graded:

1. Trim leading and trailing spaces from every entry; entries that are empty after trimming are dropped.
2. Two entries are duplicates when they are equal ignoring case: `Sales@Contoso.com` and `sales@contoso.com` are the same recipient.
3. Keep only the first occurrence of each recipient, in the order recipients first appear, with that first occurrence's original casing.
4. Join the kept entries with `'; '` — a semicolon followed by exactly one space, with no leading or trailing separator.
5. If nothing survives — empty input, or only semicolons and spaces — return an empty text (`''`).

## What the tests check

The tests call `Dedupe` and compare the returned text exactly — note rule 4's semicolon-plus-space. Fixed cases cover a single recipient, exact duplicates, duplicates differing only in casing, entries with surrounding spaces, empty entries, an empty input, and an input of only separators and spaces. One test builds a randomized list where every address reappears later in upper case with padding, so hardcoding the fixed examples fails.

## Learn More

- [Text.Split method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method)
- [Text.Trim method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method)
- [Text.ToLower method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-tolower-method)
- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [TextBuilder data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/textbuilder/textbuilder-data-type)
