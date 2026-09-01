codeunit 50100 "Resilient Http Client"
{
    procedure GetWithRetry(Url: Text; MaxAttempts: Integer; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
    begin
        // TODO: send GET requests to Url through HttpClientHandler,
        // retrying transient statuses per the task's rules.
    end;

    procedure BackoffDelayMs(RetryNumber: Integer): Integer
    begin
        // TODO: return the wait in milliseconds before retry number RetryNumber.
    end;

    procedure GetTotalBackoffMs(): Integer
    begin
        // TODO: return the backoff tally of the most recent GetWithRetry call.
    end;
}
