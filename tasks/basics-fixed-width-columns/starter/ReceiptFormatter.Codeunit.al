codeunit 50100 "Receipt Formatter"
{
    procedure ReceiptLine(Description: Text; Amount: Decimal): Text
    begin
        // TODO: 20 columns of description, then 12 columns of amount - 32 characters, always.
        exit(Description + ' ' + Format(Amount));
    end;

    procedure DocumentNo(Prefix: Code[10]; Seq: Integer): Code[20]
    begin
        // TODO: PadStr appends its filler - sequence 42 comes out as 42000, not 00042.
        exit(Prefix + '-' + PadStr(Format(Seq), 5, '0'));
    end;
}
