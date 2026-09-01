# Compose Endpoint URLs with Uri Builder

Your extension talks to the fictional Nordwind item catalog service, and the previous integration glued its URLs together with plain string concatenation. That worked until a purchaser searched for `salt & pepper set=deluxe` — the `&` and `=` were read as query syntax instead of data, and the service quietly answered a different question. You will rebuild the three URL helpers so that every input travels as *data*, correctly percent-encoded, never as URL syntax.

The System Application ships everything you need: `Codeunit "Uri Builder"` (`Init`, `SetPath`, `AddQueryParameter`, `AddQueryFlag`, and the `Enum "Uri Query Duplicate Behaviour"` policy for keys that already exist) and `Codeunit Uri` (`GetAbsoluteUri`, `EscapeDataString`). One trap to know up front: `AddQueryParameter` and `AddQueryFlag` percent-encode their keys and values for you, but `SetPath` treats its input as a ready-made path — a value you splice into the path as a segment is **not** treated as data, so an `&` or `=` inside it survives unencoded unless you escape that segment yourself.

## The service

- Search: `GET https://api.nordwind.example/v1/items` with query parameter `search` (the search term), query parameter `pageSize` (a number), and the valueless query flag `includeArchived`.
- Item card: `GET https://api.nordwind.example/v1/items/{itemNo}` — the item number is exactly one path segment.
- Export: the caller supplies the full endpoint URL, which may already carry query parameters — including a `format` parameter it wants replaced.

## Requirements

Create a **codeunit** named `"Endpoint Url Builder"` with three public procedures:

```al
procedure ItemSearchUrl(SearchTerm: Text; PageSize: Integer): Text
procedure ItemCardUrl(ItemNo: Text): Text
procedure ExportUrl(BaseUrl: Text; FileFormat: Text): Text
```

Encoding rule (it is exactly what `Uri.EscapeDataString` does): every character except ASCII letters, digits and `-` `.` `_` `~` is percent-encoded from its UTF-8 bytes with uppercase hex — a space becomes `%20` (never `+`), `&` becomes `%26`, `=` becomes `%3D`, `+` becomes `%2B`, and a non-ASCII letter like `é` becomes `%C3%A9`.

1. `ItemSearchUrl` returns `https://api.nordwind.example/v1/items?search=<encoded SearchTerm>&pageSize=<PageSize>&includeArchived` — the parameters in exactly that order, `PageSize` as plain digits, and `includeArchived` last as a flag with no `=` sign.
2. `ItemCardUrl` returns `https://api.nordwind.example/v1/items/<encoded ItemNo>` — the whole item number encoded as one path segment, and no query string.
3. `ExportUrl` returns `BaseUrl` with the query parameter `format` set to `FileFormat`: parameters the base URL already has keep their values and their first-appearance order; if one or more `format` parameters already exist, exactly one `format=<FileFormat>` remains, in the position where `format` first appeared; if none exists, `format=<FileFormat>` is appended at the end.

Worked examples, character for character:

- `ItemSearchUrl('desk lamp', 25)` → `https://api.nordwind.example/v1/items?search=desk%20lamp&pageSize=25&includeArchived`
- `ItemCardUrl('A&B=100+')` → `https://api.nordwind.example/v1/items/A%26B%3D100%2B`
- `ExportUrl('https://api.nordwind.example/v1/items/export?compress=true&format=pdf', 'xlsx')` → `https://api.nordwind.example/v1/items/export?compress=true&format=xlsx`

You may rely on these guarantees about the inputs:

- `SearchTerm` and `ItemNo` are never empty and consist of letters (including non-ASCII letters such as `é` or `Ø`), digits, spaces, and the characters `&` `=` `+` `-` `.` — never `%`, `/`, `?` or `#`.
- `PageSize` is between 1 and 500.
- `BaseUrl` is a valid absolute `https` URL with a path and no fragment; any query parameters it already carries use plain unencoded ASCII letters and digits for keys and values (no `%`-escapes, no `+`).
- `FileFormat` is plain lowercase ASCII letters.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

Every test calls one procedure and compares the returned text with the expected absolute URL **character for character** — note the exact parameter order, the uppercase hex, and `%20` rather than `+`. The search tests cover a plain two-word term, a term full of `&` `=` and spaces, a non-ASCII term, and a randomly generated term with a random page size — so hardcoding the examples fails. The item card tests cover a space, the reserved characters `&` `=` `+`, and a non-ASCII item number. The export tests cover a base URL with no query at all, one with an existing parameter but no `format` (so `format` must land at the end, after it), one whose existing `format` must be replaced in place while its neighbor parameter survives untouched, and one carrying two `format` parameters that must collapse into a single replaced one.

## Learn More

- [Uri Builder codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.uri-builder) — the full API: `Init`, `SetPath`, `AddQueryParameter`, `AddQueryFlag`, `GetUri`.
- [Uri codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.uri) — `GetAbsoluteUri` and `EscapeDataString` live here.
- [Uri Query Duplicate Behaviour enum](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/enum/system.utilities.uri-query-duplicate-behaviour) — the policies for a query key that already exists.
- [Uri.EscapeDataString method (.NET)](https://learn.microsoft.com/en-us/dotnet/api/system.uri.escapedatastring) — the escaping rules the AL wrapper follows.
