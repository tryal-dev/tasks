codeunit 50100 "Variant Formatter"
{
    procedure FormatValue(Value: Variant): Text
    begin
        // TODO: probe the Variant for each supported type and return the payload
        // as '<type name>: <payload>' in the canonical shapes from the statement;
        // raise the contract error for anything unsupported.
    end;

    procedure TryFormatValue(Value: Variant; var FormattedValue: Text): Boolean
    begin
        // TODO: same conversions, but report failure through the return value and
        // an emptied FormattedValue instead of raising an error.
    end;
}
