codeunit 50901 "Return Reason Policy Listener"
{
    // "Write no policy logic of your own" is only checkable by watching the base
    // application run its own validation: hand-written location/cost assignments
    // reproduce the field values but never fire this event for the reason-code field.
    EventSubscriberInstance = Manual;

    var
        ReasonCodeValidationCount: Integer;

    procedure ReasonCodeValidations(): Integer
    begin
        exit(ReasonCodeValidationCount);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnAfterValidateReturnReasonCode', '', false, false)]
    local procedure OnAfterValidateReturnReasonCode(var SalesLine: Record "Sales Line"; CallingFieldNo: Integer)
    begin
        if CallingFieldNo = SalesLine.FieldNo("Return Reason Code") then
            ReasonCodeValidationCount += 1;
    end;
}
