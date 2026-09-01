# Read the Token Before You Trust It

A partner's service now sends a JSON Web Token with every callback, and your integration is expected to act on what the token says: who issued it, which application it was minted for, and how long it stays good. The signing keys live with another team — verifying the signature is their job. Yours is the part that runs first and gets skipped most often: actually reading the token, and refusing it when its own claims say no.

A JWT is three dot-separated segments — header, payload, signature. The payload is a JSON object encoded with **base64url**: the same 6-bit encoding as Base64, except that `-` stands wherever Base64 writes `+`, `_` stands wherever Base64 writes `/`, and the trailing `=` padding is cut off entirely. Nothing in a JWT is encrypted; the payload is plain text to anyone who bothers to decode it.

## Requirements

Create a **codeunit** named `"JWT Claims Reader"` with three public procedures:

```al
procedure DecodePayload(Token: Text): Text
procedure GetClaim(Token: Text; ClaimName: Text): Text
procedure ValidateToken(Token: Text; AsOf: DateTime; AllowedIssuers: List of [Text]; AllowedAudiences: List of [Text]): Text
```

Rules:

1. A token is well-formed when it has exactly three dot-separated segments and none of them is empty. Anything else is malformed.
2. `DecodePayload` returns the token's **second** segment decoded back to text — the payload exactly as it was before encoding, character for character. For a malformed token it raises an error with a message that contains the text `must have three segments`.
3. `GetClaim` returns the value of the claim named `ClaimName` from the decoded payload, and `''` when the payload carries no such claim. The tests only ask for claims whose value is a JSON string, and the returned text is the string itself — no surrounding quotes.
4. `ValidateToken` never raises an error. It returns exactly one of six result codes, uppercase, single-spaced, as written here: `OK`, `MALFORMED`, `ISSUER NOT ALLOWED`, `AUDIENCE NOT ALLOWED`, `NOT YET VALID`, `EXPIRED`.
5. `ValidateToken` runs its checks in this order, and the first check that fails decides the answer: the token is well-formed and its payload is a JSON object (`MALFORMED`), the `iss` claim is one of `AllowedIssuers` (`ISSUER NOT ALLOWED`), the `aud` claim is one of `AllowedAudiences` (`AUDIENCE NOT ALLOWED`), the token is already usable (`NOT YET VALID`), the token has not run out (`EXPIRED`). A token that survives all five is `OK`.
6. `exp` and `nbf` are NumericDate values: whole seconds elapsed since 1970-01-01T00:00:00Z. `AsOf` is a UTC instant with zero milliseconds.
7. The token is `EXPIRED` when `AsOf` is at or after the instant `exp` names — landing exactly on `exp` is already too late. It is `NOT YET VALID` when `AsOf` is strictly before the instant `nbf` names — landing exactly on `nbf` means it is usable.
8. `exp` and `nbf` are optional: a payload without `exp` never runs out, and a payload without `nbf` is usable from any time. `iss` and `aud` are always present in the tokens the tests validate, and both are JSON strings.
9. Signature verification is out of scope. Ignore the third segment; the tests never check it.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

The tests decode fixed payload segments covering all three padding shapes (nothing stripped, one `=` stripped, two `=` stripped) plus one whose Base64 form needs `+` and `/`, comparing the decoded text with the original JSON character for character; a further test encodes a freshly generated payload of unpredictable length and expects it back unchanged, so a decoder tuned to the sample tokens fails. Three malformed tokens — two segments, four segments, and one with an empty middle segment — must make `DecodePayload` raise an error with a message that contains `must have three segments`. `GetClaim` is asked for a generated `sub` value and for a claim the payload does not carry (expecting `''`). Most `ValidateToken` calls pass the allow-lists `https://auth.contoso.com` / `https://auth.northwind.com` and `bc-integration`, and an `AsOf` of 2025-06-01T12:00:00Z, against tokens that sit inside their window, expire exactly at `AsOf`, expire one second after `AsOf`, become valid exactly at `AsOf`, become valid one second after `AsOf`, carry a foreign `iss`, carry a foreign `aud`, carry neither `exp` nor `nbf`, are structurally broken, decode to something that is not JSON, and one that breaks the issuer rule *and* is expired. Further calls hand the same procedure different arguments — allow-lists that name other issuers or another audience, and an `AsOf` three hours later and one an hour earlier — and expect the verdict to move with them, so an implementation that compares against the values printed above instead of reading its four parameters fails. The result codes are compared exactly — uppercase, spelled as in rule 4.

## Learn More

- [JsonObject data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type) — reading a JSON document out of text and asking it for a property.
- [JsonValue data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type) — turning a claim into the AL type you need, text or whole number.
- [Text.Split Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-text-method) — cutting the token into its segments.
- [About dates in Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-about-dates) — why every `DateTime` here is a UTC instant, and why guessing epoch arithmetic by hand goes wrong.
