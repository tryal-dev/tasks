# The Filter That Crashed the Nightly Job

Your extension's setup table has a text field where consultants type a customer filter — `1000..2000|3000`, the platform's own filter idiom — and a nightly job later slams that text straight into `SetFilter`. Last Tuesday somebody saved `1000..2000|` with a trailing pipe, and the job died at 02:13 with an error nobody saw until morning. You are writing the syntax check the setup page will run before accepting the value, so a malformed filter is rejected at entry time instead of at 2 AM.

## Requirements

Create a **codeunit** named `"Filter Expression Check"` with one public procedure:

```al
procedure IsValid(Expression: Text): Boolean
```

The procedure returns `true` when the expression follows the mini filter grammar below, and `false` otherwise — it must never raise an error, no matter how mangled the input is.

The grammar is a deliberate subset of Business Central's real filter syntax (`<>`, `*`, `@`, `&` and friends are out of scope — and therefore illegal here). All seven rules are graded:

1. An expression is one or more **alternatives** separated by `|`. Every alternative must be non-empty: a leading `|`, a trailing `|`, or a doubled `||` makes the expression invalid, and the empty expression is invalid too.
2. An alternative is either a **group** — a complete expression wrapped in parentheses, like `(1000..2000|3000)` — or a single **value or range**. A group is the whole alternative: it cannot be glued to other values or groups.
3. A **range** is `low..high`, `low..`, or `..high`; every bound that is present must be a single value. A bare `..`, a second `..` in the same alternative (`1..2..3`), or a group used as a bound (`(1|2)..5`) is invalid.
4. A **value** is either an unquoted token or a quoted value. An unquoted token is one or more letters `A`–`Z`/`a`–`z` or digits `0`–`9` — nothing else, no exceptions.
5. A **quoted value** is wrapped in single quotes `'`. Inside the quotes every character is plain data — `|`, parentheses, dots and spaces do not act as operators there. A literal quote inside is written doubled (`'O''Brien'`), and `''` is a valid, empty value. A quote that never closes makes the expression invalid, and after a closing quote only `..`, `|`, `)`, or the end of the expression may follow.
6. Parentheses outside quotes must be balanced and properly nested, and a group must contain a valid expression — `()`, `(1000..2000`, `1000)` and `)(` are all invalid.
7. Outside quotes, only these characters are legal: letters, digits, `|`, `(`, `)`, `'`, and `.` as one half of a `..` operator. A space, a `-`, a lone dot (`1.5`) — anything else anywhere outside quotes — invalidates the whole expression.

The check is purely syntactic: whether `low` actually sorts before `high`, or whether any customer matches, is not its business.

## What the tests check

The tests call `IsValid` on valid expressions — a single token, token alternatives, `1000..2000|3000`, open-ended ranges in both directions, a quoted value full of operator characters, a doubled quote, the empty quoted value `''`, quoted range bounds `'A'..'M'`, groups, nested groups, and a parenthesis inside quotes that must not count toward balancing — and on invalid ones: the empty expression, leading/trailing/doubled `|`, bare `..`, `1..2..3`, a space outside quotes, a hyphen, a wildcard `*`, an `@`, an `&`, a lone dot, an unclosed `(`, a stray `)`, `)(`, `()`, an unterminated quote, a quote "closed" only by the escape `''`, text glued after a closing quote, and a group used as a range bound. Two more expressions are assembled from randomized tokens — one valid, one corrupted — so hardcoding the examples fails.

## Learn More

- [Entering criteria in filters](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-entering-criteria-in-filters)
- [Record.SetFilter(Any, Text [, Any,...]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method)
- [Filtering records with the SetRange, SetFilter, GetRangeMin, and GetRangeMax methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-setcurrentkey-setrange-setfilter-getrangemin-and-getrangemax-methods)
- [Text data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type)
- [Text.CopyStr(Text, Integer [, Integer]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-copystr-method)
