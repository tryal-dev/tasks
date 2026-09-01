# Test libraries available on the platform

Every signature below was read from microsoft/BCApps source (pinned commit
`97d4749a` for the W1 Application Test Library; `main` for the Test Framework).

**All standard Microsoft test libraries ship on the platform.** A task's
tests may reference any test-library codeunit; the only requirement is the
exact declared object name, e.g.
`LibraryVariableStorage: Codeunit "Library - Variable Storage";`.

The layers, bottom to top:

- **Test Framework libraries** — `Any` (130500), `"Library Assert"` (130002),
  `"Library - Variable Storage"` (131004).
- **W1 Application Test Library** — `Assert` (130000),
  `"Library - Dialog Handler"` (131005), and ~44 `"Library - X"` data/posting
  helpers (`"Library - Sales"`, `"Library - ERM"`, `"Library - Random"`, …).
- **Tests-TestLibraries** — mocks and verification helpers (report datasets,
  reduced permissions, job queue rerouting…) — see the last section.

Naming trap: the object names are exact AL identifiers. It's
`"Library - Variable Storage"` (with dash) and `"Library Assert"` (no dash);
`Assert` is unquoted. Getting a dash or quoting wrong is a compile error —
name resolution is exact-match.

## Assert — `codeunit 130000 Assert` (the conventional choice)

Most Microsoft application tests declare `Assert: Codeunit Assert`. Use it in
new tasks. (`"Library Assert"` 130002 is interface-equivalent for the core
procedures and also fine — some existing tasks use it; it adds
`AreEqualDateTime`, a Dictionary `AreEqual` overload, and `KnownFailure`.)

Core assertions:

- `IsTrue(Condition: Boolean; Msg: Text)` / `IsFalse(Condition: Boolean; Msg: Text)`
- `AreEqual(Expected: Variant; Actual: Variant; Msg: Text)` — type-aware;
  numbers compare numerically. Records/RecordRef/Codeunit variants are
  unsupported types (error).
- `AreNotEqual(Expected: Variant; Actual: Variant; Msg: Text)`
- `AreNearlyEqual(Expected: Decimal; Actual: Decimal; Delta: Decimal; Msg: Text)`
  / `AreNotNearlyEqual(...)` — for rounding-tolerant decimal checks.
- `Fail(Msg: Text)` — unconditional failure.

Record/table state:

- `RecordIsEmpty(RecVariant)` / `RecordIsNotEmpty(RecVariant)` — respects the
  filters set on the record you pass.
- `TableIsEmpty(TableNo: Integer)` / `TableIsNotEmpty(TableNo: Integer)`
- `RecordCount(RecVariant; ExpectedCount: Integer)`

Error verification (use right after `asserterror`):

- `ExpectedError(Expected: Text)` — **substring** match against
  `GetLastErrorText()`; fails if no error was actually thrown.
- `ExpectedErrorCode(Expected: Text)` — substring match on the error code.
- `ExpectedErrorCannotFind(TableID: Integer [; RecordIdentificationText: Text])`
  — version-robust check for "record does not exist / can't find" errors.
- `ExpectedTestFieldError(FieldCaption: Text; ExpectedValue: Text)` —
  version-robust check for `TestField` errors.
- `AssertRecordNotFound()` / `AssertRecordAlreadyExists()` /
  `AssertNothingInsideFilter()` / `AssertNoFilter()` — verify the last error
  code is the corresponding `DB:` error, then clear it.

Text and dialog content:

- `ExpectedMessage(Expected: Text; Actual: Text)` — Expected must be a
  substring of Actual (despite the name, works for any two texts).
- `ExpectedConfirm(Expected: Text; Actual: Text)` /
  `ExpectedStrMenu(ExpectedInstruction, ExpectedOptions, ActualInstruction, ActualOptions)`
- `IsSubstring(OriginalText: Text; Substring: Text)` /
  `TextEndsWith(OriginalText: Text; Substring: Text)`

## Any — `codeunit 130500 "Any"` (random test data)

Declare as a **local variable inside each test method** (per its own docs) so
tests stay order-independent. Deterministic: first use seeds with `SetSeed(1)`.

- `Boolean(): Boolean`
- `IntegerInRange(MaxValue): Integer` / `IntegerInRange(MinValue, MaxValue): Integer`
- `DecimalInRange(MaxValue, DecimalPlaces): Decimal` /
  `DecimalInRange(MinValue, MaxValue, DecimalPlaces): Decimal` (Integer and
  Decimal bound overloads)
