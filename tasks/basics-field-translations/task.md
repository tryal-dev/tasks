# Multi-Language Descriptions with the Translation Module

Your company sells the same products across several markets, and sales wants every product description to show up in the buyer's language. Adding one field per language does not scale — Business Central's System Application ships a `Translation` module that stores per-record, per-field, per-language values instead, and your job is to wire a small product table to it.

## Requirements

The starter already contains a **table** named `"Localized Product"` with a `"Code"` field (`Code[20]`, the primary key) and a `Description` field (`Text[100]`) — you only need to finish its `OnDelete` trigger.

Create a **codeunit** named `"Product Translations"` with three public procedures:

```al
procedure SetDescription(ProductCode: Code[20]; LanguageId: Integer; Value: Text)
procedure GetDescription(ProductCode: Code[20]; LanguageId: Integer): Text
procedure DuplicateProduct(FromCode: Code[20]; NewCode: Code[20])
```

Rules:

- `SetDescription` stores `Value` as the translation of the product's `Description` field for `LanguageId`. Storing a value for a language that already has one replaces it.
- `GetDescription` returns the value stored for exactly `LanguageId`. When nothing is stored for that language, it returns the product's `Description` field value instead.
- `DuplicateProduct` creates a new `"Localized Product"` with `NewCode`, the same `Description`, and a copy of every stored translation, in every language. The tests always pass an existing `FromCode` and an unused `NewCode`.
- Deleting a `"Localized Product"` record removes every translation stored for it — and only its own. Put the cleanup in the table's `OnDelete` trigger; the tests delete with `Delete(true)` so the trigger runs.

Use the System Application's `Translation` codeunit for the storage — that is the point of the task. Two things about it fail silently if missed: a record must be **inserted** before you attach translations (the module keys every row by the record's `SystemId`), and the two-argument `Set`/`Get` overloads work on the *session* language — only the overloads taking a `LanguageId` can satisfy the per-language rules above. The three-argument `Get` returns an empty string when nothing is stored for the requested language.

`LanguageId` is a Windows locale ID — an integer such as 1031 (German), 1036 (French) or 1030 (Danish). The tests pass several distinct IDs and never rely on the language the test session happens to run in.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

The grading tests insert products and store generated description values for two languages, then read each language back; ask for a language with no stored value and expect the `Description` field value; store twice for the same language and expect the latest value; duplicate a product and expect the new record to carry the `Description` and both translations; and delete a product with `Delete(true)`, using the module's own `GetTranslations` to assert that the product's **two** translations actually live in the Translation module before the deletion and **zero** rows remain after it, while a second product keeps its own translation.

## Learn More

- [Translation codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.globalization.translation) — the full API you will build on: `Set`, `Get`, `Copy`, `Delete`, `GetTranslations`.
- [OnDelete (table) trigger](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/table/devenv-ondelete-table-trigger) — where record cleanup belongs and when the trigger actually runs.
- [Record.Delete method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-delete-method) — why the `RunTrigger` argument decides whether your cleanup fires.
- [Record.FieldNo method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-fieldno-method) — how to hand the `Description` field's number to the Translation API.
