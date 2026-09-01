codeunit 50100 "Parcel Tracking Client"
{
    procedure RegisterPrivacyNotice(PrivacyNoticeId: Code[50]; IntegrationName: Text[250]; PrivacyLink: Text[2048]): Boolean
    begin
        // TODO: register the integration's privacy notice under PrivacyNoticeId,
        // and report whether this call is the one that created it.
    end;

    procedure TrackParcel(PrivacyNoticeId: Code[50]; TrackingNo: Text; HttpClientHandler: Interface "Http Client Handler"; var ResponseBody: Text): Boolean
    begin
        // TODO: decide from the notice's current approval state whether this
        // call may reach the tracking service at all, then send it.
    end;
}
