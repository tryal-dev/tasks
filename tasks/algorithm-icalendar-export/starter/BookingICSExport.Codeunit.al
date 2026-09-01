codeunit 50101 "Booking ICS Export"
{
    procedure Export(StampDate: Date; StampTime: Time): Text
    begin
        // TODO: serialize every Booking record into an RFC 5545 VCALENDAR feed:
        // CRLF line endings, 75-octet line folding, TEXT escaping, zero-padded
        // UTC date-times, stable UIDs, events in "No." order.
        exit('');
    end;
}
