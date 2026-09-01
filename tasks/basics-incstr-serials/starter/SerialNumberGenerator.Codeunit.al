codeunit 50100 "Serial Number Generator"
{
    procedure NextSerials(LastSerial: Text; Qty: Integer): List of [Text]
    begin
        // TODO: return Qty serials, the first one step after LastSerial and each further one a step after the previous.
    end;

    procedure Advance(Serial: Text; By: Integer): Text
    begin
        // TODO: move the number closest to the end of Serial forward by By; a serial without digits must raise the statement's error.
    end;
}
