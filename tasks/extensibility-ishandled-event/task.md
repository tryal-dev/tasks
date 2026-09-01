# Override Behavior with an IsHandled Event

Your freight calculator ships inside a base extension that other teams build on. Marketing wants a free-freight promotion for large orders — but they must not edit your calculator, and you must not hardcode their campaign into it. The Business Central answer is the `OnBefore` + `IsHandled` pattern: the calculator raises an integration event before doing its own work, and any subscriber may take over the calculation entirely. The starter already declares the event publisher; wiring it into the calculation and honouring `IsHandled` is your job.

## Requirements

Complete the **codeunit** named `"Freight Charge Calculator"` with its public procedure:

```al
procedure CalculateFreight(Amount: Decimal): Decimal
```

1. By default, the freight charge is **10% of `Amount`, rounded to the nearest cent (0.01)**.
2. Before the default runs, the calculator raises the integration event the starter already declares, with exactly this name and signature (the grading tests subscribe to it, so name, parameter order, and `var` modifiers must stay character for character as provided):

```al
OnBeforeCalculateFreight(Amount: Decimal; var Freight: Decimal; var IsHandled: Boolean)
```

3. If a subscriber sets `IsHandled` to `true`, `CalculateFreight` returns whatever that subscriber left in `Freight` — **even when that value is 0** — and the default calculation must not run.
4. If no subscriber sets `IsHandled` — even if one wrote something into `Freight` — the default calculation decides the result. Only `IsHandled` may make that decision.

Then create a second **codeunit** named `"Free Freight Promotion"` that subscribes to `OnBeforeCalculateFreight`:

5. For an `Amount` of **1000 or more**, it grants free freight: the returned charge is 0 and the default must not run.
6. Below 1000 it leaves the event untouched, so the default charge applies.
7. The promotion participates **only while a caller has explicitly bound it with `BindSubscription`**. When nothing has bound it, `CalculateFreight` must return the default charge even for an order of 5000.

## What the tests check

The tests call `CalculateFreight` with generated amounts and compare against the 10% formula computed independently, so a hardcoded result fails. A test subscriber overrides `Freight` with a random value plus `IsHandled` and expects exactly that value back; another overrides it to exactly 0; a third writes a junk `Freight` without touching `IsHandled` and expects the default. The promotion is graded bound (free at exactly 1000, free above 1000, default below 1000) and unbound (default even at a large amount) — the tests bind it with `BindSubscription`, which errors unless the codeunit is built for manual binding.

## Learn More

- [Events in AL](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al)
- [Types of events for extensibility](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/types-of-events-for-extensibility)
- [IntegrationEvent attribute](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-integrationevent-attribute)
- [EventSubscriberInstance Property](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-eventsubscriberinstance-property)
- [Session.BindSubscription(Codeunit) Method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method)
