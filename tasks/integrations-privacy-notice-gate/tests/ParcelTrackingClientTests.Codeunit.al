codeunit 50900 "Parcel Tracking Client Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // The mock answers everything that travels through the handler seam;
    // grading containers have no outbound network, so a submission that
    // reaches for a raw HttpClient must fail loudly instead of hanging.
    TestHttpRequestPolicy = BlockOutboundRequests;

    // [FEATURE] [Privacy Notice] [Integration]

    var
        MissingLinkErr: Label 'A privacy link is required to register the privacy notice for %1.', Comment = '%1 = the name of the integration';
        ConsentDeclinedErr: Label 'The privacy notice %1 was disagreed, so no data was sent to the tracking service.', Comment = '%1 = the id of the privacy notice';
        TrackingUrlTok: Label 'https://tracking.example.com/v1/parcels/%1', Locked = true;
        StaleBodyTok: Label 'stale value from a previous call', Locked = true;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RegistersThePrivacyNoticeOnTheFirstCall()
    var
        PrivacyNotice: Record "Privacy Notice";
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoticeId: Code[50];
        IntegrationName: Text[250];
        PrivacyLink: Text[2048];
    begin
        // [SCENARIO] The first registration creates the notice and stores the name and link it was given
        Initialize();
        NoticeId := 'TRYAL-PNG-01';
        IntegrationName := CopyStr('Parcel Tracking ' + Any.AlphabeticText(10), 1, MaxStrLen(IntegrationName));
        PrivacyLink := CopyStr('https://tracking.example.com/privacy/' + LowerCase(Any.AlphanumericText(12)), 1, MaxStrLen(PrivacyLink));

        Assert.IsTrue(ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, IntegrationName, PrivacyLink),
            StrSubstNo('Expected RegisterPrivacyNotice to return true for the first registration of the privacy notice %1', NoticeId));

        Assert.IsTrue(PrivacyNotice.Get(NoticeId),
            StrSubstNo('Expected a privacy notice with the id %1 to exist in the platform registry after registering it', NoticeId));
        Assert.AreEqual(IntegrationName, PrivacyNotice."Integration Service Name",
            'Expected the registered privacy notice to carry the integration name that was passed to RegisterPrivacyNotice');
        Assert.AreEqual(PrivacyLink, PrivacyNotice.Link,
            'Expected the registered privacy notice to carry the privacy link that was passed to RegisterPrivacyNotice, not a default one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RepeatedRegistrationReturnsFalseAndChangesNothing()
    var
        PrivacyNotice: Record "Privacy Notice";
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoticeId: Code[50];
        FirstName: Text[250];
        FirstLink: Text[2048];
    begin
        // [SCENARIO] Registering an id that already exists reports false and leaves the stored notice alone
        Initialize();
        NoticeId := 'TRYAL-PNG-02';
        FirstName := CopyStr('Parcel Tracking ' + Any.AlphabeticText(10), 1, MaxStrLen(FirstName));
        FirstLink := CopyStr('https://tracking.example.com/privacy/' + LowerCase(Any.AlphanumericText(12)), 1, MaxStrLen(FirstLink));
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, FirstName, FirstLink);

        Assert.IsFalse(ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Someone Else Tracking', 'https://elsewhere.example.com/privacy'),
            StrSubstNo('Expected RegisterPrivacyNotice to return false for a second registration of the privacy notice %1 — and never to raise an error', NoticeId));

        Assert.IsTrue(PrivacyNotice.Get(NoticeId),
            StrSubstNo('Expected the privacy notice %1 to still exist after the second registration attempt', NoticeId));
        Assert.AreEqual(FirstName, PrivacyNotice."Integration Service Name",
            'Expected the second registration to leave the stored integration name of the first one untouched');
        Assert.AreEqual(FirstLink, PrivacyNotice.Link,
            'Expected the second registration to leave the stored privacy link of the first one untouched');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RefusesToRegisterAPrivacyNoticeWithoutALink()
    var
        PrivacyNotice: Record "Privacy Notice";
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        Assert: Codeunit Assert;
        NoticeId: Code[50];
        IntegrationName: Text[250];
    begin
        // [SCENARIO] A blank privacy link is refused with the documented error and registers nothing
        Initialize();
        NoticeId := 'TRYAL-PNG-03';
        IntegrationName := 'Parcel Tracking Without A Link';

        asserterror ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, IntegrationName, '');

        Assert.ExpectedError(StrSubstNo(MissingLinkErr, IntegrationName));
        PrivacyNotice.SetRange(ID, NoticeId);
        Assert.RecordIsEmpty(PrivacyNotice);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsExactlyOneRequestWhenTheNoticeIsAgreed()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        PrivacyNotice: Codeunit "Privacy Notice";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoticeId: Code[50];
        ExpectedBody: Text;
        ResponseBody: Text;
    begin
        // [SCENARIO] An agreed privacy notice lets exactly one request through and returns the service's answer
        Initialize();
        NoticeId := 'TRYAL-PNG-04';
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Agreed);
        ExpectedBody := 'parcel-' + Any.AlphanumericText(20);
        MockTrackingService.SetResponseBody(ExpectedBody);

        Assert.IsTrue(ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody),
            'Expected TrackParcel to return true when the privacy notice is agreed to');

        Assert.AreEqual(1, MockTrackingService.GetRequestCount(),
            'Expected exactly one request to reach the tracking service when the privacy notice is agreed to');
        Assert.AreEqual(ExpectedBody, ResponseBody,
            'Expected ResponseBody to carry the body of the tracking service response unchanged');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsTheTrackingNumberInTheDocumentedUrl()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        PrivacyNotice: Codeunit "Privacy Notice";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoticeId: Code[50];
        TrackingNo: Text;
        ResponseBody: Text;
    begin
        // [SCENARIO] The single request is a GET to the documented address for the tracking number it was given
        Initialize();
        NoticeId := 'TRYAL-PNG-05';
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Agreed);
        MockTrackingService.SetResponseBody('{"status":"in transit"}');
        TrackingNo := LowerCase(Any.AlphanumericText(12));

        ParcelTrackingClient.TrackParcel(NoticeId, TrackingNo, MockTrackingService, ResponseBody);

        Assert.AreEqual(1, MockTrackingService.GetRequestCount(),
            'Expected exactly one request to reach the tracking service when the privacy notice is agreed to');
        Assert.AreEqual('GET', UpperCase(MockTrackingService.GetCapturedMethod(1)),
            'Expected the request to the tracking service to use the GET method');
        Assert.AreEqual(StrSubstNo(TrackingUrlTok, TrackingNo), MockTrackingService.GetCapturedUri(1),
            'Expected the request URL to be the documented parcel address with the tracking number appended verbatim');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsNothingAndErrorsWhenTheNoticeIsDisagreed()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        PrivacyNotice: Codeunit "Privacy Notice";
        Assert: Codeunit Assert;
        NoticeId: Code[50];
        ResponseBody: Text;
    begin
        // [SCENARIO] A disagreed privacy notice fails the call with the documented error and sends nothing
        Initialize();
        NoticeId := 'TRYAL-PNG-06';
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Disagreed);
        MockTrackingService.SetResponseBody('{"status":"this response must never be requested"}');

        asserterror ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody);

        Assert.ExpectedError(StrSubstNo(ConsentDeclinedErr, NoticeId));
        Assert.AreEqual(0, MockTrackingService.GetRequestCount(),
            'Expected no request at all to reach the tracking service while the privacy notice is disagreed to');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsNothingWhenNobodyHasDecidedYet()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        Assert: Codeunit Assert;
        NoticeId: Code[50];
        ResponseBody: Text;
    begin
        // [SCENARIO] A registered but undecided privacy notice is skipped silently, without a request
        Initialize();
        NoticeId := 'TRYAL-PNG-07';
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        MockTrackingService.SetResponseBody('{"status":"this response must never be requested"}');
        ResponseBody := StaleBodyTok;

        Assert.IsFalse(ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody),
            'Expected TrackParcel to return false while nobody has agreed to or disagreed with the privacy notice');

        Assert.AreEqual(0, MockTrackingService.GetRequestCount(),
            'Expected no request at all to reach the tracking service while nobody has decided on the privacy notice');
        Assert.AreEqual('', ResponseBody,
            'Expected ResponseBody to end up empty when the call was skipped (it was preset to a stale value)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsNothingForAnIntegrationThatWasNeverRegistered()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        Assert: Codeunit Assert;
        NoticeId: Code[50];
        ResponseBody: Text;
    begin
        // [SCENARIO] An id with no privacy notice behind it carries no consent, so the call is skipped
        Initialize();
        NoticeId := 'TRYAL-PNG-08';
        MockTrackingService.SetResponseBody('{"status":"this response must never be requested"}');
        ResponseBody := StaleBodyTok;

        Assert.IsFalse(ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody),
            StrSubstNo('Expected TrackParcel to return false for %1, an id that was never registered as a privacy notice', NoticeId));

        Assert.AreEqual(0, MockTrackingService.GetRequestCount(),
            'Expected no request at all to reach the tracking service for an integration that was never registered');
        Assert.AreEqual('', ResponseBody,
            'Expected ResponseBody to end up empty when the call was skipped (it was preset to a stale value)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StopsCallingAfterConsentIsRevoked()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        PrivacyNotice: Codeunit "Privacy Notice";
        Assert: Codeunit Assert;
        NoticeId: Code[50];
        ResponseBody: Text;
    begin
        // [SCENARIO] Consent granted for one call and revoked afterwards stops the very next call
        Initialize();
        NoticeId := 'TRYAL-PNG-09';
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        MockTrackingService.SetResponseBody('{"status":"in transit"}');
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Agreed);
        ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody);
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Disagreed);

        asserterror ParcelTrackingClient.TrackParcel(NoticeId, 'tn1001', MockTrackingService, ResponseBody);

        Assert.ExpectedError(StrSubstNo(ConsentDeclinedErr, NoticeId));
        Assert.AreEqual(1, MockTrackingService.GetRequestCount(),
            'Expected the tracking service to have received only the first request: the approval state is read again on every call, so revoking consent stops the second one');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StartsCallingOnceConsentIsGranted()
    var
        ParcelTrackingClient: Codeunit "Parcel Tracking Client";
        MockTrackingService: Codeunit "Mock Tracking Service";
        PrivacyNotice: Codeunit "Privacy Notice";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        NoticeId: Code[50];
        ExpectedBody: Text;
        ResponseBody: Text;
    begin
        // [SCENARIO] A call skipped for want of a decision goes out as soon as the notice is agreed to
        Initialize();
        NoticeId := 'TRYAL-PNG-10';
        ExpectedBody := 'parcel-' + Any.AlphanumericText(20);
        ParcelTrackingClient.RegisterPrivacyNotice(NoticeId, 'Parcel Tracking', 'https://tracking.example.com/privacy');
        MockTrackingService.SetResponseBody(ExpectedBody);
        ParcelTrackingClient.TrackParcel(NoticeId, 'tn1000', MockTrackingService, ResponseBody);
        PrivacyNotice.SetApprovalState(NoticeId, "Privacy Notice Approval State"::Agreed);

        Assert.IsTrue(ParcelTrackingClient.TrackParcel(NoticeId, 'tn1001', MockTrackingService, ResponseBody),
            'Expected TrackParcel to return true once the privacy notice is agreed to, even though an earlier call on the same instance was skipped');

        Assert.AreEqual(1, MockTrackingService.GetRequestCount(),
            'Expected exactly one request in total: none while the notice was undecided, one after it was agreed to');
        Assert.AreEqual(ExpectedBody, ResponseBody,
            'Expected ResponseBody to carry the body of the tracking service response unchanged');
    end;

    local procedure Initialize()
    begin
        // The privacy-notice module answers "Agreed" for every notice in an
        // evaluation company, which would hide the undecided cases these tests
        // grade. Clearing the flag is best effort — the standard grading
        // company is not an evaluation company to begin with.
        if ClearEvaluationCompanyFlag() then;
    end;

    [TryFunction]
    local procedure ClearEvaluationCompanyFlag()
    var
        Company: Record Company;
    begin
        if not Company.Get(CompanyName()) then
            exit;
        if not Company."Evaluation Company" then
            exit;
        Company."Evaluation Company" := false;
        Company.Modify();
    end;
}