- `DateInRange(MaxNumberOfDays): Date` (from `WorkDate()`) /
  `DateInRange(StartingDate, MaxNumberOfDays)` /
  `DateInRange(StartingDate, MinNumberOfDays, MaxNumberOfDays)`
- `AlphabeticText(Length): Text` (lowercase a–z) /
  `AlphanumericText(Length): Text` / `UnicodeText(Length): Text`
- `Email(): Text` / `Email(LocalPartLength, DomainLength): Text`
- `GuidValue(): Guid` (truly random, not seed-driven)
- `SetSeed(NewSeed)` / `GetSeed(): Integer`

The application-layer alternative is `codeunit 130440 "Library - Random"`
(`RandDec(Range, Decimals)`, `RandDecInRange(Min, Max, Decimals)`,
`RandInt(Range)`, `RandIntInRange(Min, Max)`, `RandDate(Delta)`,
`RandText(Length)`) — the one official BC test examples use. Either is fine.

## "Library - Variable Storage" — `codeunit 131004`

FIFO queue of max 25 Variants. Purpose: pass values between a test method and
its handler methods, which can't take extra parameters. **Not SingleInstance**
— the test method and the handler only share state through the SAME codeunit
variable, so declare it as a global of the test codeunit.

- `Enqueue(Value: Variant)` — errors "Queue overflow." past 25.
- `Dequeue(var Value: Variant)` — errors "Queue underflow." when empty.
- Typed dequeues: `DequeueText(): Text`, `DequeueDecimal(): Decimal`,
  `DequeueInteger(): Integer`, `DequeueDate(): Date`,
  `DequeueDateTime(): DateTime`, `DequeueTime(): Time`,
  `DequeueBoolean(): Boolean`.
- `Peek(var Value: Variant; Index: Integer)` + typed peeks (1-based, no removal).
- `Length(): Integer` / `Clear()`
- `AssertEmpty()` — end every handler-based test with this: it fails if a
  queued value was never consumed (a leaked expectation = a dialog that
  never appeared).

## "Library - Dialog Handler" — `codeunit 131005` (complete API)

Wraps the variable-storage pattern for dialog verification: the test declares
what dialog content to expect, the handler verifies and answers. Built on
`Assert.ExpectedMessage/ExpectedConfirm/ExpectedStrMenu` (substring matches).

- `SetExpectedMessage(Message: Text)` / `HandleMessage(Message: Text)`
- `SetExpectedConfirm(Question: Text; Reply: Boolean)` /
  `HandleConfirm(Question: Text; var Reply: Boolean)`
- `SetExpectedStrMenu(Options: Text; Choice: Integer; Instruction: Text)` /
  `HandleStrMenu(Options: Text; var Choice: Integer; Instruction: Text)`
- `ClearVariableStorage()`

Canonical usage — note the **global** var, shared by test and handler:

```al
codeunit 50900 "Posting Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryDialogHandler: Codeunit "Library - Dialog Handler";

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PostingAsksForConfirmationAndPosts()
    var
        Assert: Codeunit Assert;
    begin
        LibraryDialogHandler.SetExpectedConfirm('post the document', true);
        // ... invoke the code under test that raises the Confirm ...
        // ... then Assert on the resulting state ...
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        LibraryDialogHandler.HandleConfirm(Question, Reply);
    end;
}
```

## The "Library - X" application helpers

Reach-for-first cheat sheet:

| Need | Call |
|---|---|
| A customer | `LibrarySales.CreateCustomer(var Customer)` |
| A vendor | `LibraryPurchase.CreateVendor(var Vendor)` |
| An item | `LibraryInventory.CreateItem(var Item)`; with prices: `CreateItemWithUnitPriceAndUnitCost(...)` |
| Create + post a sales invoice | `LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, "Sales Document Type"::Invoice, CustNo, ItemNo, Qty, '', 0D)` then `LibrarySales.PostSalesDocument(SalesHeader, true, true)` → posted no. |
| Random amount | `LibraryRandom.RandDecInRange(Min, Max, 2)` |
| Unique code for a Code field | `LibraryUtility.GenerateGUID()` or `GenerateRandomCode20(FieldNo, TableNo)` |
| G/L account wired for posting | `LibraryERM.CreateGLAccountWithSalesSetup()` / `CreateGLAccountWithPurchSetup()` |
| Post a journal amount | `LibraryJournals.CreateGenJournalLineWithBatch(...)` + `LibraryERM.PostGeneralJnlLine(GenJournalLine)` |

