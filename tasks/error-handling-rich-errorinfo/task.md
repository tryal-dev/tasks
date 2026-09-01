# Errors Worth Reading

The warehouse picking app stops a short pick with a one-line error — and that line is all anyone ever gets. Support keeps asking users for screenshots because the message is the only trace of what happened, telemetry has no numbers to filter on, and the upcoming batch-validation feature cannot gather the error at all: the moment it fires, everything stops. Your job is to keep the same guard rule but raise an error that carries real information.

## Requirements

Create a **codeunit** named `"Pick Validator"` with a public procedure:

```al
procedure ValidatePick(ItemCode: Code[20]; RequestedQty: Integer; AvailableQty: Integer)
```

Rules:

1. When `RequestedQty` is less than or equal to `AvailableQty`, the procedure completes without any error — a pick of exactly the available quantity is allowed.
2. When `RequestedQty` is greater than `AvailableQty`, the procedure raises a single error carrying all four of the following.
3. A user-facing message of exactly `Cannot pick <RequestedQty> units of item <ItemCode>.` — for a request of 7 units of `BOLT-M8` that is `Cannot pick 7 units of item BOLT-M8.` (note the exact wording and the final period).
4. A detailed message — the hidden text meant for whoever troubleshoots the error, not for the end user — of exactly `Requested <RequestedQty> units of item <ItemCode>, but only <AvailableQty> units are available.` — for 7 requested and 3 available that is `Requested 7 units of item BOLT-M8, but only 3 units are available.`
5. Three custom dimensions — machine-readable key/value diagnostics attached to the error: key `ItemCode` holding the item code, key `RequestedQty` holding the requested quantity as plain digits (7 → `7`), and key `AvailableQty` holding the available quantity as plain digits.
6. The error must be collectible, so that a validation run executing in an error-collection scope can gather it and keep checking the remaining picks instead of stopping at the first one.

## What the tests check

Two tests call `ValidatePick` with enough stock (below and exactly at the boundary) and expect no error. One test provokes a shortage and asserts the user-facing message character for character. The remaining tests call `ValidatePick` inside an error-collection scope and assert that the error was actually collected (execution continued past it), that its detailed message matches character for character, and that the three custom dimensions are present with exactly the values described above. Quantities and item codes are randomly generated, so both texts and the dimension values must be built from the actual arguments, not hardcoded.

## Learn More

- [ErrorInfo data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type)
- [ErrorInfo.DetailedMessage([Text]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-detailedmessage-method)
- [ErrorInfo.CustomDimensions([Dictionary of [Text, Text]]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-customdimensions-method)
- [ErrorInfo.Collectible([Boolean]) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-collectible-method)
- [Collecting errors](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-collection)
