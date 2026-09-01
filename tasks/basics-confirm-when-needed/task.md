# Ask Only When It Matters

The sales back office releases dozens of orders a day. An order released without the customer's purchase-order reference tends to come back as a disputed invoice, so releasing one deserves a deliberate Yes from a human. But most orders are fine — and a routine that asks "Are you sure?" every single time trains users to click Yes without reading, and crashes outright when it runs from a job queue where nobody can answer.

## Requirements

Create a **codeunit** named `"Order Release Manager"` with one public procedure:

```al
procedure ReleaseOrder(var SalesHeader: Record "Sales Header"): Boolean
```

Rules:

1. If the order's `"External Document No."` is empty, ask the user for confirmation with exactly this question: `Order %1 has no external document number. Release it anyway?` — where `%1` is the order's `"No."`. Note the exact wording, including the final question mark.
2. If the user answers **Yes**, release the order and return `true`.
3. If the user answers **No**, leave the order exactly as it is and return `false`.
4. If `"External Document No."` is filled, release the order **without showing any dialog** and return `true` — the clean path must never prompt.
5. Releasing means setting the order's `Status` field to `Released` and saving the record with `Modify()`. Do not call the standard release codeunit — the graded orders have no lines, so it would refuse to release them.

Raise the dialog through the `Confirm Management` codeunit from the System Application — its `GetResponseOrDefault(Question, Default)` shows the dialog only when a UI exists and returns the default you pass otherwise. Pass `false` as the default: when the routine runs headless (job queue, web service), the risky release is then skipped instead of crashing the session. A raw `Confirm` call behaves the same under the grading tests but raises an error in headless sessions — LinterCop rule LC0021 exists precisely to catch it. Which of the two APIs you call is not graded; the prompting behavior is.

Pick object IDs in the 50100–50199 range, and reference other objects by name, never by ID.

## What the tests check

Three tests grade the three paths. One answers Yes through a ConfirmHandler that also verifies the full question text with the real order number substituted, then expects the order Released and `true` returned. One answers No and expects the order still Open and `false` returned. The third seeds an order with an external document number and declares **no ConfirmHandler at all** — in the AL test framework any dialog without a handler fails the test, so a routine that always asks fails the clean path.

## Learn More

- [Confirm Management codeunit](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.utilities.confirm-management) — the System Application wrapper this task is about: `GetResponseOrDefault` and `GetResponse`.
- [Dialog.Confirm method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-confirm-method) — the raw dialog underneath, and why confirm questions end with a question mark.
- [System.GuiAllowed method](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-guiallowed-method) — how code detects a session that cannot show any UI.
- [Progress windows, Message, Error, and Confirm methods](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-progress-windows-message-error-and-confirm-methods) — best practices for user-facing dialogs, including putting the text in a label.
