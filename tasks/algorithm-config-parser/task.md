# Settings on a String

Your extension keeps its integration settings in a single Text value — `retries=3;timeout=30;endpoint=https://api.example.com` — the way BC apps often stash options in an Isolated Storage entry or one setup field. Right now every feature re-splits that string by hand, and each copy of the code disagrees about spaces, duplicates, and broken entries.

Your job is the one parser they should all call: turn the raw string into a `Dictionary of [Text, Text]` with well-defined rules for trimming, duplicates, and malformed entries.

## Requirements

Create a **codeunit** named `"Config Parser"` with one public procedure:

```al
procedure Parse(Config: Text): Dictionary of [Text, Text]
```

Parsing rules — all of them are graded:

1. Entries are separated by `;`. Entries that are empty or only spaces (a double `;;`, a trailing `;`, a blank segment) are skipped.
2. Each entry is cut at its **first** `=`: the part before it is the key, and everything after it is the value — so a value may itself contain `=` (think base64 like `abc==`).
3. Keys and values are trimmed of leading and trailing spaces; spaces inside them are preserved (`log level = verbose mode` → key `log level`, value `verbose mode`).
4. A value that is empty after trimming is fine: the key maps to an empty text.
5. When the same key appears more than once, the **last** occurrence wins — the dictionary holds one entry for that key, with the last value.
6. Keys are case-sensitive: `Mode` and `mode` are two different keys.
7. An entry that has no `=`, or whose key is empty after trimming (like `=5`), is invalid: raise an error with a message that contains `Invalid config entry`.
8. An empty or all-spaces `Config` yields an empty dictionary.

## What the tests check

The tests call `Parse` and verify every rule above: a plain two-entry config, spaces around keys and values, values containing `=`, an empty value, skipped empty segments, last-one-wins duplicates, case-sensitive keys, the `Invalid config entry` error for an entry with no `=` and for an empty key (substring match on the message), empty and all-spaces input, and one config assembled from randomized keys and values so hardcoding the examples fails. Key and value comparisons are exact — trimming must remove all leading and trailing spaces and nothing else.

## Learn More

- [Dictionary data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type)
- [Text.Trim method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-trim-method)
- [Text.IndexOf method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-indexof-method)
- [Text.CopyStr method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
- [AL error handling](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling)
