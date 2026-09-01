codeunit 50100 "Order Text Builder"
{
    procedure ConfirmationText(OrderNo: Code[20]; CustomerName: Text; LineCount: Integer): Text
    begin
        // TODO: move the sentence into Label variables (singular and plural) and fill them with StrSubstNo.
        exit('Dear ' + CustomerName + ', your order ' + OrderNo + ' with ' + Format(LineCount) + ' lines is confirmed.');
    end;

    procedure SlipColumn(ItemNo: Code[20]; Description: Text): Text
    begin
        // TODO: fixed-width columns through the # placeholder family.
        exit(ItemNo + ' ' + Description);
    end;
}
