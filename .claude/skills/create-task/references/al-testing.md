# Writing AL tests — mechanics reference

Distilled from Microsoft Learn (testing-application, test-codeunits-and-test-methods,
subtype-codeunit-property, transactionmodel-attribute, testing-pages,
creating-handler-methods, app-faq-test, the purchase-invoice-discounts example,
the Customer Rewards walkthrough in extension-advanced-example-test, and
httpclient-mock-outbound-calls) plus the alguidelines.dev agentic testing guide.
Platform-specific notes for THIS catalog are marked **[platform]**.

## Test codeunit fundamentals

- A test codeunit declares `Subtype = Test;`. Methods in it are test methods
  by default; mark them explicitly with `[Test]` (house style), handler
  attributes, or `[Normal]`.
- When a test codeunit runs, `OnRun` executes first, then each test method.
- Outcome per test method is SUCCESS or FAILURE. FAILURE = any error raised
  by the tested code or the test code. Unlike a normal codeunit, a failing
  test method terminates only itself — the remaining test methods still run.
- Each test method runs in its own database transaction by default.
- Tests are executed by a test-runner codeunit. Two consequences that matter:
  any **unhandled UI interaction** (Message, Confirm, a modal page…) fails
  the test, and the runner's TestIsolation can roll back committed data.
  **[platform]** The platform runs your tests through its own runner inside
  a BC container — you never write a test runner for a task.
- **[platform]** House rule: every test codeunit declares
  `TestPermissions = Disabled;` right below `Subtype = Test;` (the official
  Customer Rewards walkthrough does the same). It keeps the permission-set
  testing infrastructure out of grading, so tests that seed base tables
  directly can never trip over simulated permissions. If a task is ever
  *about* permissions, drop the rule deliberately in that task and run the
  body under `"Library - Lower Permissions"`
  (e.g. `LibraryLowerPermissions.SetO365BusFull();` before the WHEN step).

## Test method design

- Three-step pattern with comment notation:

  ```al
  // [SCENARIO] Invoice discount is calculated for an amount above the minimum
  // [GIVEN] a vendor with 10% invoice discount above 100
  // [WHEN] calculating the discount on a 150 line
  // [THEN] the discount amount is 15
  ```

- Tag discipline: one `// [SCENARIO] <description>` per test; optionally a
  `// [FEATURE] [<area>]` once at the top of the codeunit (inherited by all
  its tests). Exactly **one WHEN per test** — needing a second WHEN followed
  by its own verification means the test must be split. Any number of
  GIVENs; at least one THEN — a test with no verification tests nothing.
