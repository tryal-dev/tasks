# Print in the Customer's Language

Sales ships all over Europe, and the people who receive your order confirmations do not all read English — which is why every customer card carries a `Language Code`. Producing a document in the recipient's language means switching the session into that language for the duration of the printout; forgetting to switch it back is the classic production bug, and it surfaces an hour later as a French error message on a Danish user's screen.

## Requirements

Create a **codeunit** named `"Document Language Mgt."` with four public procedures:

```al
procedure GreetingInSessionLanguage(): Text
procedure ConfirmationLineFor(CustomerNo: Code[20]): Text
procedure WireTagFor(CustomerNo: Code[20]): Text
procedure AuditLineFor(CustomerNo: Code[20]): Text
```

Rules:

1. `GreetingInSessionLanguage` takes no arguments. As with a report label, the only thing that tells it which language to speak is the language the session is running in — `GlobalLanguage()`. The greeting is keyed on the **two-letter ISO name** of that language, which codeunit `Language` hands out through `GetTwoLetterISOLanguageName`:
   - `en` → `Thank you for your order.`
   - `da` → `Tak for din ordre.`
   - `fr` → `Merci pour votre commande.`
   - every other language → the `en` text.
2. Regional variants share their ISO name: a session running in Canadian French (language ID 3084) is `fr` exactly like French (1036), and British English (2057) is `en` exactly like en-US (1033).
3. Where the three texts live is up to you, and only the returned text is graded — but note the dead end: a plain `Label` gets its translations from XLIFF files, which a submission cannot ship, so the texts have to be picked by your own code from the session language.
4. `ConfirmationLineFor` produces one document line for a customer: the customer's `Name`, a colon, one space, then the greeting **in that customer's language** — `Contoso Ltd: Tak for din ordre.` Note the colon and the single space.
5. A customer's language is whatever its `Language Code` field resolves to. A customer with no language code, or with a code that no `Language` record backs, gets the language the **session** is currently running in — not en-US. Codeunit `Language` already implements exactly that fallback in `GetLanguageIdOrDefault`; a hardcoded 1033 is the wrong answer.
6. The line is printed into a `Text[100]` field. When the finished line is longer than 100 characters, raise the error `The confirmation line does not fit in 100 characters.` The three texts have different lengths, so one and the same customer name can fit in Danish and overflow in English.
7. Whatever the three customer procedures do internally, the session language must be exactly what it was when they were called — after a normal return **and** after the error in rule 6. AL has no `try ... finally`, so the error path needs a plan of its own.
8. `WireTagFor` returns the two-letter ISO name of the customer's resolved language (`da`, `fr`, `en`, …), the language tag your integration puts on the wire. The customer's language is resolved exactly as in rule 5.
9. `AuditLineFor` returns the same line as rule 4, but always in the application's default language — whatever the customer's language code says, and whatever language the session happens to be running in. Ask codeunit `Language` for that default (`GetDefaultApplicationLanguageId`) instead of hardcoding 1033. The audit copy has no length limit.

The tests always pass a customer number that exists.

`Language.ToDefaultLanguage()` is the sibling of rule 9 for *values*: it formats a variant — a date, a decimal, a boolean — in the default language. This task's audit copy is about the texts, so `GetDefaultApplicationLanguageId` is the one you need here.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The grading tests run `GreetingInSessionLanguage` with the session switched to Danish, French, Canadian French, British English, German and one further regional variant this statement does not name, and compare the returned text character for character — final full stop included — with German falling back to the English text. Only the ISO name of the session language decides, so a hand-written list of language IDs loses on the variant it never heard of. They then create customers whose `Language Code` resolves to Danish, is blank, or is a code that no `Language` record backs, call `ConfirmationLineFor` from sessions running in en-US, French and Danish, and compare the whole line: a fallback that reaches for en-US instead of the session language fails there. One customer's name is exactly 80 characters long, so its Danish line lands on the 100-character limit exactly and must come back intact; another is 85 characters long and must raise the error text, matched as it is written above. Four tests read `GlobalLanguage()` immediately after the call — after a successful line, after the failing one, after an audit copy and after a wire tag — and expect the language the test started in. The wire-tag tests expect `da` for a Danish customer, `de` for a German one — a language with no greeting of its own still has a tag — and `fr` for a customer with no language code in a French session. The audit tests expect the English line for a Danish customer even when the session itself is running in French, and one of them passes a 95-character name and expects the whole 122-character line back, so the 100-character check must not sit anywhere the audit copy passes through.

## Learn More

- [Language codeunit (System Application)](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.globalization.language) — `GetLanguageIdOrDefault`, `GetTwoLetterISOLanguageName` and `GetDefaultApplicationLanguageId`, the API this task is built on.
- [GlobalLanguage method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-globallanguage-method) — reading and setting the session language, and what a language ID is.
- [Report.Language method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-language-method) — how the base application prints documents in the recipient's language, with the very same resolution call.
- [Working with translation files](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files) — where AL texts get their translations from, and why the session language is what selects them at run time.
