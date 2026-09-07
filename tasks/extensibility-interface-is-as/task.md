# Does This Carrier Track?

Your shipping module already does the textbook thing: an extensible `Carrier` enum picks a codeunit through the `"IShipping Carrier"` interface, and posting asks that codeunit for a `Quote` without ever naming a carrier. Now the webshop team wants a **Track parcel** link on the shipment page. Only some carriers offer tracking, and the carrier list is not yours to know — partner extensions add their own values to `Carrier` and wire them to codeunits you will never see. The dispatcher you write has to ask each carrier's codeunit, at run time, whether it can track at all, and it must never crash on one that cannot.

## Requirements

The starter declares the pieces below — keep every name and signature exactly as given, the grading tests bind to them:

- Interface `"IShipping Carrier"` with `procedure Quote(Weight: Decimal): Decimal`.
- Interface `ITrackable` with `procedure TrackingUrl(TrackingNo: Text): Text`.
- Extensible enum `Carrier`, implementing `"IShipping Carrier"`, with the values `"Ground Post"` and `"Express Air"`, each wired to its codeunit. Leave the enum, its values and their wiring as they are.
- Codeunits `"Ground Post Shipping"` and `"Express Air Shipping"`, both implementing `"IShipping Carrier"`. Their `Quote` is scenery — it is not graded, leave it alone.

1. Make `"Express Air Shipping"` implement `ITrackable` as well. Its `TrackingUrl` returns `https://track.expressair.example/` immediately followed by the tracking number, unchanged — no extra slash, no encoding, no trimming.
2. `"Ground Post Shipping"` does not track parcels and must **not** implement `ITrackable`. The tests verify this directly: treating its codeunit as `ITrackable` has to fail.
3. Implement both procedures of the codeunit `"Carrier Tracking"`:

```al
procedure IsTrackable(Carrier: Enum Carrier): Boolean
procedure TrackingLink(Carrier: Enum Carrier; TrackingNo: Text): Text
```

- `IsTrackable` returns `true` exactly when the codeunit the carrier value is wired to implements `ITrackable`, and `false` otherwise.
- `TrackingLink` returns that codeunit's `TrackingUrl(TrackingNo)` when the carrier is trackable, and an empty text (`''`) otherwise. It must never raise an error, whatever carrier value it is given.

4. Neither procedure may depend on which values `Carrier` has or on the names of the two built-in carriers: the enum is extensible, and the grading tests add values of their own, wired to codeunits you have never seen — one that tracks and one that does not. The only thing your dispatcher may rely on is the carrier's codeunit, reached through the `Carrier` value itself.

Pick object IDs in the 50100–50199 range and reference other objects by name, never by ID.

## What the tests check

Every test goes through the `Carrier` enum. For `"Express Air"` they expect `IsTrackable` to be `true` and `TrackingLink` to be exactly `https://track.expressair.example/` followed by a random tracking number; for `"Ground Post"` they expect `false` and an empty text. The tests then extend `Carrier` with two values of their own — `"Test Drone"`, wired to a test codeunit implementing both interfaces, and `"Test Barge"`, wired to one implementing only `"IShipping Carrier"` — and expect the same behavior from your unchanged dispatcher: `true` and the drone codeunit's own URL, `false` and an empty text for the barge. A dispatcher that recognizes carriers by name fails here, and one that treats every carrier as trackable errors on the barge. Finally the tests inspect your object design: they take the codeunit wired to `"Express Air"` as `ITrackable` without any check and expect its `TrackingUrl` to answer with the URL above, and they do the same with the codeunit wired to `"Ground Post"` and expect that unchecked conversion to fail with an error. Against the unchanged starter, every Express Air and Test Drone test fails.

## Learn More

- [Interfaces in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-interfaces-in-al) — how a codeunit implements one or more interfaces and how an interface variable dispatches to it.
- [Extensible enums](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums) — why other extensions can add `Carrier` values your code has never seen.
- [Implementation property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-implementation-property) — how an enum value is wired to the codeunit that implements its interface.