The main libraries:

- `codeunit 130509 "Library - Sales"` — customers, sales documents, posting.
  `CreateSalesHeader(var SalesHeader, DocumentType, SellToCustomerNo)`,
  `CreateSalesLine(var SalesLine, SalesHeader, Type, No, Quantity)`,
  `PostSalesDocument(var SalesHeader, Ship, Invoice): Code[20]`,
  `ReleaseSalesDocument(var SalesHeader)`.
- `codeunit 130512 "Library - Purchase"` — mirror for vendors/purchases:
  `CreateVendor`, `CreatePurchHeader` (note: not "CreatePurchaseHeader"),
  `CreatePurchaseDocumentWithItem(...)`, `PostPurchaseDocument(...)`.
- `codeunit 132201 "Library - Inventory"` — items, UoM, item journals:
  `CreateItemJournalLine(...)`, `PostItemJournalLine(TemplateName, BatchName)`.
- `codeunit 131300 "Library - ERM"` — the giant finance library: G/L accounts,
  journals (`CreateGeneralJnlLine`, `PostGeneralJnlLine`), currencies +
  exchange rates, VAT/general posting setup, payment terms, entry application.
- `codeunit 131000 "Library - Utility"` — unique codes, no. series, random
  text/email/date.
- `codeunit 130440 "Library - Random"` — see above.
- `codeunit 131009 "Library - Setup Storage"` — `Save(TableId)` /
  `SaveGeneralLedgerSetup()` / … / `Restore()`: snapshot setup tables once,
  restore at the start of every test so setup mutations don't leak.
- Also available for specialized tasks: `"Library - Warehouse"` (132204),
  `"Library - Manufacturing"` (132202), `"Library - Assembly"` (132207),
  `"Library - Planning"` (132203), `"Library - Costing"` (132200),
  `"Library - Item Tracking"` (130502), `"Library - Job"` (131920),
  `"Library - Service"` (131902), `"Library - Fixed Asset"` (131330),
  `"Library - Dimension"` (131001), `"Library - Price Calculation"` (130510),
  `"Library - Marketing"` (131900), `"Library - Human Resource"` (131901),
  `"Library - Resource"` (130511), `"Library - Workflow"` (131101),
  `"Library - Fiscal Year"` (131302), `"Library - Journals"` (131306),
  `"Library - Templates"` (132210).

Conventions worth imitating: creators are `Create<Entity>(var Rec, ...)`,
often with `Create<Entity>No(): Code[20]` returning just the key; posting
routines return the posted document no.; the Ship/Invoice boolean pair on
`Post*Document` maps to the posting dialog's checkboxes.

## Tests-TestLibraries helpers (specialized, also available)

- `codeunit 131007 "Library - Report Dataset"` — verify report output:
  `RunReportAndLoad(ReportID, RecordVariant, RequestPageParametersXML)`,
  `AssertElementWithValueExists(ElementName, ExpectedValue)`,
  `GetNextRow(): Boolean`, `SetRange(ElementName, Value)`.
- `codeunit 131002 "Library - Report Validation"` — checks on Excel-rendered
  reports: `SetFileName(...)`, `OpenExcelFile()`, `CheckIfValueExists(...)`.
- `codeunit 131337 "Library - XPath XML Reader"` — XML verification:
  `Initialize(FullFilePath, NameSpace)`, `VerifyNodeValue(ElementName, Expected)`,
  `VerifyNodeCountByXPath(xPath, NodeCount)`.
- `codeunit 132217 "Library - Lower Permissions"` — run the test body under
  reduced permission sets: `SetO365BusFull()`, `PushPermissionSet(RoleID)`.
- `codeunit 131352 "Library - Document Approvals"` — approval users/setup:
  `CreateUserSetup(...)`, `SetupUsersForApprovals(...)`.
- `codeunit 132458 "Library - Job Queue"` — reroutes job-queue work to run
  synchronously in tests (needed when posting setup uses "Post with Job Queue").
- `codeunit 130618 "Library - Graph Mgt"` — API/OData test helpers:
  `EnsureWebServiceExist(...)`, `GetFromWebServiceAndCheckResponseCode(...)`.
