codeunit 50100 "Campaign Call List"
{
    procedure BuildCallList(var Customer: Record Customer; CampaignCity: Text; VipCreditLimit: Decimal)
    begin
        // TODO: these two filters combine with AND — the list ends up with
        // customers matching BOTH rules, but the campaign needs either/or.
        Customer.SetRange(City, CampaignCity);
        Customer.SetFilter("Credit Limit (LCY)", '>=%1', VipCreditLimit);
    end;
}