- Reset shared state in a local `Initialize()` called first in every test:
  delete or normalize the records the tests touch, rebind mocks
  (`UnbindSubscription` then `BindSubscription`). The Customer Rewards
  walkthrough calls `Commit` right after Initialize — **[platform]** that
  requires `transactionModel: committed` + `companyIsolation: fresh`;
  prefer rollback-safe setup without `Commit` (see "Keeping a task
  rollback-safe").
- Tiered or threshold rules: drive a parameterized local helper once per
  case — below, exactly at, and above each boundary. The helper dedups the
  arrange/assert code; one `[Test]` per behavior still applies.
- Time-dependent logic is a trap: a test asserting on `Today`-dependent
  behavior passes only part of the year. Have the tested code take the date
  as a parameter and pass explicit dates. **[platform]** put that date
  parameter in the task's promised signature.
- Positive tests assert return values, state changes, and written data.
  Negative tests assert that the intended error occurs, with the right
  message, and that data is untouched.
- `asserterror <statement>` declares the statement MUST error:
  - if it errors, execution continues with the next statement;
  - if it does NOT error, `asserterror` itself fails the test.
  Verify the message afterwards via `GetLastErrorText`:

  ```al
  asserterror ThingUnderTest.Validate(BadInput);
  Assert.ExpectedError('must be positive');  // substring match, see test-libraries.md
  ```

  `asserterror` is test-code only — never in product code.
- Naming: `<Functionality><Variant>` — mirrored positive/negative variants
  (`...Above`, `...Below`, `...Zero`). One behavior per test method.
- Prefer generated inputs over hardcoded ones so implementations can't
  pattern-match the examples. **[platform]** use `Any` or
  `"Library - Random"` — see test-libraries.md.
- Tests must not depend on each other or on execution order; leave the
  system in a known state; keep a test codeunit well under 2 minutes.

## Failure messages that show the actual value

A failing grading test is the user's only debugging surface — they cannot
attach a debugger to the platform's container. The failure must let them
see what their code actually produced, not just that it was wrong.

- `Assert.AreEqual` / `AreNotEqual` / `AreNearlyEqual` append the values on
  their own — a failure reads
  `Assert.AreEqual failed. Expected:<36.66> (Decimal). Actual:<36.663>
  (Decimal). <your message>.` Prefer them over `IsTrue(A = B, ...)`, which
  swallows both values.
- `Assert.ExpectedError` reports the actual error text when it doesn't
  match — nothing extra to do after `asserterror`.
- When only `IsTrue`/`IsFalse` fits (enum comparisons, state checks,
  compound conditions), build the actual value into the message yourself:

  ```al
  Assert.IsTrue(Item."Restock Priority" = "Item Priority"::High,
      StrSubstNo('Expected "Restock Priority" to store and return High, got %1',
          Item."Restock Priority"));
  ```

- Rule of thumb: read the failure message and ask "can the user tell what
  their code returned?" If not, the message isn't done.

## SQL-budget (performance) tests

Grading a cost ceiling means snapshotting `SessionInformation`
(`SqlStatementsExecuted()`, `SqlRowsRead()`) around ONE call of the code
under test. Hard-won facts — a budget test that skips any of these grades
the wrong thing:

- **Warm up first**: the very first call pays one-time metadata statements
  and rows that vary by BC version. Run one throwaway call, measure the
  second.
- **The warm-up also fills the server data cache** — and that silently
  breaks the test. `Get`/`Find*`/`Count`/`IsEmpty`/`CalcFields` results are
  served from cache, so a repeated identical call costs **0 statements and
  0 rows**: the naive chatty implementation the budget exists to fail
  sails under any ceiling. Query objects bypass the cache ("results from
  query objects aren't cached"), so the intended solution honestly pays
  its statement while the anti-pattern hides.
- **Invalidate the cache between warm-up and graded call.** Write a decoy
  row into EVERY table the measured code reads (a write bumps the table's
  version, which invalidates its cached result sets — guaranteed), then
  call `SelectLatestVersion()` as well (the documented cache bypass, but
  it only clears non-locked records, so it is NOT sufficient alone inside
  the test transaction that seeded the data). Keep the decoys out of the
  graded filter, e.g. a customer with no salesperson code.
- **Calibrate budgets from measured numbers, not guesses**: add a local
  `DebugBudgets(): Boolean` returning `false`; when flipped, the test
  fails right after measuring with the raw counters in the message — a
  failure message is a test's only output channel on the platform. Run
  the starter and the reference solution, then set the ceiling a little
  above the solution's cost (version drift, legitimate variants) and far
  below the naive cost. Ship with the switch on `false`.
- Reads of the `SessionInformation` counters execute no SQL themselves;
  take snapshots freely, but keep the decoy writes and
  `SelectLatestVersion()` OUTSIDE the measured window.

## [TransactionModel] attribute (per test method)

`[TransactionModel(TransactionModel::<value>)]` — valid only in Subtype=Test
codeunits, placed on a test method. Values:

- **AutoRollback** (the default behavior) — the method runs inside one
  transaction that is rolled back afterwards. Any `Commit` in the tested
  code **errors**.
- **AutoCommit** — `Commit` calls take effect and remaining changes are
  committed at the end; the database is NOT restored (the runner's
  TestIsolation may clean up).
- **None** — simulates a real user: the test method itself cannot write to
  the database; each page-field interaction runs (and commits) its own
  transaction. For read-only/calculation tests driven through pages.

Best practice: declare the attribute **explicitly on every test method**
rather than relying on the default — it states the test's transactional
contract at a glance:

```al
[Test]
[TransactionModel(TransactionModel::AutoRollback)]
procedure TestInstallCodeunitData()
```

**[platform]** metadata's `transactionModel` field is the task-level
declaration of the same concern: keep `auto_rollback` unless the tested code
or your tests commit — then set `transactionModel: committed` AND
`companyIsolation: fresh` in `metadata.yaml`, and use `[TransactionModel]`
attributes as appropriate on the methods.

## Keeping a task rollback-safe **[platform]**

A rollback-safe task (`auto_rollback` + `reuse`) grades in a shared warm
company; a `committed` + `fresh` task creates a throwaway company first,
~17 s per run, every run. Two things push a task off the warm path, and
both have a rollback-safe pattern:

### Standard posting commits — `[CommitBehavior(CommitBehavior::Ignore)]`

`Sales-Post`, `Purch.-Post`, `Gen. Jnl.-Post Batch`, `TransferOrder-Post
Shipment/Receipt`, `Assembly-Post`, the undo codeunits, the blanket-order
*Make Order* and every `Library - X` helper that wraps them call `Commit()`.
Under AutoRollback that is fatal: "Tests cannot call the Commit function if
TransactionModel property is set to AutoRollback". The `CommitBehavior`
attribute scopes to the decorated method **and everything it calls**, so on a
test method it silences every explicit `Commit()` in the posting routine and
in the solution alike — no library rewrite, no "never commit" rule for users:

```al
[Test]
[TransactionModel(TransactionModel::AutoRollback)]
[CommitBehavior(CommitBehavior::Ignore)]
procedure ShipPassPostsTheShipment()
```

Put it on every test method of a codeunit that posts (house style: one
comment near the top of the codeunit says why), keep metadata on
`auto_rollback` + `reuse`, and drop any explicit `Commit();` from the tests —
the platform's isolation scanner treats a literal `Commit` as an escape and
falls back to a fresh company anyway. Limits: the attribute covers explicit
commits only — the implicit commit of `if Codeunit.Run(...)` (return value
captured), `Email.Send`, `StartSession` and `TaskScheduler.CreateTask` are
not silenced; a task that needs those stays `committed` + `fresh`.
`SetSuppressCommit(true)` on the posting codeunit works too, but only where
the test (not a library helper) drives the codeunit and the solution also
suppresses — prefer the attribute.

### State after a refused call — a test-local `[TryFunction]`

An error caught by `asserterror` rolls the database back to the last
`Commit`, the test's own arrangement included; under AutoRollback that is
everything. A try method is different: its database changes are **not**
rolled back when it catches the error. So a test that must read state after
a refused call catches the refusal this way:

```al
// [WHEN] undoing an invoiced receipt line
if TryUndoReceiptLine(ReceiptNo, LineNo) then
    Assert.Fail(StrSubstNo('Expected the undo of receipt line %1 of %2 to be refused, but it went through', LineNo, ReceiptNo));

// [THEN] the service refuses with its own message and changes nothing
Assert.ExpectedError(StrSubstNo('Receipt line %1 of %2 is already invoiced and cannot be undone.', LineNo, ReceiptNo));
PurchRcptLine.Get(ReceiptNo, LineNo);
...

[TryFunction]
local procedure TryUndoReceiptLine(ReceiptNo: Code[20]; LineNo: Integer)
var
    ReceiptCorrection: Codeunit "Receipt Correction";
begin
    ReceiptCorrection.UndoReceiptLine(ReceiptNo, LineNo);
end;
```

`GetLastErrorText`/`Assert.ExpectedError` work after a failed try function
exactly as after `asserterror`. Side effect worth knowing: the refused call's
own partial writes survive too, so "fails and writes nothing" now really
tests validate-before-write. Limits: the runner already wraps tests in a try
function, and inside a nested one `ModifyAll`/`DeleteAll` are refused — if
the refused call reaches such a statement before erroring, the test sees
that refusal instead of the promised error. Tests that only check the error
text can keep plain `asserterror`.

The fallback when neither pattern fits: `[TransactionModel(TransactionModel::AutoCommit)]`
on the test, `Commit();` right before the `asserterror`, and
`transactionModel: committed` + `companyIsolation: fresh` in metadata.

## Testing pages (TestPage / TestRequestPage)

TestPage mimics a page with no UI; code runs server-side.

```al
var
    CustomerCard: TestPage "Customer Card";
begin
    CustomerCard.OpenEdit();                    // or OpenView(), OpenNew()
    CustomerCard.GoToRecord(Customer);          // or GoToKey('10000')
    CustomerCard."Custom Field".SetValue('x');  // write a control
    Value := CustomerCard."Custom Field".Value; // read a control
    CustomerCard."Custom Field".AssertEquals('x'); // built-in field assert
    CustomerCard.Post.Invoke();                 // invoke a page action
    CustomerCard.Close();
```

- Getting a test page: `OpenNew/OpenEdit/OpenView`; as the parameter of a
  Page/ModalPageHandler; or `Trap()` called **before** the code that opens
  the page ("traps the next test page invoked").
- Fields are `TestField`: `Value`, `SetValue(Any)`, `AssertEquals(Any)`,
  `AsBoolean/AsDate/AsDateTime/AsDecimal/AsInteger/AsTime`, state getters
  `Editable/Enabled/Visible/ShowMandatory/Caption`, `Lookup()`, `Drilldown()`,
  `Invoke()`, `GetValidationError([Integer])`, `ValidationErrorCount()`.
- Navigation: `First/Last/Next/Previous`, `New()`, `GoToRecord(Record)`,
  `GoToKey(...)`, `Expand(Boolean)`/`IsExpanded()`.
- System actions have direct methods: `OK()`, `Cancel()`, `Yes()`, `No()`.
- Filters: `CustomerList.Filter.SetFilter("No.", '20000..30000');`
- Page parts are directly reachable:
  `CustomerCard."Sales Hist. Sell-to FactBox"."No.".Value`.
- Choose the transaction model deliberately when test pages write data.

## Handler methods

Wire handlers to a test with `[HandlerFunctions('HandlerA,HandlerB')]` (one
comma-separated string). The handled call's arguments are passed through.

| Attribute | Handles | Required signature |
|---|---|---|
| `[MessageHandler]` | `Message` | `(Message: Text[1024])` |
| `[ConfirmHandler]` | `Confirm` | `(Question: Text[1024]; var Reply: Boolean)` |
| `[StrMenuHandler]` | `StrMenu` | `(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])` |
| `[PageHandler]` | a specific non-modal page | `(var P: TestPage <id>)` |
| `[ModalPageHandler]` | a specific modal page | `(var P: TestPage <id>)` |
| `[ReportHandler]` | a specific report (replaces the whole run — its RequestPageHandler is then never called) | `(var R: Report <id>)` |
| `[RequestPageHandler]` | a report's request page | `(var RP: TestRequestPage <id>)` |
| `[FilterPageHandler]` | a FilterPageBuilder page | `(var R1: RecordRef, ...): Boolean` |
| `[HyperlinkHandler]` | hyperlinks | `(Hyperlink: Text[1024])` |
| `[SendNotificationHandler]` | notification Send | `(TheNotification: Notification): Boolean` |
| `[RecallNotificationHandler]` | notification Recall | `(TheNotification: Notification): Boolean` |
| `[SessionSettingsHandler]` | RequestSessionUpdate | `(var SessionSettings: SessionSettings): Boolean` |

Rules that bite:

- Under a test runner, **any unhandled UI interaction fails the test** —
  if the code under test raises a Confirm and there's no ConfirmHandler,
  the test fails. **[platform]** always true here.
- **Every declared handler must fire**: a handler listed in
  `[HandlerFunctions]` that is never called during the test method fails
  the test. Don't declare handlers "just in case".
- Assert inside handlers on the surfaced text, and set the reply:

  ```al
  [ConfirmHandler]
  procedure ConfirmYes(Question: Text[1024]; var Reply: Boolean)
  begin
      Assert.IsTrue(StrPos(Question, 'post') > 0, Question);
      Reply := true;
  end;
  ```

- An **empty-bodied** `[PageHandler]` / `[ModalPageHandler]` is the standard
  way to assert navigation ("invoking action X opens page Y"): if the page
  never opens, the declared handler never fires and the test fails; if it
  opens without the handler declared, the unhandled UI fails the test.
- To pass values between the test and a handler (handlers can't take extra
  parameters), use `"Library - Variable Storage"` — enqueue in the test,
  dequeue in the handler — or `"Library - Dialog Handler"`, which wraps the
  whole expect-verify-reply pattern for Message/Confirm/StrMenu
  (see test-libraries.md for both).

## Mocking external calls

Tests must never call a real external service. Two official mechanisms:

### 1. HttpClientHandler — intercept outbound HTTP at the transport level

BC 2025 wave 1 (v26) and later, on-premises only — which is what grading
containers run. The code under test uses plain `HttpClient`; the test
intercepts every outbound call:

```al
codeunit 50901 "Document Service Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // Any outbound request not caught by a handler raises an error
    // instead of silently hitting the network.
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [HandlerFunctions('MockDocumentApi')]
    procedure GetsDocumentContentFromTheService()
    var
        DocService: Codeunit "Document Service";
        Assert: Codeunit Assert;
    begin
        Assert.AreEqual('EXAMPLE CONTENT 42', DocService.GetDocumentContent('42'),
            'Expected the content returned by the service for document 42');
    end;

    [HttpClientHandler]
    procedure MockDocumentApi(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        DocumentId: Text;
    begin
        if (Request.RequestType = HttpRequestType::Get) and
           (Request.Path = 'http://example.com/documents')
        then begin
            Request.QueryParameters.Get('DocumentId', DocumentId);
            Response.Content.WriteFrom('EXAMPLE CONTENT ' + DocumentId);
            Response.HttpStatusCode := 200;
            exit(false); // false = answer with the mock
        end;
        exit(true); // true = send the real request (fall through)
    end;
}
```

Facts:

- Handler signature is exactly
  `(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean`,
  marked `[HttpClientHandler]`, attached to a test via `[HandlerFunctions]`
  like any other handler. While attached, ALL HttpClient calls in that test
  route to it.
- Return `false` to use the mocked response — this is the **default**, so an
  empty handler still intercepts and mocks a blank response. Return `true`
  to fall through to the real endpoint.
- Inspect the request via `Request.RequestType` (`HttpRequestType::Get` …),
  `Request.Path`, `Request.QueryParameters`. For security the request
  exposes **no headers, content, or cookies**; a `SecretText` URI hides even
  path and query (filter with `Request.HasSecretUri`).
- Build the response via `Response.Content.WriteFrom(...)`,
  `Response.HttpStatusCode`, `Response.ReasonPhrase`. No cookies, no 3xx
  redirect codes.
- Codeunit-level `TestHttpRequestPolicy` property:
  `BlockOutboundRequests` (unhandled request = exception — use this in
  grading tests), `AllowOutboundFromHandler` (every request must hit a
  handler, which may fall through), `AllowAllOutboundRequests` (default).

**[platform]** this is the preferred design for integrations tasks: the
statement asks the user to write real `HttpClient` code against a documented
fake endpoint, and the tests mock exactly that endpoint — asserting on
`Request.Path`/`QueryParameters` and simulating success, failure, and
malformed-payload responses.

### 2. Event-subscriber mock — for non-HTTP seams

The pattern from the Customer Rewards walkthrough; use it when the external
dependency isn't an HttpClient call (or the seam is a business event):

1. The product code raises an integration event instead of (or around) the
   external call — optionally consulting a setup record for WHICH codeunit
   handles it, so a mock can take over from the real handler.
2. A mock codeunit subscribes to that event and fabricates the response:

   ```al
   codeunit 50902 MockRewardsValidation
   {
       // Subscribers fire only while explicitly bound — the test decides when.
       EventSubscriberInstance = Manual;

       var
           CannedResponse: Text;

       procedure MockResponse(Success: Boolean)
       begin
           // set CannedResponse to a success or failure payload
       end;

       [EventSubscriber(ObjectType::Codeunit, Codeunit::"Rewards Ext. Mgt.",
                        'OnGetActivationCodeStatusFromServer', '', false, false)]
       local procedure HandleValidation(ActivationCode: Text)
       begin
           // parse CannedResponse and write the same records the real
           // handler would have written
       end;
   }
   ```

3. The test's `Initialize()` binds the mock and picks the canned outcome:

   ```al
   UnbindSubscription(MockRewardsValidation);
   BindSubscription(MockRewardsValidation);
   MockRewardsValidation.MockResponse(true);
   ```

**[platform]** grading containers have no outbound network, so an
integrations task must be DESIGNED for mocking from the start: prefer the
HttpClientHandler pattern above (users write real `HttpClient` code); fall
back to an integration-event seam for non-HTTP dependencies. A task whose
tests would need a live endpoint cannot be graded.

## Pitfalls

- `Commit` under AutoRollback errors; under AutoCommit/None it dirties the
  database. **[platform]** declare `transactionModel: committed` +
  `companyIsolation: fresh` in metadata if anything commits.
- `asserterror` swallows the error and continues — always assert on
  `GetLastErrorText` (or `Assert.ExpectedError`) after it, or a wrong error
  passes silently.
- An error caught by `asserterror` rolls the database back to the **last
  `Commit`** — the refused call's writes *and* everything the test itself
  wrote before the `asserterror`. Under AutoRollback nothing can be
  committed, so after the `asserterror` the arrangement is gone: a
  `Get`/`Count` of the seeded rows then fails ("The X does not exist",
  `Expected:<2> Actual:<0>`). A test that inspects state after a refused
  call catches the error through a test-local `[TryFunction]` instead — see
  "Keeping a task rollback-safe". Tests that only check the error text can
  keep `asserterror`.
- **[platform]** Standard posting commits. `Sales-Post`, `Purch.-Post`,
  `Gen. Jnl.-Post Batch`, the blanket-order *Make Order*, *Undo Receipt* and
  the `Library - X` posting helpers all `Commit` — under AutoRollback the run
  fails with "Tests cannot call the Commit function if TransactionModel
  property is set to AutoRollback". Put `[CommitBehavior(CommitBehavior::Ignore)]`
  on the test methods that post — see "Keeping a task rollback-safe". Only
  `Email.Send`, a captured `Codeunit.Run` and `StartSession` cannot be
  silenced and force `committed`/`fresh`.
- **[platform]** The runner invokes test codeunits inside a `[TryFunction]`.
  Inside a further try function *in your test* (one whose return value is
  used), `ModifyAll`/`DeleteAll` are refused ("Call to the function
  'MODIFYALL' is not allowed inside the call to 'RunTests' when it is used as
  a TryFunction"). Call the operation directly and let an error fail the
  test, or read the state it should have produced.
- **[platform]** Containers run in a non-UTC time zone (CET/CEST).
  `CreateDateTime`, `DT2Date`, `DT2Time` and DateTime arithmetic work in the
  session's local time — anything that promises UTC (Unix timestamps, ISO
  `Z` instants) must go through UTC-aware APIs (`Format(DT, 0, 9)`,
  `Evaluate(DT, '…Z', 9)`, the Type Helper UTC methods), on both the
  solution and the test side.
- AL evaluates **both** operands of `and`/`or` — there is no short-circuit.
  `if (i > 0) and (List.Get(i) = X)`, `(not Dict.ContainsKey(K)) or (Dict.Get(K) < V)`,
  `(i = 1) or (Arr[i - 1] <> 13)`, `OpenEnded or (EndDate + 1 >= D)` all
  crash on the guarded branch ("invalid argument passed to a 'List'", "key
  was not present", "INDEXING parameter … outside of the permitted range",
  "The date is not valid"). Nest the guard as its own `if`, or bound the
  loop and `break`. This bites solutions and test helpers alike.
- A `Codeunit "Temp Blob"` declared as a local of a helper dies with the
  helper — an `InStream` it handed back by `var` then reads as empty (`EOS`
  at once). Declare the blob in the test method and pass it by `var` into
  the helper that fills it.
- A handler declared but not triggered fails the test — as does UI with no
  handler. Symmetric traps.
- Records written by one test are rolled back before the next (AutoRollback)
  — but never rely on that for correctness; use distinct keys per test.
- A SQL-budget test that measures a second, identical call without
  invalidating the data cache measures cache hits (0 statements, 0 rows) —
  the chatty implementation it exists to fail passes. See "SQL-budget
  (performance) tests" above.

## Patterns from the official worked example (purchase invoice discounts)

Codeunit 50111 "ERM Vendor Discount" testing codeunit 70 "Purch.-Calc.Discount":

- One parameterized local helper (`CreatePurchDocument(var PurchLine; DocumentType; DocAmount; MinAmount; DiscountPct)`)
  serves all test variants: above minimum, below minimum, zero discount,
  credit memo. Build data with `Init` / `Validate` each field / `Insert(true)`.
- The expected value is computed independently in the test
  (`Round(PurchLine."Line Amount" * DiscountPct / 100)`), never read back
  from the code under test.
- Failure messages are named labels:
  `PurchInvDiscErr: Label 'The Purchase Invoice Discount Amount was not calculated correctly.';`
- Random inputs guarantee generality: a discount % of `RandDec(100, 5)`,
  a minimum of `RandDec(1000, 2)`, an amount of `MinAmount + RandDec(100, 2)`.
  **[platform]** `"Library - Random"`, `"Library - Purchase"`, and the whole
  W1 Application Test Library are available here — reproduce this example's
  idioms directly (see test-libraries.md).
