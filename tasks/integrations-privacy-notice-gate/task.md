# Don't Call Before They Agree

Your extension hands shipment numbers to a third-party parcel-tracking service. Before an AppSource app sends a single byte to a non-Microsoft service, the customer has to have said yes — and Business Central already ships the machinery for that: a *privacy notice*, registered under an id, that an administrator can agree to for the whole organization, disagree to for the whole organization, or simply leave undecided.

Consent is a database fact, not a startup constant. An admin can revoke it at 10:03, and the call your code makes at 10:04 has to be silent already. A connector that checks once and remembers the answer is the bug this task is about.

## Requirements

Create a **codeunit** named `"Parcel Tracking Client"` with two public procedures:

```al
procedure RegisterPrivacyNotice(PrivacyNoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]): Boolean
procedure TrackParcel(PrivacyNoticeId: Code[50]; TrackingNo: Text; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
```

Consent lives in the platform's privacy-notice registry, reached through the System Application's `Codeunit "Privacy Notice"`, and that registry is the single source of truth here: the grading tests put the organization's answer there by calling `SetApprovalState`, and your code has to read the same store. A notice is in exactly one of three states — `Agreed`, `Disagreed`, or `"Not set"` (nobody has decided yet).

Rules for `RegisterPrivacyNotice`:

1. It registers the integration in that registry under `PrivacyNoticeId`, storing `IntegrationName` as the integration name and `PrivacyLink` as the link to the privacy terms.
2. It returns `true` when this call is what created the notice, and `false` when a notice with that id already exists. A repeat registration is not an error, and it must leave the stored notice exactly as the first registration left it — same integration name, same link.
3. A blank `PrivacyLink` is refused with this error, character for character, and nothing is registered: `A privacy link is required to register the privacy notice for %1.` — where `%1` is `IntegrationName`.

Rules for `TrackParcel`:

4. Before anything leaves the building, it reads the current approval state of `PrivacyNoticeId` — on every single call, never a value remembered from an earlier one.
5. `Disagreed` means no request is sent at all, and the call fails with this error, character for character: `The privacy notice %1 was disagreed, so no data was sent to the tracking service.` — where `%1` is `PrivacyNoticeId`.
6. `"Not set"` means no request is sent either: the call returns `false` and leaves `ResponseBody` empty (`''`), even when the caller passed a stale value in. Nobody agreed, so nothing goes out — and nothing gets asked either.
7. An id that was never registered carries no decision, so it counts as `"Not set"`: same silent skip, no error.
8. `Agreed` means exactly one HTTP **GET** goes out through `HttpClientHandler`, to exactly this URL: `https://tracking.example.com/v1/parcels/<TrackingNo>`, with `<TrackingNo>` appended unchanged. The body of the response comes back in `ResponseBody`, and the call returns `true`.
9. Never ask the user anything. `ConfirmPrivacyNoticeApproval` — and anything else that shows a privacy notice — can open a modal page, and under the grading test runner a page that opens without a handler fails the test on the spot. Read the state; don't ask for it.

HTTP status handling is out of scope: the grading handler always answers `200`, and no test inspects status codes. Pick object ids in the 50100–50199 range, and reference every other object by name, never by id.

## What the tests check

The grading tests own the consent side: they call `SetApprovalState` on the platform registry to make a notice `Agreed`, `Disagreed`, or leave it undecided, and they pass in a mock of the tracking service that implements `Interface "Http Client Handler"`, counts every request and records its method and full URL. The grading container has no network, so write your call as if the endpoint were real and let the mock answer. **Every gate test asserts the exact number of requests that reached the mock**, so a call that slips out under `Disagreed` or `"Not set"` always fails somewhere: disagreed expects zero requests plus that exact error text, not-set expects zero requests plus `false` with `ResponseBody` back to `''` (it is preset to a stale value first), an unregistered id expects zero requests, and agreed expects exactly one request whose method is `GET` and whose URL matches the documented address for a randomly generated tracking number, with the mock's randomly generated response body returned. Two tests flip the state between two calls on the same instance — agreed, one request, then revoked to disagreed and the next call must error with **still exactly one request in total**; and undecided, skipped, then agreed and the next call must send its request — so an implementation that reads the state once and caches it fails both. Registration is graded by reading the notice back out of the registry: the first call returns `true` and the stored integration name and link are the ones you passed, a second call with the same id returns `false` and leaves those two values untouched, and a blank link produces the exact error above with no notice created.

## Learn More

- [Privacy Notices Status in Dynamics 365 Business Central](https://learn.microsoft.com/en-us/dynamics365/business-central/privacy-notices-status) — what a privacy notice is, and the admin page whose "Agree for All" / "Disagree for All" / "Let User Decide" columns are the three states you gate on.
- [Enum "Privacy Notice Approval State"](https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/enum/system.privacy.privacy-notice-approval-state) — the exact enum values your branches compare against.
- [Call external services with the HttpClient data type](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-httpclient) — building the GET request that the handler sends for you.
- [Technical validation checklist for AppSource](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-checklist-submission) — the rules an app has to pass before it may talk to anything outside Business Central.
