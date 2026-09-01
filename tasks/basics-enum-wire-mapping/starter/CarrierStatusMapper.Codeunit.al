codeunit 50101 "Carrier Status Mapper"
{
    procedure FromWire(WireCode: Integer): Enum "Carrier Status"
    begin
        // TODO: this hardcoded list is the bug — a value added later by an
        // enumextension never reaches it. Replace it with run-time discovery.
        case WireCode of
            10:
                exit("Carrier Status"::Registered);
            20:
                exit("Carrier Status"::"In Transit");
            30:
                exit("Carrier Status"::Delivered);
            else
                exit("Carrier Status"::Unknown);
        end;
    end;

    procedure FromWireStrict(WireCode: Integer): Enum "Carrier Status"
    begin
        // TODO: like FromWire, but an unrecognized code must raise an error
        // with a message that contains the code.
        exit("Carrier Status"::Unknown);
    end;

    procedure ToWire(Status: Enum "Carrier Status"): Integer
    begin
        // TODO: return the wire code of the given value.
        exit(0);
    end;

    procedure ToWireName(Status: Enum "Carrier Status"): Text
    begin
        // TODO: return the declared name of the given value — not the caption.
        exit('');
    end;
}
