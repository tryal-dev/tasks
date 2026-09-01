codeunit 50900 "Resilient Http Client Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    // The mock answers requests sent through the handler interface; grading
    // containers have no outbound network, so a submission that bypasses the
    // seam with a raw HttpClient must fail loudly instead of hanging on a
    // dead socket.
    TestHttpRequestPolicy = BlockOutboundRequests;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReturnsTrueAndTheBodyWhenTheFirstAttemptSucceeds()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        SuccessStatus: Integer;
        ExpectedBody: Text;
        ResponseBody: Text;
    begin
        // [SCENARIO] A randomly chosen 2xx on the first attempt returns true with that response's body, after exactly one request
        SuccessStatus := Any.IntegerInRange(200, 299);
        ExpectedBody := 'payload-' + Any.AlphanumericText(20);
        MockFlakyService.SetSuccessBody(ExpectedBody);
        MockFlakyService.ScriptStatus(SuccessStatus);

        Assert.IsTrue(ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 3, MockFlakyService, ResponseBody),
            StrSubstNo('Expected GetWithRetry to return true for a %1 response — any status in the 2xx class is a success, not just 200', SuccessStatus));
        Assert.AreEqual(ExpectedBody, ResponseBody,
            StrSubstNo('Expected ResponseBody to carry the body of the successful %1 response unchanged', SuccessStatus));
        Assert.AreEqual(1, MockFlakyService.GetRequestCount(),
            StrSubstNo('Expected exactly one request through the handler when the first attempt already succeeded with a %1', SuccessStatus));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SendsGetRequestsToTheExactUrlOnEveryAttempt()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        Url: Text;
        ResponseBody: Text;
        i: Integer;
    begin
        // [SCENARIO] Every attempt, retries included, is a GET to the Url parameter character for character
        Url := 'https://api.example.com/v1/' + LowerCase(Any.AlphabeticText(8));
        MockFlakyService.SetSuccessBody('url-check-body');
        MockFlakyService.ScriptStatus(429);
        MockFlakyService.ScriptStatus(500);
        MockFlakyService.ScriptStatus(200);

        ResilientHttpClient.GetWithRetry(Url, 5, MockFlakyService, ResponseBody);

        Assert.AreEqual(3, MockFlakyService.GetRequestCount(),
            'Expected exactly three requests through the handler for the script 429, 500, 200');
        for i := 1 to MockFlakyService.GetRequestCount() do begin
            Assert.AreEqual('GET', UpperCase(MockFlakyService.GetCapturedMethod(i)),
                StrSubstNo('Expected request %1 to use the GET method', i));
            Assert.AreEqual(Url, MockFlakyService.GetCapturedUri(i),
                StrSubstNo('Expected the full URL of request %1 to equal the Url parameter exactly, with nothing rewritten or appended', i));
        end;
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RetriesThrough429Then500AndSucceedsOnTheThirdAttempt()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        ExpectedBody: Text;
        ResponseBody: Text;
    begin
        // [SCENARIO] 429 then 500 are both retried; the third response is a 200 whose body comes back
        ExpectedBody := 'third-time-lucky-' + Any.AlphanumericText(20);
        MockFlakyService.SetSuccessBody(ExpectedBody);
        MockFlakyService.ScriptStatus(429);
        MockFlakyService.ScriptStatus(500);
        MockFlakyService.ScriptStatus(200);

        Assert.IsTrue(ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 5, MockFlakyService, ResponseBody),
            'Expected GetWithRetry to return true after retrying through a 429 and a 500 to a final 200');
        Assert.AreEqual(3, MockFlakyService.GetRequestCount(),
            'Expected exactly three requests through the handler for the script 429, 500, 200');
        Assert.AreEqual(ExpectedBody, ResponseBody,
            'Expected ResponseBody to carry the body of the third (successful) response, not one of the failed ones');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StopsAfterExactlyMaxAttemptsWhenTheServiceNeverRecovers()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MaxAttempts: Integer;
        TransientStatus: Integer;
        ResponseBody: Text;
    begin
        // [SCENARIO] An endlessly repeated, randomly chosen 5xx consumes exactly the attempt budget, then the call gives up
        MaxAttempts := Any.IntegerInRange(2, 5);
        TransientStatus := Any.IntegerInRange(500, 599);
        MockFlakyService.SetSuccessBody('never-delivered');
        MockFlakyService.ScriptStatus(TransientStatus);

        Assert.IsFalse(ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', MaxAttempts, MockFlakyService, ResponseBody),
            StrSubstNo('Expected GetWithRetry to return false when all %1 allowed attempts get a %2 — every status in 500-599 is transient', MaxAttempts, TransientStatus));
        Assert.AreEqual(MaxAttempts, MockFlakyService.GetRequestCount(),
            StrSubstNo('Expected exactly MaxAttempts (%1) requests through the handler against a service that always answers %2 — every status in 500-599 is transient', MaxAttempts, TransientStatus));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure DoesNotRetryAPermanentClientError()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        PermanentStatus: Integer;
        ResponseBody: Text;
    begin
        // [SCENARIO] A 400 or 404 gives up immediately — a retry would reach the scripted 200 and wrongly succeed
        if Any.IntegerInRange(1, 2) = 1 then
            PermanentStatus := 400
        else
            PermanentStatus := 404;
        MockFlakyService.SetSuccessBody('unreachable-success-body');
        MockFlakyService.ScriptStatus(PermanentStatus);
        MockFlakyService.ScriptStatus(200);
        ResponseBody := 'stale value from a previous call';

        Assert.IsFalse(ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 3, MockFlakyService, ResponseBody),
            StrSubstNo('Expected GetWithRetry to return false for a %1: a permanent client error must not be retried, even though a retry here would have reached a 200', PermanentStatus));
        Assert.AreEqual(1, MockFlakyService.GetRequestCount(),
            StrSubstNo('Expected exactly one request through the handler for a %1 response — permanent errors are never retried', PermanentStatus));
        Assert.AreEqual('', ResponseBody,
            StrSubstNo('Expected ResponseBody to end up empty after a %1, not the failed response''s body and not the stale value it was preset to', PermanentStatus));
        Assert.AreEqual(0, ResilientHttpClient.GetTotalBackoffMs(),
            'Expected no backoff on the tally when the call gives up without retrying');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ASingleAllowedAttemptMeansNoRetry()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] MaxAttempts = 1 against a 500 sends one request — an off-by-one retry would hit the scripted 200
        MockFlakyService.SetSuccessBody('unreachable-success-body');
        MockFlakyService.ScriptStatus(500);
        MockFlakyService.ScriptStatus(200);
        ResponseBody := 'stale value from a previous call';

        Assert.IsFalse(ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 1, MockFlakyService, ResponseBody),
            'Expected GetWithRetry to return false when MaxAttempts is 1 and the only attempt gets a 500');
        Assert.AreEqual(1, MockFlakyService.GetRequestCount(),
            'Expected exactly one request through the handler when MaxAttempts is 1 — the transient 500 leaves no budget for a retry');
        Assert.AreEqual('', ResponseBody,
            'Expected ResponseBody to end up empty when the single allowed attempt failed (it was preset to a stale value)');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ClearsTheStaleBodyWhenEveryAttemptFails()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] On failure the caller's variable ends up empty, not stale and not a failed response's body
        MockFlakyService.SetSuccessBody('never-delivered');
        MockFlakyService.ScriptStatus(500);
        ResponseBody := 'stale value from a previous call';

        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 2, MockFlakyService, ResponseBody);

        Assert.AreEqual('', ResponseBody,
            'Expected ResponseBody to end up empty when every attempt failed (it was preset to a stale value)');
        Assert.AreEqual(2, MockFlakyService.GetRequestCount(),
            'Expected exactly two requests through the handler when MaxAttempts is 2 and the service keeps answering 500');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure BackoffScheduleDoublesFrom100Milliseconds()
    var
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        RetryNumber: Integer;
    begin
        // [SCENARIO] BackoffDelayMs returns 100 * 2^(RetryNumber - 1) milliseconds
        Assert.AreEqual(100, ResilientHttpClient.BackoffDelayMs(1),
            'Expected the wait before retry number 1 to be 100 milliseconds');
        Assert.AreEqual(200, ResilientHttpClient.BackoffDelayMs(2),
            'Expected the wait before retry number 2 to double to 200 milliseconds');
        Assert.AreEqual(400, ResilientHttpClient.BackoffDelayMs(3),
            'Expected the wait before retry number 3 to double again to 400 milliseconds');

        RetryNumber := Any.IntegerInRange(4, 8);
        Assert.AreEqual(DoublingScheduleValue(RetryNumber), ResilientHttpClient.BackoffDelayMs(RetryNumber),
            StrSubstNo('Expected the wait before retry number %1 to keep doubling from 100 milliseconds', RetryNumber));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecordsTheBackoffScheduledForEachRetry()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] Two retries put 100 + 200 = 300 ms on the tally
        MockFlakyService.SetSuccessBody('slow-but-steady');
        MockFlakyService.ScriptStatus(429);
        MockFlakyService.ScriptStatus(500);
        MockFlakyService.ScriptStatus(200);

        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 5, MockFlakyService, ResponseBody);

        Assert.AreEqual(3, MockFlakyService.GetRequestCount(),
            'Expected exactly three requests through the handler for the script 429, 500, 200');
        Assert.AreEqual(300, ResilientHttpClient.GetTotalBackoffMs(),
            'Expected the backoff tally for two retries to be 100 ms + 200 ms = 300 ms');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecordsZeroBackoffWhenTheFirstAttemptSucceeds()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] No retry means an empty tally
        MockFlakyService.SetSuccessBody('first-try-body');
        MockFlakyService.ScriptStatus(200);

        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 5, MockFlakyService, ResponseBody);

        Assert.AreEqual(0, ResilientHttpClient.GetTotalBackoffMs(),
            'Expected a backoff tally of 0 when the first attempt already succeeded');
        Assert.AreEqual(1, MockFlakyService.GetRequestCount(),
            'Expected exactly one request through the handler when the first attempt already succeeded');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RecordsTheFullScheduleWhenTheAttemptBudgetIsSpent()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        MaxAttempts: Integer;
        TransientStatus: Integer;
        ExpectedTotalMs: Integer;
        RetryNo: Integer;
        ResponseBody: Text;
    begin
        // [SCENARIO] MaxAttempts requests mean MaxAttempts - 1 retries on the tally — no delay after the final attempt
        MaxAttempts := Any.IntegerInRange(2, 5);
        TransientStatus := Any.IntegerInRange(500, 599);
        MockFlakyService.SetSuccessBody('never-delivered');
        MockFlakyService.ScriptStatus(TransientStatus);
        for RetryNo := 1 to MaxAttempts - 1 do
            ExpectedTotalMs += DoublingScheduleValue(RetryNo);

        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', MaxAttempts, MockFlakyService, ResponseBody);

        Assert.AreEqual(MaxAttempts, MockFlakyService.GetRequestCount(),
            StrSubstNo('Expected exactly MaxAttempts (%1) requests through the handler against a service that always answers %2 — every status in 500-599 is transient', MaxAttempts, TransientStatus));
        Assert.AreEqual(ExpectedTotalMs, ResilientHttpClient.GetTotalBackoffMs(),
            StrSubstNo('Expected the backoff tally for %1 attempts to cover retries 1 through %2 of the doubling schedule and nothing more', MaxAttempts, MaxAttempts - 1));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure StartsTheBackoffTallyAfreshOnEveryCall()
    var
        MockFlakyService: Codeunit "Mock Flaky Service";
        ResilientHttpClient: Codeunit "Resilient Http Client";
        Assert: Codeunit Assert;
        ResponseBody: Text;
    begin
        // [SCENARIO] A second call on the same instance reports its own tally, not a running total
        MockFlakyService.SetSuccessBody('warm-up-body');
        MockFlakyService.ScriptStatus(429);
        MockFlakyService.ScriptStatus(200);
        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 3, MockFlakyService, ResponseBody);
        MockFlakyService.ScriptStatus(200);

        ResilientHttpClient.GetWithRetry('https://api.example.com/v1/orders', 3, MockFlakyService, ResponseBody);

        Assert.AreEqual(0, ResilientHttpClient.GetTotalBackoffMs(),
            'Expected the second call, which never retried, to report a backoff tally of 0 — not the 100 ms left over from the first call');
        Assert.AreEqual(3, MockFlakyService.GetRequestCount(),
            'Expected three requests through the handler in total: two for the first call (429 then 200) and one for the second (200)');
    end;

    local procedure DoublingScheduleValue(RetryNumber: Integer): Integer
    var
        DelayMs: Integer;
        i: Integer;
    begin
        DelayMs := 100;
        for i := 2 to RetryNumber do
            DelayMs *= 2;
        exit(DelayMs);
    end;
}
