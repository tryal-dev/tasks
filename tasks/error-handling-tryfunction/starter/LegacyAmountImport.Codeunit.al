codeunit 50101 "Legacy Amount Import"
{
    procedure ParseAmount(AmountText: Text): Decimal
    begin
        // TODO: return the decimal value of a valid amount text;
        // raise the error described in the task statement for an invalid one.
    end;

    procedure TryParseAmount(AmountText: Text; var Amount: Decimal; var FailureReason: Text): Boolean
    begin
        // TODO: never raise — catch the conversion failure and report its
        // error text through FailureReason instead.
    end;

    procedure ImportLine(EntryCode: Code[20]; AmountText: Text): Boolean
    begin
        // TODO: insert a "Legacy Amount Entry" only when AmountText is valid;
        // a failed line must leave no row behind.
    end;
}
