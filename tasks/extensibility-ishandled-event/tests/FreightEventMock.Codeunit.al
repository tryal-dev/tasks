codeunit 50901 "Freight Event Mock"
{
    EventSubscriberInstance = Manual;

    var
        CannedFreight: Decimal;
        MarkHandled: Boolean;

    procedure ArrangeOverride(NewFreight: Decimal)
    begin
        CannedFreight := NewFreight;
        MarkHandled := true;
    end;

    procedure ArrangeWriteWithoutHandling(NewFreight: Decimal)
    begin
        CannedFreight := NewFreight;
        MarkHandled := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Freight Charge Calculator", 'OnBeforeCalculateFreight', '', false, false)]
    local procedure HandleOnBeforeCalculateFreight(Amount: Decimal; var Freight: Decimal; var IsHandled: Boolean)
    begin
        Freight := CannedFreight;
        if MarkHandled then
            IsHandled := true;
    end;
}
